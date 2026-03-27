# frozen_string_literal: true

require_relative "pixel_canvas"
require_relative "bitmap_font"
require_relative "compass"
require_relative "sea_state"

# Renders the marine weather screen for Tidbyt (64×32).
#
# Layout:
#   Row 1 (6×13): [wind icon] 11-20kn [arrow]
#   Row 2 (6×13): [wave icon] 0.5m 5s [arrow]
#   Row 3 (Tom Thumb): Slight
class MarineRenderer
  COLOR_ICON = ChunkyPNG::Color.rgb(255, 170, 0)

  HEX_WIND  = "#00ccff"
  HEX_SWELL = "#00cc44"
  HEX_WAVE  = "#0077ff"

  FONT_PATH      = BitmapFont::LARGE_FONT_PATH
  FONT_SIZE      = BitmapFont::LARGE_FONT_SIZE
  FONT_CHAR_WIDTH = 6

  WIND_ICON = [
    [1,1,1,1,1],
    [0,0,0,0,0],
    [0,1,1,1,0],
    [0,0,0,0,0],
    [1,1,1,0,0],
  ].freeze

  WAVE_ICON = [
    [0,0,0,0,0],
    [0,1,0,1,0],
    [1,0,1,0,1],
    [0,0,0,0,0],
    [0,0,0,0,0],
  ].freeze

  TEXT_X = 7   # left edge of text (after 5px icon + 2px gap)

  def initialize(marine:, wind:)
    @marine = marine
    @wind   = wind
  end

  def to_webp
    canvas = PixelCanvas.new
    draw_icons(canvas)

    canvas.to_webp { |png_path| draw_text(png_path) }
  end

  private

  # --- Icons and arrows (ChunkyPNG) ---

  def draw_icons(canvas)
    draw_row_icons(canvas, y: 2,  icon: WIND_ICON, text: wind_text, direction: @wind[:direction])
    draw_row_icons(canvas, y: 15, icon: WAVE_ICON, text: swell_text, direction: @marine[:swell_direction])
  end

  def draw_row_icons(canvas, y:, icon:, text:, direction:)
    canvas.draw_bitmap(x: 0, y: y, bitmap: icon, color: COLOR_ICON)

    if direction
      arrow_x = text.length * FONT_CHAR_WIDTH + TEXT_X + 1
      arrow = Compass.arrow_for(direction)
      canvas.draw_bitmap(x: arrow_x, y: y, bitmap: arrow, color: COLOR_ICON) if arrow
    end
  end

  # --- Text (ImageMagick) ---

  def draw_text(png_path)
    big   = { font_path: FONT_PATH, font_size: FONT_SIZE }
    small = { font_path: BitmapFont::FONT_PATH, font_size: BitmapFont::FONT_SIZE }

    BitmapFont.draw_text(png_path, x: TEXT_X, y: 10, text: wind_text,      color: HEX_WIND,  **big)
    BitmapFont.draw_text(png_path, x: TEXT_X, y: 23, text: swell_text,     color: HEX_SWELL, **big)
    BitmapFont.draw_text(png_path, x: TEXT_X, y: 31, text: sea_state_text, color: HEX_WAVE,  **small)
  end

  # --- Formatted text ---

  def wind_text
    @wind_text ||= begin
      speed = (@wind[:speed_kn] || 0).round
      gusts = @wind[:gusts_kn]&.round

      gusts && gusts > speed ? "#{speed}-#{gusts}kn" : "#{speed}kn"
    end
  end

  def swell_text
    @swell_text ||= begin
      height = format("%.1fm", @marine[:swell_height] || 0)
      period = "#{(@marine[:swell_period] || 0).round}s"
      "#{height} #{period}"
    end
  end

  def sea_state_text
    @sea_state_text ||= SeaState.describe(@marine[:wave_height] || 0)
  end
end
