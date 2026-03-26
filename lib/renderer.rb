# frozen_string_literal: true

require "chunky_png"
require "tempfile"
require_relative "bitmap_font"

class Renderer
  WIDTH  = 64
  HEIGHT = 32

  # Graph area
  GRAPH_TOP    = 11
  GRAPH_BOTTOM = 31
  GRAPH_HEIGHT = GRAPH_BOTTOM - GRAPH_TOP + 1

  # Colors (ChunkyPNG RGBA)
  COLOR_BG         = ChunkyPNG::Color.rgb(0, 0, 0)
  COLOR_STATION    = ChunkyPNG::Color.rgb(255, 170, 0)    # amber
  COLOR_HIGH       = ChunkyPNG::Color.rgb(0, 204, 255)    # cyan
  COLOR_LOW        = ChunkyPNG::Color.rgb(0, 204, 68)     # green
  COLOR_CURVE      = ChunkyPNG::Color.rgb(0, 119, 255)    # blue
  COLOR_FILL       = ChunkyPNG::Color.rgb(0, 34, 68)      # dark navy
  COLOR_NOW        = ChunkyPNG::Color.rgb(255, 0, 0)      # red

  def initialize(station_name, calculator, now: Time.now.utc)
    @station_name = station_name.upcase
    @calculator   = calculator
    @now          = now
    @local_now    = @now.getlocal(uk_offset)
  end

  def to_png
    image = ChunkyPNG::Image.new(WIDTH, HEIGHT, COLOR_BG)

    draw_header(image)
    draw_graph(image)
    draw_now_line(image)

    image.to_blob(:fast_rgb)
  end

  def to_webp
    png_data = to_png

    png_file = Tempfile.new(["tide", ".png"])
    webp_file = Tempfile.new(["tide", ".webp"])
    begin
      # Write PNG via ChunkyPNG (need to re-create from raw to get valid PNG)
      image = render_image
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
    draw_header(image)
    draw_graph(image)
    draw_now_line(image)
    image
  end

  def draw_header(image)
    # Row 0: station name
    BitmapFont.draw_text(image, 1, 0, @station_name, COLOR_STATION)

    # Row 6: next high tide
    next_high = @calculator.next_high(@now)
    if next_high
      ht = format_local_time(next_high[:time])
      BitmapFont.draw_arrow(image, 1, 6, BitmapFont::UP_ARROW, COLOR_HIGH)
      BitmapFont.draw_text(image, 7, 6, "#{ht} #{format_height(next_high[:height])}", COLOR_HIGH)
    end

    # Would overlap on 32px height, so skip low tide text row if no room
    # Actually we have room: row 0-4 station, row 6-10 high, graph starts at 11
    # There isn't room for a third text row before the graph, so we show high/low
    # on the same row, split left/right
    next_low = @calculator.next_low(@now)
    if next_low && next_high
      # Show low tide on right side of same row or on the station name row's right side
      lt = format_local_time(next_low[:time])
      low_text = "#{lt} #{format_height(next_low[:height])}"
      low_width = BitmapFont.text_width(low_text) + 6 # 5 for arrow + 1 spacing
      low_x = WIDTH - low_width
      BitmapFont.draw_arrow(image, low_x, 6, BitmapFont::DOWN_ARROW, COLOR_LOW)
      BitmapFont.draw_text(image, low_x + 6, 6, low_text, COLOR_LOW)
    elsif next_low
      lt = format_local_time(next_low[:time])
      BitmapFont.draw_arrow(image, 1, 6, BitmapFont::DOWN_ARROW, COLOR_LOW)
      BitmapFont.draw_text(image, 7, 6, "#{lt} #{format_height(next_low[:height])}", COLOR_LOW)
    end
  end

  def draw_graph(image)
    points = @calculator.curve_points(@now)
    y_min, y_max = @calculator.y_limits
    y_range = y_max - y_min

    # Current time is at pixel 32 (center of 64px)
    now_x = 32

    points.each do |x, height|
      # Map height to pixel row (inverted: high values = low row numbers)
      normalized = (height - y_min) / y_range
      curve_y = GRAPH_BOTTOM - (normalized * (GRAPH_HEIGHT - 1)).round

      # Draw the curve pixel
      image[x, curve_y] = COLOR_CURVE if in_bounds?(x, curve_y)

      # Fill below curve with navy, but only up to current time (x <= now_x)
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
    time.getlocal(uk_offset).strftime("%H:%M")
  end

  def format_height(h)
    format("%.1fM", h)
  end

  # Determine current UK offset (GMT or BST).
  # BST: last Sunday of March 01:00 UTC to last Sunday of October 01:00 UTC.
  def uk_offset
    @uk_offset ||= begin
      year = @now.year

      # Last Sunday of March
      bst_start = last_sunday_of(year, 3) + 3600 # 01:00 UTC
      # Last Sunday of October
      bst_end = last_sunday_of(year, 10) + 3600 # 01:00 UTC

      if @now.to_i >= bst_start.to_i && @now.to_i < bst_end.to_i
        "+01:00"
      else
        "+00:00"
      end
    end
  end

  def last_sunday_of(year, month)
    # Find the last day of the month, walk back to Sunday
    last_day = Time.utc(year, month + (month == 12 ? -11 : 1), 1) - 86400
    last_day -= 86400 until last_day.sunday?
    last_day
  end
end
