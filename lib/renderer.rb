# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/time/zones"
require_relative "pixel_canvas"
require_relative "bitmap_font"

# Renders the tide chart screen for Tidbyt (64×32).
#
# Layout:
#   Row 0:  ▲ HH:MM X.Xm  (next high, cyan)
#   Row 6:  ▼ HH:MM X.Xm  (next low, green)
#   Rows 12–31: tide curve graph with red "now" line at x=32
class Renderer
  GRAPH_TOP    = 12
  GRAPH_BOTTOM = 31
  GRAPH_HEIGHT = GRAPH_BOTTOM - GRAPH_TOP + 1
  NOW_X        = 32

  COLOR_HIGH  = ChunkyPNG::Color.rgb(0, 204, 255)
  COLOR_LOW   = ChunkyPNG::Color.rgb(0, 204, 68)
  COLOR_CURVE = ChunkyPNG::Color.rgb(0, 119, 255)
  COLOR_FILL  = ChunkyPNG::Color.rgb(0, 34, 68)
  COLOR_NOW   = ChunkyPNG::Color.rgb(255, 0, 0)

  HEX_HIGH = "#00ccff"
  HEX_LOW  = "#00cc44"

  UP_ARROW = [
    [0, 0, 1, 0, 0],
    [0, 1, 1, 1, 0],
    [1, 1, 1, 1, 1],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
  ].freeze

  DOWN_ARROW = [
    [1, 1, 1, 1, 1],
    [0, 1, 1, 1, 0],
    [0, 0, 1, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
  ].freeze

  def initialize(station_name, calculator, now: Time.now.utc)
    @station_name = station_name.upcase
    @calculator   = calculator
    @now          = now
  end

  def to_webp
    canvas = PixelCanvas.new
    draw_arrows(canvas)
    draw_graph(canvas)
    draw_now_line(canvas)

    canvas.to_webp { |png_path| draw_text(png_path) }
  end

  private

  def draw_arrows(canvas)
    canvas.draw_bitmap(x: 1, y: 0, bitmap: UP_ARROW, color: COLOR_HIGH) if next_high
    canvas.draw_bitmap(x: 1, y: 6, bitmap: DOWN_ARROW, color: COLOR_LOW) if next_low
  end

  def draw_text(png_path)
    if next_high
      BitmapFont.draw_text(png_path, x: 7, y: 5,
        text: "#{format_time(next_high[:time])} #{format_height(next_high[:height])}",
        color: HEX_HIGH)
    end

    if next_low
      BitmapFont.draw_text(png_path, x: 7, y: 11,
        text: "#{format_time(next_low[:time])} #{format_height(next_low[:height])}",
        color: HEX_LOW)
    end
  end

  def draw_graph(canvas)
    points  = @calculator.curve_points(@now)
    y_min, y_max = @calculator.y_limits
    y_range = y_max - y_min

    points.each do |x, height|
      curve_y = GRAPH_BOTTOM - ((height - y_min) / y_range * (GRAPH_HEIGHT - 1)).round

      canvas.draw_pixel(x, curve_y, COLOR_CURVE)

      if x <= NOW_X
        ((curve_y + 1)..GRAPH_BOTTOM).each { |y| canvas.draw_pixel(x, y, COLOR_FILL) }
      end
    end
  end

  def draw_now_line(canvas)
    (GRAPH_TOP..GRAPH_BOTTOM).each { |y| canvas.draw_pixel(NOW_X, y, COLOR_NOW) }
  end

  def next_high  = @next_high  ||= @calculator.next_high(@now)
  def next_low   = @next_low   ||= @calculator.next_low(@now)

  def format_time(time)   = time.in_time_zone("London").strftime("%H:%M")
  def format_height(h)    = format("%.1fm", h)
end
