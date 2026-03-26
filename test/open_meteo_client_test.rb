# frozen_string_literal: true

require_relative "test_helper"
require "open_meteo_client"

class OpenMeteoClientTest < Minitest::Test
  def setup
    @client = OpenMeteoClient.new(latitude: 50.2384, longitude: -3.7718)
  end

  def test_current_marine
    body = {
      "current" => {
        "wave_height" => 1.2,
        "wave_direction" => 220.0,
        "wave_period" => 6.5,
        "swell_wave_height" => 0.8,
        "swell_wave_period" => 10.0,
        "swell_wave_direction" => 240.0,
      },
    }.to_json

    stub_request(:get, /marine-api\.open-meteo\.com/)
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    result = @client.current_marine

    assert_equal 1.2, result[:wave_height]
    assert_equal 0.8, result[:swell_height]
    assert_equal 10.0, result[:swell_period]
    assert_equal 240.0, result[:swell_direction]
  end

  def test_current_wind
    body = {
      "current" => {
        "wind_speed_10m" => 15.5,
        "wind_direction_10m" => 180.0,
        "wind_gusts_10m" => 22.0,
      },
    }.to_json

    stub_request(:get, /api\.open-meteo\.com/)
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    result = @client.current_wind

    assert_equal 15.5, result[:speed_kn]
    assert_equal 180.0, result[:direction]
    assert_equal 22.0, result[:gusts_kn]
  end

  def test_current_wind_requests_knots
    stub_request(:get, /api\.open-meteo\.com/)
      .with(query: hash_including("wind_speed_unit" => "kn"))
      .to_return(status: 200, body: '{"current":{}}', headers: { "Content-Type" => "application/json" })

    @client.current_wind

    assert_requested(:get, /api\.open-meteo\.com/, times: 1)
  end

  def test_marine_raises_on_error
    stub_request(:get, /marine-api\.open-meteo\.com/)
      .to_return(status: 500, body: "error")

    assert_raises(RuntimeError) { @client.current_marine }
  end

  def test_wind_raises_on_error
    stub_request(:get, /api\.open-meteo\.com/)
      .to_return(status: 500, body: "error")

    assert_raises(RuntimeError) { @client.current_wind }
  end
end
