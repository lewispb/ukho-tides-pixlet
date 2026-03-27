# frozen_string_literal: true

# Text rendering for Tidbyt LED display via ImageMagick with BDF bitmap fonts.
module BitmapFont
  FONT_PATH = File.expand_path("../fonts/tom-thumb.bdf", __dir__)
  FONT_SIZE = 6

  LARGE_FONT_PATH = File.expand_path("../fonts/6x13.bdf", __dir__)
  LARGE_FONT_SIZE = 13

  module_function

  def draw_text(png_path, x:, y:, text:, color:, font_path: FONT_PATH, font_size: FONT_SIZE)
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

  def convert_to_webp(png_path, webp_path)
    system("magick", png_path, "-define", "webp:lossless=true", webp_path, exception: true)
  end

  def text_width(text, font_size: FONT_SIZE)
    (text.length * 4 * font_size / FONT_SIZE.to_f).ceil
  end
end
