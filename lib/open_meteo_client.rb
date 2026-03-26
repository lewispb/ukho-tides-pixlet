# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

class OpenMeteoClient
  MARINE_BASE  = "https://marine-api.open-meteo.com/v1/marine"
  WEATHER_BASE = "https://api.open-meteo.com/v1/forecast"

  def initialize(latitude:, longitude:)
    @latitude = latitude
    @longitude = longitude
  end

  def current_marine
    params = {
      latitude: @latitude,
      longitude: @longitude,
      current: "wave_height,wave_direction,wave_period,swell_wave_height,swell_wave_period,swell_wave_direction",
    }
    data = get(MARINE_BASE, params)
    current = data["current"] || {}

    {
      wave_height: current["wave_height"]&.to_f,
      wave_direction: current["wave_direction"]&.to_f,
      wave_period: current["wave_period"]&.to_f,
      swell_height: current["swell_wave_height"]&.to_f,
      swell_period: current["swell_wave_period"]&.to_f,
      swell_direction: current["swell_wave_direction"]&.to_f,
    }
  end

  def current_wind
    params = {
      latitude: @latitude,
      longitude: @longitude,
      current: "wind_speed_10m,wind_direction_10m,wind_gusts_10m",
      wind_speed_unit: "kn",
    }
    data = get(WEATHER_BASE, params)
    current = data["current"] || {}

    {
      speed_kn: current["wind_speed_10m"]&.to_f,
      direction: current["wind_direction_10m"]&.to_f,
      gusts_kn: current["wind_gusts_10m"]&.to_f,
    }
  end

  private

  def get(base_url, params)
    uri = URI(base_url)
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(Net::HTTP::Get.new(uri))
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "Open-Meteo API error: #{response.code} #{response.body}"
    end

    JSON.parse(response.body)
  end
end
