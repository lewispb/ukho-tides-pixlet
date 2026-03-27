# frozen_string_literal: true

require_relative "test_helper"
require "chunky_png"
require "bitmap_font"

class BitmapFontTest < Minitest::Test
  def test_text_width
    assert_equal 12, BitmapFont.text_width("ABC")
    assert_equal 4, BitmapFont.text_width("A")
    assert_equal 0, BitmapFont.text_width("")
  end

  def test_draw_text
    skip "ImageMagick not installed" unless system("which convert", out: File::NULL, err: File::NULL)

    image = ChunkyPNG::Image.new(64, 32, ChunkyPNG::Color::BLACK)
    file = Tempfile.new(["test", ".png"])
    begin
      image.save(file.path)
      BitmapFont.draw_text(file.path, x: 1, y: 5, text: "TEST", color: "#ffffff")

      result = ChunkyPNG::Image.from_file(file.path)
      white_pixels = (0...64).sum { |x| (0...6).count { |y| result[x, y] != ChunkyPNG::Color::BLACK } }
      assert white_pixels > 0, "Expected text pixels to be drawn"
    ensure
      file.close!
    end
  end
end
