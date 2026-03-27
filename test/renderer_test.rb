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

  def test_to_webp_returns_webp_data
    skip "ImageMagick not installed" unless system("which convert", out: File::NULL, err: File::NULL)

    webp = @renderer.to_webp
    assert_kind_of String, webp
    assert webp.start_with?("RIFF"), "Expected WebP RIFF header"
  end

  def test_to_webp_produces_nonzero_data
    skip "ImageMagick not installed" unless system("which convert", out: File::NULL, err: File::NULL)

    webp = @renderer.to_webp
    assert webp.bytesize > 100, "Expected substantial WebP data"
  end

  def test_format_time_bst
    # March 26 2026 is during BST (clocks change March 29 2026)
    # Actually, BST starts last Sunday of March. In 2026 that's March 29.
    # So March 26 is still GMT.
    summer = Time.utc(2026, 7, 15, 12, 0, 0)
    renderer = Renderer.new("Test", @calculator, now: summer)
    # 12:00 UTC = 13:00 BST
    assert_equal "13:00", renderer.send(:format_time, summer)
  end

  def test_format_time_gmt
    winter = Time.utc(2026, 1, 15, 12, 0, 0)
    renderer = Renderer.new("Test", @calculator, now: winter)
    assert_equal "12:00", renderer.send(:format_time, winter)
  end

  def test_format_height
    assert_equal "4.8m", @renderer.send(:format_height, 4.8)
    assert_equal "1.2m", @renderer.send(:format_height, 1.2)
    assert_equal "0.0m", @renderer.send(:format_height, 0.0)
  end
end
