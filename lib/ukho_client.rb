# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

class UkhoClient
  API_BASE = "https://admiraltyapi.azure-api.net/uktidalapi/api/V1/Stations"

  def initialize(api_key)
    @api_key = api_key
  end

  def station_name(station_id)
    data = get("#{API_BASE}/#{station_id}")
    data.dig("properties", "Name") || station_id
  end

  def tidal_events(station_id)
    data = get("#{API_BASE}/#{station_id}/TidalEvents")
    data.map do |event|
      {
        type: event["EventType"] == "HighWater" ? :high : :low,
        time: Time.parse(event["DateTime"] + " UTC"),
        height: event["Height"].to_f,
      }
    end
  end

  private

  def get(url)
    uri = URI(url)
    request = Net::HTTP::Get.new(uri)
    request["Ocp-Apim-Subscription-Key"] = @api_key

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "UKHO API error: #{response.code} #{response.body}"
    end

    JSON.parse(response.body)
  end
end
