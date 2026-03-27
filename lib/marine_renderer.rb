# frozen_string_literal: true

require "chunky_png"
require "tempfile"
require_relative "bitmap_font"

class MarineRenderer
  WIDTH  = 64
  HEIGHT = 32

  COLOR_BG   = ChunkyPNG::Color.rgb(0, 0, 0)
  COLOR_ICON = ChunkyPNG::Color.rgb(255, 170, 0)   # amber

  HEX_WIND  = "#00ccff"   # cyan
  HEX_SWELL = "#00cc44"   # green
  HEX_WAVE  = "#0077ff"   # blue
  HEX_LABEL = "#828282"   # grey

  # Primary text: 6×13 bitmap font (wind + swell rows)
  FONT_PATH = BitmapFont::LARGE_FONT_PATH
  FONT_SIZE = BitmapFont::LARGE_FONT_SIZE
  FONT_CHAR_WIDTH = 6

  # Sea state row: Tom Thumb (fits in the remaining 4px at bottom)
  SMALL_FONT_PATH = BitmapFont::FONT_PATH
  SMALL_FONT_SIZE = BitmapFont::FONT_SIZE

  # Compass arrows 5x5 — 8 cardinal directions
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

  # Wind icon 5x5
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
    png_file = Tempfile.new(["marine", ".png"])
    webp_file = Tempfile.new(["marine", ".webp"])
    begin
      # Step 1: ChunkyPNG draws icons + direction arrows
      image = ChunkyPNG::Image.new(WIDTH, HEIGHT, COLOR_BG)
      draw_icons(image)
      image.save(png_file.path)

      # Step 2: ImageMagick adds text
      draw_text(png_file.path)

      # Step 3: Convert to WebP
      BitmapFont.convert_to_webp(png_file.path, webp_file.path)

      File.binread(webp_file.path)
    ensure
      png_file.close!
      webp_file.close!
    end
  end

  private

  def draw_icons(image)
    # Row 1 (y=0..13): wind icon centered at y=4
    draw_icon(image, 0, 4, WIND_ICON, COLOR_ICON)
    wind_text_width = wind_text.length * FONT_CHAR_WIDTH + 7
    draw_direction_arrow(image, wind_text_width + 1, 4, @wind[:direction], COLOR_ICON)

    # Row 2 (y=14..27): swell icon centered at y=18
    draw_icon(image, 0, 18, WAVE_ICON, COLOR_ICON)
    swell_text_width = swell_text.length * FONT_CHAR_WIDTH + 7
    draw_direction_arrow(image, swell_text_width + 1, 18, @marine[:swell_direction], COLOR_ICON)
  end

  def draw_text(png_path)
    big = { font_path: FONT_PATH, font_size: FONT_SIZE }

    # Row 1: wind (6×13, baseline at y=12)
    BitmapFont.draw_text_on_file(png_path, 7, 12, wind_text, HEX_WIND, **big)

    # Row 2: swell (6×13, baseline at y=26)
    BitmapFont.draw_text_on_file(png_path, 7, 26, swell_text, HEX_SWELL, **big)

    # Row 3: sea state word (Tom Thumb, baseline at y=31)
    BitmapFont.draw_text_on_file(png_path, 1, 31, sea_state_text, HEX_WAVE,
      font_path: SMALL_FONT_PATH, font_size: SMALL_FONT_SIZE)
  end

  def wind_text
    speed = (@wind[:speed_kn] || 0).round
    gusts = @wind[:gusts_kn]&.round

    if gusts && gusts > speed
      "#{speed}-#{gusts}kn"
    else
      "#{speed}kn"
    end
  end

  def swell_text
    height = format("%.1fm", @marine[:swell_height] || 0)
    period = "#{(@marine[:swell_period] || 0).round}s"
    "#{height} #{period}"
  end

  def sea_state_text
    sea_state_description(@marine[:wave_height] || 0)
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
    when 0...0.1    then "Calm"
    when 0.1...0.5  then "Smooth"
    when 0.5...1.25 then "Slight"
    when 1.25...2.5 then "Mod"
    when 2.5...4.0  then "Rough"
    when 4.0...6.0  then "V.Rough"
    when 6.0...9.0  then "High"
    when 9.0...14.0 then "V.High"
    else                 "Phenomenal"
    end
  end
end
