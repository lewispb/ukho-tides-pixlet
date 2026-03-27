# frozen_string_literal: true

require "tempfile"

# Text and icon rendering for Tidbyt LED display.
# Uses ImageMagick with Tom Thumb BDF font for crisp pixel-perfect text.
# Arrows are hand-drawn pixel icons.
module BitmapFont
  FONT_PATH = File.expand_path("../fonts/tom-thumb.bdf", __dir__)
  FONT_SIZE = 6

  # 6×13 bitmap font for larger text (marine screen).
  LARGE_FONT_PATH = File.expand_path("../fonts/6x13.bdf", __dir__)
  LARGE_FONT_SIZE = 13

  # Up arrow (▲) — 5x5
  UP_ARROW = [
    [0, 0, 1, 0, 0],
    [0, 1, 1, 1, 0],
    [1, 1, 1, 1, 1],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
  ].freeze

  # Down arrow (▼) — 5x5
  DOWN_ARROW = [
    [1, 1, 1, 1, 1],
    [0, 1, 1, 1, 0],
    [0, 0, 1, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
  ].freeze

  module_function

  # Render text onto an existing PNG file using ImageMagick.
  # color is a hex string like "#00ccff". font_path and font_size override the defaults.
  def draw_text_on_file(png_path, x, y, text, color, font_path: FONT_PATH, font_size: FONT_SIZE)
    system(
      "magick", png_path,
      "-font", font_path,
      "-pointsize", font_size.to_s,
      "-fill", color,
      "-annotate", "+#{x}+#{y}", text,
      png_path,
      exception: true
    )
  end

  # Convert PNG to WebP.
  def convert_to_webp(png_path, webp_path)
    system("magick", png_path, "-define", "webp:lossless=true", webp_path, exception: true)
  end

  # Measure approximate pixel width of text.
  # Tom Thumb is 4px advance per char at FONT_SIZE; scale proportionally for other sizes.
  def text_width(text, font_size: FONT_SIZE)
    (text.length * 4 * font_size / FONT_SIZE.to_f).ceil
  end

  # Draw a special arrow glyph (UP_ARROW or DOWN_ARROW) at (x, y) onto a ChunkyPNG image.
  def draw_arrow(image, x, y, arrow, color)
    arrow.each_with_index do |row, ry|
      row.each_with_index do |pixel, rx|
        if pixel == 1
          px = x + rx
          py = y + ry
          image[px, py] = color if px >= 0 && px < image.width && py >= 0 && py < image.height
        end
      end
    end
  end
end
