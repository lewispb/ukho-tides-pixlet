# frozen_string_literal: true

require_relative "test_helper"
require "tide_calculator"
require "renderer"

class RendererTest < Minitest::Test
  def setup
    @now = Time.utc(2026, 3, 26, 12, 0, 0)

    events = [
      { type: :high, time: @now - 3600,       height: 4.8 },
      { type: :low,  time: @now + 3 * 3600,   height: 1.2 },
      { type: :high, time: @now + 9 * 3600,   height: 5.0 },
      { type: :low,  time: @now + 15 * 3600,  height: 0.9 },
    ]

    @calculator = TideCalculator.new(events)
    @renderer = Renderer.new("Salcombe", @calculator, now: @now)
  end

  def test_to_png_returns_binary_data
    png = @renderer.to_png
    assert_kind_of String, png
    refute_empty png
  end

  def test_render_image_dimensions
    image = @renderer.send(:render_image)
    assert_equal 64, image.width
    assert_equal 32, image.height
  end

  def test_render_image_has_station_name_pixels
    image = @renderer.send(:render_image)

    # Station name "SALCOMBE" drawn at (1, 0) in amber — first pixel of "S" should be lit
    # "S" top row is 0b111 — pixel at (1, 0) should be amber
    amber = ChunkyPNG::Color.rgb(255, 170, 0)
    assert_equal amber, image[1, 0]
  end

  def test_render_image_has_now_line
    image = @renderer.send(:render_image)
    red = ChunkyPNG::Color.rgb(255, 0, 0)

    # Red vertical line at x=32 through the graph area
    (Renderer::GRAPH_TOP..Renderer::GRAPH_BOTTOM).each do |y|
      assert_equal red, image[32, y], "Expected red at (32, #{y})"
    end
  end

  def test_render_image_has_curve_pixels
    image = @renderer.send(:render_image)
    blue = ChunkyPNG::Color.rgb(0, 119, 255)

    # At least some blue pixels should exist in the graph area
    blue_count = 0
    (0...64).each do |x|
      (Renderer::GRAPH_TOP..Renderer::GRAPH_BOTTOM).each do |y|
        blue_count += 1 if image[x, y] == blue
      end
    end
    assert blue_count > 0, "Expected blue curve pixels in graph area"
  end

  def test_render_image_has_fill_only_left_of_center
    image = @renderer.send(:render_image)
    fill = ChunkyPNG::Color.rgb(0, 34, 68)

    # Fill should only appear at x <= 32
    (33...64).each do |x|
      (Renderer::GRAPH_TOP..Renderer::GRAPH_BOTTOM).each do |y|
        refute_equal fill, image[x, y], "Unexpected fill at (#{x}, #{y})"
      end
    end
  end

  def test_to_webp_returns_webp_data
    skip "ImageMagick not installed" unless system("which convert", out: File::NULL, err: File::NULL)

    webp = @renderer.to_webp
    assert_kind_of String, webp
    # WebP files start with RIFF header
    assert webp.start_with?("RIFF"), "Expected WebP RIFF header"
  end

  def test_uk_offset_gmt_in_winter
    winter = Time.utc(2026, 1, 15, 12, 0, 0)
    renderer = Renderer.new("Test", @calculator, now: winter)
    assert_equal "+00:00", renderer.send(:uk_offset)
  end

  def test_uk_offset_bst_in_summer
    summer = Time.utc(2026, 7, 15, 12, 0, 0)
    renderer = Renderer.new("Test", @calculator, now: summer)
    assert_equal "+01:00", renderer.send(:uk_offset)
  end

  def test_format_height
    assert_equal "4.8M", @renderer.send(:format_height, 4.8)
    assert_equal "1.2M", @renderer.send(:format_height, 1.2)
    assert_equal "0.0M", @renderer.send(:format_height, 0.0)
  end
end
