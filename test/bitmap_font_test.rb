# frozen_string_literal: true

require_relative "test_helper"
require "chunky_png"
require "bitmap_font"

class BitmapFontTest < Minitest::Test
  def setup
    @image = ChunkyPNG::Image.new(64, 32, ChunkyPNG::Color::BLACK)
    @white = ChunkyPNG::Color.rgb(255, 255, 255)
  end

  def test_text_width_single_char
    assert_equal 3, BitmapFont.text_width("A")
  end

  def test_text_width_multiple_chars
    # 3 chars: 3 + 1 + 3 + 1 + 3 = 11
    assert_equal 11, BitmapFont.text_width("ABC")
  end

  def test_text_width_empty
    assert_equal 0, BitmapFont.text_width("")
  end

  def test_draw_text_sets_pixels
    BitmapFont.draw_text(@image, 0, 0, "A", @white)

    # "A" top row is 0b111 — all 3 pixels lit
    assert_equal @white, @image[0, 0]
    assert_equal @white, @image[1, 0]
    assert_equal @white, @image[2, 0]
  end

  def test_draw_text_returns_cursor_position
    cursor = BitmapFont.draw_text(@image, 0, 0, "AB", @white)
    # After "AB": 2 * (3 + 1) = 8
    assert_equal 8, cursor
  end

  def test_draw_text_case_insensitive
    lower = ChunkyPNG::Image.new(64, 32, ChunkyPNG::Color::BLACK)
    upper = ChunkyPNG::Image.new(64, 32, ChunkyPNG::Color::BLACK)

    BitmapFont.draw_text(lower, 0, 0, "abc", @white)
    BitmapFont.draw_text(upper, 0, 0, "ABC", @white)

    assert_equal lower.to_blob, upper.to_blob
  end

  def test_draw_text_skips_unknown_chars
    # Should not raise, just skip the unknown char
    cursor = BitmapFont.draw_text(@image, 0, 0, "A@B", @white)
    # Only A and B rendered: 2 * (3 + 1) = 8
    assert_equal 8, cursor
  end

  def test_draw_text_clips_at_bounds
    # Drawing near the edge should not raise
    BitmapFont.draw_text(@image, 62, 0, "AB", @white)
    # First char partially visible, second clipped
    assert_equal @white, @image[62, 0]
    assert_equal @white, @image[63, 0]
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

  def test_all_glyphs_have_correct_dimensions
    BitmapFont::GLYPHS.each do |char, rows|
      assert_equal 5, rows.length, "Glyph '#{char}' should have 5 rows"
      rows.each_with_index do |bits, i|
        assert bits >= 0 && bits <= 0b111, "Glyph '#{char}' row #{i} out of 3-bit range"
      end
    end
  end
end
