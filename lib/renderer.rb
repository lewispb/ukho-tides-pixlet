# frozen_string_literal: true

require "chunky_png"
require "tempfile"
require "active_support"
require "active_support/core_ext/time/zones"
require_relative "bitmap_font"

class Renderer
  WIDTH  = 64
  HEIGHT = 32

  # Graph area
  GRAPH_TOP    = 12
  GRAPH_BOTTOM = 31
  GRAPH_HEIGHT = GRAPH_BOTTOM - GRAPH_TOP + 1

  # Colors (ChunkyPNG RGBA)
  COLOR_BG     = ChunkyPNG::Color.rgb(0, 0, 0)
  COLOR_HIGH   = ChunkyPNG::Color.rgb(0, 204, 255)    # cyan
  COLOR_LOW    = ChunkyPNG::Color.rgb(0, 204, 68)     # green
  COLOR_CURVE  = ChunkyPNG::Color.rgb(0, 119, 255)    # blue
  COLOR_FILL   = ChunkyPNG::Color.rgb(0, 34, 68)      # dark navy
  COLOR_NOW    = ChunkyPNG::Color.rgb(255, 0, 0)      # red

  # Colors (hex for ImageMagick text)
  HEX_HIGH = "#00ccff"
  HEX_LOW  = "#00cc44"

  def initialize(station_name, calculator, now: Time.now.utc)
    @station_name = station_name.upcase
    @calculator   = calculator
    @now          = now
  end

  def to_webp
    png_file = Tempfile.new(["tide", ".png"])
    webp_file = Tempfile.new(["tide", ".webp"])
    begin
      # Step 1: ChunkyPNG draws graph + arrows
      image = ChunkyPNG::Image.new(WIDTH, HEIGHT, COLOR_BG)
      draw_arrows(image)
      draw_graph(image)
      draw_now_line(image)
      image.save(png_file.path)

      # Step 2: ImageMagick adds text with BDF font
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

  def draw_arrows(image)
    next_high = @calculator.next_high(@now)
    next_low = @calculator.next_low(@now)

    BitmapFont.draw_arrow(image, 1, 0, BitmapFont::UP_ARROW, COLOR_HIGH) if next_high
    BitmapFont.draw_arrow(image, 1, 6, BitmapFont::DOWN_ARROW, COLOR_LOW) if next_low
  end

  def draw_text(png_path)
    next_high = @calculator.next_high(@now)
    next_low = @calculator.next_low(@now)

    if next_high
      ht = format_local_time(next_high[:time])
      BitmapFont.draw_text_on_file(png_path, 7, 5, "#{ht} #{format_height(next_high[:height])}", HEX_HIGH)
    end

    if next_low
      lt = format_local_time(next_low[:time])
      BitmapFont.draw_text_on_file(png_path, 7, 11, "#{lt} #{format_height(next_low[:height])}", HEX_LOW)
    end
  end

  def draw_graph(image)
    points = @calculator.curve_points(@now)
    y_min, y_max = @calculator.y_limits
    y_range = y_max - y_min

    now_x = 32

    points.each do |x, height|
      normalized = (height - y_min) / y_range
      curve_y = GRAPH_BOTTOM - (normalized * (GRAPH_HEIGHT - 1)).round

      image[x, curve_y] = COLOR_CURVE if in_bounds?(x, curve_y)

      if x <= now_x
        ((curve_y + 1)..GRAPH_BOTTOM).each do |fill_y|
          image[x, fill_y] = COLOR_FILL if in_bounds?(x, fill_y)
        end
      end
    end
  end

  def draw_now_line(image)
    (GRAPH_TOP..GRAPH_BOTTOM).each do |y|
      image[32, y] = COLOR_NOW
    end
  end

  def in_bounds?(x, y)
    x >= 0 && x < WIDTH && y >= 0 && y < HEIGHT
  end

  def format_local_time(time)
    time.in_time_zone("London").strftime("%H:%M")
  end

  def format_height(h)
    format("%.1fm", h)
  end
end
