# frozen_string_literal: true

require "chunky_png"
require "tempfile"
require_relative "bitmap_font"

class MarineRenderer
  WIDTH  = 64
  HEIGHT = 32

  COLOR_BG       = ChunkyPNG::Color.rgb(0, 0, 0)
  COLOR_WIND     = ChunkyPNG::Color.rgb(0, 204, 255)   # cyan
  COLOR_SWELL    = ChunkyPNG::Color.rgb(0, 204, 68)    # green
  COLOR_WAVE     = ChunkyPNG::Color.rgb(0, 119, 255)   # blue
  COLOR_LABEL    = ChunkyPNG::Color.rgb(130, 130, 130)  # grey
  COLOR_ICON     = ChunkyPNG::Color.rgb(255, 170, 0)   # amber

  # Compass arrows 5x5 — pointing in the direction wind/swell comes FROM
  # We provide 8 cardinal directions, pick nearest
  ARROWS = {
    "N"  => [[0,0,1,0,0],[0,1,1,1,0],[1,0,1,0,1],[0,0,1,0,0],[0,0,1,0,0]],
    "NE" => [[0,1,1,1,0],[0,0,1,1,0],[0,1,0,1,0],[1,1,0,0,0],[1,0,0,0,0]],
    "E"  => [[0,0,1,0,0],[0,1,0,0,0],[1,1,1,1,1],[0,1,0,0,0],[0,0,1,0,0]],
    "SE" => [[1,0,0,0,0],[1,1,0,0,0],[0,1,0,1,0],[0,0,1,1,0],[0,1,1,1,0]],
    "S"  => [[0,0,1,0,0],[0,0,1,0,0],[1,0,1,0,1],[0,1,1,1,0],[0,0,1,0,0]],
    "SW" => [[0,0,0,0,1],[0,0,0,1,1],[0,1,0,1,0],[0,1,1,0,0],[0,1,1,1,0]],
    "W"  => [[0,0,1,0,0],[0,0,0,1,0],[1,1,1,1,1],[0,0,0,1,0],[0,0,1,0,0]],
    "NW" => [[0,1,1,1,0],[0,1,1,0,0],[0,1,0,1,0],[0,0,0,1,1],[0,0,0,0,1]],
  }.freeze

  # Wave icon 5x5
  WAVE_ICON = [
    [0,0,0,0,0],
    [0,1,0,1,0],
    [1,0,1,0,1],
    [0,0,0,0,0],
    [0,0,0,0,0],
  ].freeze

  # Wind icon 5x5 (three horizontal lines with taper)
  WIND_ICON = [
    [1,1,1,1,1],
    [0,0,0,0,0],
    [0,1,1,1,0],
    [0,0,0,0,0],
    [1,1,1,0,0],
  ].freeze

  def initialize(marine:, wind:)
    @marine = marine
    @wind = wind
  end

  def to_webp
    image = render_image

    png_file = Tempfile.new(["marine", ".png"])
    webp_file = Tempfile.new(["marine", ".webp"])
    begin
      image.save(png_file.path)
      system("convert", png_file.path, "-define", "webp:lossless=true", webp_file.path,
             exception: true)
      File.binread(webp_file.path)
    ensure
      png_file.close!
      webp_file.close!
    end
  end

  private

  def render_image
    image = ChunkyPNG::Image.new(WIDTH, HEIGHT, COLOR_BG)

    draw_wind(image)
    draw_swell(image)
    draw_sea_state(image)

    image
  end

  # Row 0: wind icon + speed + direction arrow + gust
  def draw_wind(image)
    draw_icon(image, 0, 0, WIND_ICON, COLOR_ICON)

    speed = (@wind[:speed_kn] || 0).round
    cursor = BitmapFont.draw_text(image, 7, 0, "#{speed}KN", COLOR_WIND)

    draw_direction_arrow(image, cursor + 1, 0, @wind[:direction], COLOR_WIND)

    gusts = @wind[:gusts_kn]
    if gusts
      BitmapFont.draw_text(image, cursor + 8, 0, "G#{gusts.round}", COLOR_WIND)
    end
  end

  # Row 11: wave icon + swell height + period + direction arrow
  def draw_swell(image)
    draw_icon(image, 0, 11, WAVE_ICON, COLOR_ICON)

    height_text = format("%.1fM", @marine[:swell_height] || 0)
    cursor = BitmapFont.draw_text(image, 7, 11, height_text, COLOR_SWELL)

    period_text = "#{(@marine[:swell_period] || 0).round}S"
    cursor = BitmapFont.draw_text(image, cursor + 2, 11, period_text, COLOR_SWELL)

    draw_direction_arrow(image, cursor + 2, 11, @marine[:swell_direction], COLOR_SWELL)
  end

  # Row 22: sea state (combined wave height + period)
  def draw_sea_state(image)
    height = @marine[:wave_height] || 0
    state = sea_state_description(height)

    BitmapFont.draw_text(image, 1, 22, "SEA", COLOR_LABEL)

    height_text = format("%.1fM", height)
    cursor = BitmapFont.draw_text(image, 17, 22, height_text, COLOR_WAVE)

    BitmapFont.draw_text(image, cursor + 2, 22, state, COLOR_WAVE)
  end

  def draw_icon(image, x, y, icon, color)
    icon.each_with_index do |row, ry|
      row.each_with_index do |pixel, rx|
        if pixel == 1
          px = x + rx
          py = y + ry
          image[px, py] = color if px >= 0 && px < WIDTH && py >= 0 && py < HEIGHT
        end
      end
    end
  end

  def draw_direction_arrow(image, x, y, degrees, color)
    return unless degrees
    cardinal = degrees_to_cardinal(degrees)
    arrow = ARROWS[cardinal]
    draw_icon(image, x, y, arrow, color) if arrow
  end

  def degrees_to_cardinal(deg)
    directions = %w[N NE E SE S SW W NW]
    index = ((deg + 22.5) % 360 / 45).floor
    directions[index]
  end

  def sea_state_description(wave_height)
    case wave_height
    when 0...0.1    then "CALM"
    when 0.1...0.5  then "SMOOTH"
    when 0.5...1.25 then "SLIGHT"
    when 1.25...2.5 then "MOD"
    when 2.5...4.0  then "ROUGH"
    when 4.0...6.0  then "VROUGH"
    when 6.0...9.0  then "HIGH"
    when 9.0...14.0 then "VHIGH"
    else                 "PHENML"
    end
  end
end
