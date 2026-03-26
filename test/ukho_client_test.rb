# frozen_string_literal: true

require_relative "test_helper"
require "ukho_client"

class UkhoClientTest < Minitest::Test
  def setup
    @client = UkhoClient.new("test-api-key")
  end

  def test_station_name
    stub_request(:get, "https://admiraltyapi.azure-api.net/uktidalapi/api/V1/Stations/0020")
      .with(headers: { "Ocp-Apim-Subscription-Key" => "test-api-key" })
      .to_return(
        status: 200,
        body: '{"properties":{"Name":"Salcombe"}}',
        headers: { "Content-Type" => "application/json" }
      )

    assert_equal "Salcombe", @client.station_name("0020")
  end

  def test_station_name_falls_back_to_id
    stub_request(:get, "https://admiraltyapi.azure-api.net/uktidalapi/api/V1/Stations/0020")
      .to_return(status: 200, body: '{"properties":{}}', headers: { "Content-Type" => "application/json" })

    assert_equal "0020", @client.station_name("0020")
  end

  def test_station_name_raises_on_error
    stub_request(:get, "https://admiraltyapi.azure-api.net/uktidalapi/api/V1/Stations/0020")
      .to_return(status: 401, body: "Unauthorized")

    error = assert_raises(RuntimeError) { @client.station_name("0020") }
    assert_match(/401/, error.message)
  end

  def test_tidal_events
    body = [
      { "EventType" => "HighWater", "DateTime" => "2026-03-26T14:32:00", "Height" => 4.8 },
      { "EventType" => "LowWater", "DateTime" => "2026-03-26T20:51:00", "Height" => 1.2 },
    ].to_json

    stub_request(:get, "https://admiraltyapi.azure-api.net/uktidalapi/api/V1/Stations/0020/TidalEvents")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    events = @client.tidal_events("0020")

    assert_equal 2, events.length

    assert_equal :high, events[0][:type]
    assert_equal Time.utc(2026, 3, 26, 14, 32, 0), events[0][:time]
    assert_equal 4.8, events[0][:height]

    assert_equal :low, events[1][:type]
    assert_equal Time.utc(2026, 3, 26, 20, 51, 0), events[1][:time]
    assert_equal 1.2, events[1][:height]
  end

  def test_tidal_events_raises_on_error
    stub_request(:get, "https://admiraltyapi.azure-api.net/uktidalapi/api/V1/Stations/0020/TidalEvents")
      .to_return(status: 500, body: "Internal Server Error")

    error = assert_raises(RuntimeError) { @client.tidal_events("0020") }
    assert_match(/500/, error.message)
  end

  def test_sends_api_key_header
    stub_request(:get, "https://admiraltyapi.azure-api.net/uktidalapi/api/V1/Stations/0020/TidalEvents")
      .with(headers: { "Ocp-Apim-Subscription-Key" => "test-api-key" })
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })

    @client.tidal_events("0020")

    assert_requested(:get, "https://admiraltyapi.azure-api.net/uktidalapi/api/V1/Stations/0020/TidalEvents",
      headers: { "Ocp-Apim-Subscription-Key" => "test-api-key" })
  end
end
