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

  def test_to_webp_returns_webp_data
    skip "ImageMagick not installed" unless system("which convert", out: File::NULL, err: File::NULL)

    webp = @renderer.to_webp
    assert webp.start_with?("RIFF"), "Expected WebP RIFF header"
  end

  def test_wind_text_with_gusts
    assert_equal "15-22kn", @renderer.send(:wind_text)
  end

  def test_wind_text_without_gusts
    renderer = MarineRenderer.new(marine: @marine, wind: { speed_kn: 10.0, direction: 180.0, gusts_kn: nil })
    assert_equal "10kn", renderer.send(:wind_text)
  end

  def test_wind_text_gusts_equal_speed
    renderer = MarineRenderer.new(marine: @marine, wind: { speed_kn: 10.0, direction: 180.0, gusts_kn: 10.0 })
    assert_equal "10kn", renderer.send(:wind_text)
  end

  def test_swell_text
    assert_equal "0.8m 10s", @renderer.send(:swell_text)
  end

  def test_sea_state_text
    assert_equal "Sea 1.2m Slight", @renderer.send(:sea_state_text)
  end

  def test_degrees_to_cardinal
    r = @renderer
    assert_equal "N",  r.send(:degrees_to_cardinal, 0)
    assert_equal "NE", r.send(:degrees_to_cardinal, 45)
    assert_equal "E",  r.send(:degrees_to_cardinal, 90)
    assert_equal "S",  r.send(:degrees_to_cardinal, 180)
    assert_equal "W",  r.send(:degrees_to_cardinal, 270)
    assert_equal "N",  r.send(:degrees_to_cardinal, 350)
  end

  def test_sea_state_descriptions
    r = @renderer
    assert_equal "Calm",   r.send(:sea_state_description, 0.0)
    assert_equal "Smooth", r.send(:sea_state_description, 0.3)
    assert_equal "Slight", r.send(:sea_state_description, 1.0)
    assert_equal "Mod",    r.send(:sea_state_description, 2.0)
    assert_equal "Rough",  r.send(:sea_state_description, 3.0)
    assert_equal "V.Rough", r.send(:sea_state_description, 5.0)
    assert_equal "High",   r.send(:sea_state_description, 7.0)
    assert_equal "V.High", r.send(:sea_state_description, 12.0)
    assert_equal "Phenomenal", r.send(:sea_state_description, 15.0)
  end

  def test_handles_nil_values
    skip "ImageMagick not installed" unless system("which convert", out: File::NULL, err: File::NULL)

    marine = { wave_height: nil, swell_height: nil, swell_period: nil, swell_direction: nil,
               wave_direction: nil, wave_period: nil }
    wind = { speed_kn: nil, direction: nil, gusts_kn: nil }

    renderer = MarineRenderer.new(marine: marine, wind: wind)
    webp = renderer.to_webp
    assert webp.start_with?("RIFF")
  end
end
