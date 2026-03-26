# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "base64"

class TidbytPush
  API_BASE = "https://api.tidbyt.com/v0/devices"

  def initialize(device_id:, api_token:)
    @device_id = device_id
    @api_token = api_token
  end

  def push(webp_data, installation_id: "ukho-tides")
    uri = URI("#{API_BASE}/#{@device_id}/push")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@api_token}"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(
      image: Base64.strict_encode64(webp_data),
      installationID: installation_id,
      background: false
    )

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "Tidbyt push error: #{response.code} #{response.body}"
    end

    true
  end
end
