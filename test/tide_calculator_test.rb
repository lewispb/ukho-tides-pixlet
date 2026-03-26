# frozen_string_literal: true

require_relative "test_helper"
require "tide_calculator"

class TideCalculatorTest < Minitest::Test
  def setup
    @base_time = Time.utc(2026, 3, 26, 12, 0, 0)

    @events = [
      { type: :high, time: @base_time - 3600,  height: 4.8 },  # 11:00
      { type: :low,  time: @base_time + 3 * 3600, height: 1.2 }, # 15:00
      { type: :high, time: @base_time + 9 * 3600, height: 5.0 }, # 21:00
      { type: :low,  time: @base_time + 15 * 3600, height: 0.9 }, # 03:00 next day
    ]

    @calculator = TideCalculator.new(@events)
  end

  def test_events_sorted_by_time
    shuffled = @events.shuffle
    calc = TideCalculator.new(shuffled)
    times = calc.events.map { |e| e[:time] }
    assert_equal times.sort, times
  end

  def test_next_high_returns_first_high_after_now
    result = @calculator.next_high(@base_time)
    assert_equal :high, result[:type]
    assert_equal 5.0, result[:height]
    assert_equal @base_time + 9 * 3600, result[:time]
  end

  def test_next_high_returns_nil_when_none
    far_future = @base_time + 100 * 3600
    assert_nil @calculator.next_high(far_future)
  end

  def test_next_low_returns_first_low_after_now
    result = @calculator.next_low(@base_time)
    assert_equal :low, result[:type]
    assert_equal 1.2, result[:height]
  end

  def test_next_low_returns_nil_when_none
    far_future = @base_time + 100 * 3600
    assert_nil @calculator.next_low(far_future)
  end

  def test_curve_points_returns_64_points
    points = @calculator.curve_points(@base_time)
    assert_equal 64, points.length
  end

  def test_curve_points_x_values_are_0_to_63
    points = @calculator.curve_points(@base_time)
    xs = points.map(&:first)
    assert_equal (0..63).to_a, xs
  end

  def test_curve_points_heights_are_within_event_range
    points = @calculator.curve_points(@base_time)
    heights = points.map(&:last)

    min_height = @events.map { |e| e[:height] }.min
    max_height = @events.map { |e| e[:height] }.max

    heights.each do |h|
      assert h >= min_height - 0.01, "Height #{h} below min #{min_height}"
      assert h <= max_height + 0.01, "Height #{h} above max #{max_height}"
    end
  end

  def test_interpolation_at_event_time_returns_event_height
    # At the exact time of the first high tide (11:00), should be ~4.8
    calc = TideCalculator.new(@events)
    # The first event is at base_time - 3600
    points = calc.curve_points(@base_time - 3600) # center on 11:00
    # Point 32 should be at center (11:00), which is the high tide
    center_height = points[32].last
    assert_in_delta 4.8, center_height, 0.1
  end

  def test_interpolation_midpoint_between_high_and_low
    # Midpoint between high (4.8) and low (1.2) should be ~3.0
    mid_time = @base_time - 3600 + ((@base_time + 3 * 3600) - (@base_time - 3600)) / 2
    calc = TideCalculator.new(@events)
    points = calc.curve_points(mid_time)
    mid_height = points[32].last
    assert_in_delta 3.0, mid_height, 0.1
  end

  def test_y_limits_include_padding
    y_min, y_max = @calculator.y_limits
    assert y_min < @events.map { |e| e[:height] }.min
    assert y_max > @events.map { |e| e[:height] }.max
  end

  def test_y_limits_minimum_padding
    # Events with small range — padding should be at least 0.3
    events = [
      { type: :high, time: @base_time, height: 3.0 },
      { type: :low,  time: @base_time + 3600, height: 2.8 },
    ]
    calc = TideCalculator.new(events)
    y_min, y_max = calc.y_limits
    assert y_min <= 2.5
    assert y_max >= 3.3
  end

  def test_curve_points_with_time_objects
    # Ensure Time objects work (not just floats)
    points = @calculator.curve_points(Time.now.utc)
    assert_equal 64, points.length
    points.each do |x, h|
      assert_kind_of Integer, x
      assert_kind_of Float, h
    end
  end
end
