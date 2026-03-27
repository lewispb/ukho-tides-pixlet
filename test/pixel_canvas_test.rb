# frozen_string_literal: true

require_relative "test_helper"
require "pixel_canvas"

class PixelCanvasTest < Minitest::Test
  def setup
    @canvas = PixelCanvas.new
    @white = ChunkyPNG::Color.rgb(255, 255, 255)
  end

  def test_draw_pixel
    @canvas.draw_pixel(5, 5, @white)
    assert_equal @white, @canvas.image[5, 5]
  end

  def test_draw_pixel_clips_at_bounds
    @canvas.draw_pixel(-1, 0, @white)
    @canvas.draw_pixel(0, -1, @white)
    @canvas.draw_pixel(64, 0, @white)
    @canvas.draw_pixel(0, 32, @white)
    # No error raised
  end

  def test_draw_bitmap
    bitmap = [[1, 0], [0, 1]]
    @canvas.draw_bitmap(x: 0, y: 0, bitmap: bitmap, color: @white)

    assert_equal @white, @canvas.image[0, 0]
    assert_equal ChunkyPNG::Color::BLACK, @canvas.image[1, 0]
    assert_equal ChunkyPNG::Color::BLACK, @canvas.image[0, 1]
    assert_equal @white, @canvas.image[1, 1]
  end

  def test_draw_bitmap_clips_at_bounds
    bitmap = [[1, 1, 1, 1, 1]]
    @canvas.draw_bitmap(x: 62, y: 31, bitmap: bitmap, color: @white)
    # No error raised
  end

  def test_to_webp
    skip "ImageMagick not installed" unless system("which convert", out: File::NULL, err: File::NULL)

    webp = @canvas.to_webp
    assert webp.start_with?("RIFF"), "Expected WebP RIFF header"
  end
end
