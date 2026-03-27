# frozen_string_literal: true

require "chunky_png"
require "tempfile"
require_relative "bitmap_font"

# 64×32 pixel canvas for Tidbyt LED display.
# Wraps ChunkyPNG for pixel drawing and ImageMagick for text + WebP conversion.
class PixelCanvas
  WIDTH  = 64
  HEIGHT = 32

  attr_reader :image

  def initialize(background: ChunkyPNG::Color::BLACK)
    @image = ChunkyPNG::Image.new(WIDTH, HEIGHT, background)
  end

  def draw_pixel(x, y, color)
    @image[x, y] = color if in_bounds?(x, y)
  end

  def draw_bitmap(x:, y:, bitmap:, color:)
    bitmap.each_with_index do |row, ry|
      row.each_with_index do |pixel, rx|
        draw_pixel(x + rx, y + ry, color) if pixel == 1
      end
    end
  end

  # Yields the PNG path for ImageMagick text annotation, then converts to WebP.
  def to_webp
    png_file  = Tempfile.new(["canvas", ".png"])
    webp_file = Tempfile.new(["canvas", ".webp"])

    begin
      @image.save(png_file.path)
      yield png_file.path if block_given?
      BitmapFont.convert_to_webp(png_file.path, webp_file.path)
      File.binread(webp_file.path)
    ensure
      png_file.close!
      webp_file.close!
    end
  end

  private

  def in_bounds?(x, y)
    x >= 0 && x < WIDTH && y >= 0 && y < HEIGHT
  end
end
