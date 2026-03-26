# frozen_string_literal: true

require_relative "test_helper"
require "chunky_png"
require "bitmap_font"

class BitmapFontTest < Minitest::Test
  def setup
    @image = ChunkyPNG::Image.new(64, 32, ChunkyPNG::Color::BLACK)
    @white = ChunkyPNG::Color.rgb(255, 255, 255)
  end

  def test_text_width
    # Tom Thumb is 4px advance per character
    assert_equal 12, BitmapFont.text_width("ABC")
    assert_equal 4, BitmapFont.text_width("A")
    assert_equal 0, BitmapFont.text_width("")
  end

  def test_draw_text_on_file
    skip "ImageMagick not installed" unless system("which convert", out: File::NULL, err: File::NULL)

    file = Tempfile.new(["test", ".png"])
    begin
      @image.save(file.path)
      BitmapFont.draw_text_on_file(file.path, 1, 5, "TEST", "#ffffff")

      result = ChunkyPNG::Image.from_file(file.path)
      # Should have some non-black pixels where text was drawn
      white_pixels = 0
      (0...64).each do |x|
        (0...6).each do |y|
          white_pixels += 1 if result[x, y] != ChunkyPNG::Color::BLACK
        end
      end
      assert white_pixels > 0, "Expected text pixels to be drawn"
    ensure
      file.close!
    end
  end

  def test_draw_arrow_up
    BitmapFont.draw_arrow(@image, 0, 0, BitmapFont::UP_ARROW, @white)

    # Top row of UP_ARROW: [0, 0, 1, 0, 0]
    assert_equal ChunkyPNG::Color::BLACK, @image[0, 0]
    assert_equal @white, @image[2, 0]

    # Second row: [0, 1, 1, 1, 0]
    assert_equal @white, @image[1, 1]
    assert_equal @white, @image[2, 1]
    assert_equal @white, @image[3, 1]
  end

  def test_draw_arrow_down
    BitmapFont.draw_arrow(@image, 0, 0, BitmapFont::DOWN_ARROW, @white)

    # Top row of DOWN_ARROW: [1, 1, 1, 1, 1]
    5.times { |x| assert_equal @white, @image[x, 0] }
  end

  def test_draw_arrow_clips_at_bounds
    # Should not raise when drawing near edges
    BitmapFont.draw_arrow(@image, 62, 30, BitmapFont::UP_ARROW, @white)
  end
end
