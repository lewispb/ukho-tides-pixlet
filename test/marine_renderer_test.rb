# frozen_string_literal: true

require_relative "test_helper"
require "marine_renderer"

class MarineRendererTest < Minitest::Test
  def setup
    @marine = {
      wave_height: 1.2,
      wave_direction: 220.0,
      wave_period: 6.5,
      swell_height: 0.8,
      swell_period: 10.0,
      swell_direction: 240.0,
    }

    @wind = {
      speed_kn: 15.0,
      direction: 180.0,
      gusts_kn: 22.0,
    }

    @renderer = MarineRenderer.new(marine: @marine, wind: @wind)
  end

  def test_render_image_dimensions
    image = @renderer.send(:render_image)
    assert_equal 64, image.width
    assert_equal 32, image.height
  end

  def test_render_image_has_wind_icon
    image = @renderer.send(:render_image)
    amber = ChunkyPNG::Color.rgb(255, 170, 0)

    # Wind icon at (0,0) — top row is all 1s
    assert_equal amber, image[0, 0]
    assert_equal amber, image[4, 0]
  end

  def test_render_image_has_wind_text
    image = @renderer.send(:render_image)
    cyan = ChunkyPNG::Color.rgb(0, 204, 255)

    # Wind speed text starts at x=7, row 0 — some cyan pixels should exist
    cyan_count = 0
    (7...40).each do |x|
      (0...5).each do |y|
        cyan_count += 1 if image[x, y] == cyan
      end
    end
    assert cyan_count > 0, "Expected cyan wind text pixels"
  end

  def test_render_image_has_swell_text
    image = @renderer.send(:render_image)
    green = ChunkyPNG::Color.rgb(0, 204, 68)

    green_count = 0
    (7...50).each do |x|
      (11...16).each do |y|
        green_count += 1 if image[x, y] == green
      end
    end
    assert green_count > 0, "Expected green swell text pixels"
  end

  def test_render_image_has_sea_state_text
    image = @renderer.send(:render_image)
    blue = ChunkyPNG::Color.rgb(0, 119, 255)

    blue_count = 0
    (17...60).each do |x|
      (22...27).each do |y|
        blue_count += 1 if image[x, y] == blue
      end
    end
    assert blue_count > 0, "Expected blue sea state text pixels"
  end

  def test_to_webp_returns_webp_data
    skip "ImageMagick not installed" unless system("which convert", out: File::NULL, err: File::NULL)

    webp = @renderer.to_webp
    assert webp.start_with?("RIFF"), "Expected WebP RIFF header"
  end

  def test_degrees_to_cardinal
    r = @renderer
    assert_equal "N",  r.send(:degrees_to_cardinal, 0)
    assert_equal "N",  r.send(:degrees_to_cardinal, 10)
    assert_equal "NE", r.send(:degrees_to_cardinal, 45)
    assert_equal "E",  r.send(:degrees_to_cardinal, 90)
    assert_equal "S",  r.send(:degrees_to_cardinal, 180)
    assert_equal "W",  r.send(:degrees_to_cardinal, 270)
    assert_equal "N",  r.send(:degrees_to_cardinal, 350)
  end

  def test_sea_state_descriptions
    r = @renderer
    assert_equal "CALM",   r.send(:sea_state_description, 0.0)
    assert_equal "SMOOTH", r.send(:sea_state_description, 0.3)
    assert_equal "SLIGHT", r.send(:sea_state_description, 1.0)
    assert_equal "MOD",    r.send(:sea_state_description, 2.0)
    assert_equal "ROUGH",  r.send(:sea_state_description, 3.0)
    assert_equal "VROUGH", r.send(:sea_state_description, 5.0)
    assert_equal "HIGH",   r.send(:sea_state_description, 7.0)
    assert_equal "VHIGH",  r.send(:sea_state_description, 12.0)
    assert_equal "PHENML", r.send(:sea_state_description, 15.0)
  end

  def test_handles_nil_values
    marine = { wave_height: nil, swell_height: nil, swell_period: nil, swell_direction: nil,
               wave_direction: nil, wave_period: nil }
    wind = { speed_kn: nil, direction: nil, gusts_kn: nil }

    renderer = MarineRenderer.new(marine: marine, wind: wind)
    image = renderer.send(:render_image)
    assert_equal 64, image.width
  end
end
