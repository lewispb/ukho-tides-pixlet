# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

class UkhoClient
  API_BASE = "https://admiraltyapi.azure-api.net/uktidalapi/api/V1/Stations"

  # Tidal predictions are pre-computed and never change; cache for 6h so we
  # minimise API calls while always having fresh upcoming events in the window.
  CACHE_TTL = 6 * 3600

  def initialize(api_key)
    @api_key = api_key
  end

  def station_info(station_id)
    data = get("#{API_BASE}/#{station_id}")
    coords = data.dig("geometry", "coordinates") || []
    {
      name: data.dig("properties", "Name") || station_id,
      longitude: coords[0]&.to_f,
      latitude: coords[1]&.to_f,
    }
  end

  def station_name(station_id)
    station_info(station_id)[:name]
  end

  def tidal_events(station_id)
    raw = cached_get("#{API_BASE}/#{station_id}/TidalEvents", cache_key: "tidal_events_#{station_id}")
    raw.map do |event|
      {
        type: event["EventType"] == "HighWater" ? :high : :low,
        time: Time.parse(event["DateTime"] + " UTC"),
        height: event["Height"].to_f,
      }
    end
  end

  private

  # Fetch with file-based caching. Returns parsed JSON.
  def cached_get(url, cache_key:)
    cache_file = File.join(ENV.fetch("UKHO_CACHE_DIR", "/tmp"), "ukho_#{cache_key}.json")

    if File.exist?(cache_file) && (Time.now - File.mtime(cache_file)) < CACHE_TTL
      data = JSON.parse(File.read(cache_file))
      puts "[ukho-tides] Cache hit for #{cache_key} (age #{(Time.now - File.mtime(cache_file)).to_i}s)"
      return data
    end

    puts "[ukho-tides] Cache miss for #{cache_key}, fetching from API..."
    data = get(url)
    File.write(cache_file, JSON.generate(data))
    data
  end

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
