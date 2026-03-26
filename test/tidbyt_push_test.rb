# frozen_string_literal: true

require_relative "test_helper"
require "tidbyt_push"

class TidbytPushTest < Minitest::Test
  def setup
    @push = TidbytPush.new(device_id: "test-device", api_token: "test-token")
  end

  def test_push_sends_correct_request
    stub_request(:post, "https://api.tidbyt.com/v0/devices/test-device/push")
      .with(
        headers: {
          "Authorization" => "Bearer test-token",
          "Content-Type" => "application/json",
        }
      )
      .to_return(status: 200, body: "{}")

    result = @push.push("fake-webp-data")
    assert_equal true, result

    assert_requested(:post, "https://api.tidbyt.com/v0/devices/test-device/push") do |req|
      body = JSON.parse(req.body)
      body["installationID"] == "ukho-tides" &&
        body["background"] == false &&
        body["image"] == Base64.strict_encode64("fake-webp-data")
    end
  end

  def test_push_with_custom_installation_id
    stub_request(:post, "https://api.tidbyt.com/v0/devices/test-device/push")
      .to_return(status: 200, body: "{}")

    @push.push("data", installation_id: "custom-id")

    assert_requested(:post, "https://api.tidbyt.com/v0/devices/test-device/push") do |req|
      JSON.parse(req.body)["installationID"] == "custom-id"
    end
  end

  def test_push_raises_on_error
    stub_request(:post, "https://api.tidbyt.com/v0/devices/test-device/push")
      .to_return(status: 403, body: "Forbidden")

    error = assert_raises(RuntimeError) { @push.push("data") }
    assert_match(/403/, error.message)
  end

  def test_push_raises_on_server_error
    stub_request(:post, "https://api.tidbyt.com/v0/devices/test-device/push")
      .to_return(status: 500, body: "Internal Server Error")

    error = assert_raises(RuntimeError) { @push.push("data") }
    assert_match(/500/, error.message)
  end
end
