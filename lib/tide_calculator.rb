# frozen_string_literal: true

class TideCalculator
  WINDOW_HOURS = 6
  NUM_POINTS = 64

  attr_reader :events

  def initialize(events)
    @events = events.sort_by { |e| e[:time] }
  end

  # Returns the next high water event after the given time, or nil.
  def next_high(now)
    @events.find { |e| e[:type] == :high && e[:time] > now }
  end

  # Returns the next low water event after the given time, or nil.
  def next_low(now)
    @events.find { |e| e[:type] == :low && e[:time] > now }
  end

  # Generate 64 (x, y) tide curve points spanning 12 hours centered on now.
  # x = pixel column (0..63), y = interpolated height in metres.
  def curve_points(now)
    t_start = now.to_f - (WINDOW_HOURS * 3600)
    t_end   = now.to_f + (WINDOW_HOURS * 3600)
    dt = (t_end - t_start) / NUM_POINTS

    NUM_POINTS.times.map do |i|
      t = t_start + (i * dt)
      height = interpolate_height(t)
      [i, height]
    end
  end

  # Y-axis limits with padding for the graph.
  def y_limits
    heights = @events.map { |e| e[:height] }
    min = heights.min || 0
    max = heights.max || 5
    padding = (max - min) * 0.15
    padding = 0.3 if padding < 0.3
    [min - padding, max + padding]
  end

  private

  # Cosine interpolation between bracketing high/low events.
  def interpolate_height(t)
    prev_event = nil
    next_event = nil

    t = t.to_f
    @events.each_cons(2) do |a, b|
      if a[:time].to_f <= t && b[:time].to_f > t
        prev_event = a
        next_event = b
        break
      end
    end

    # Before first event or after last — clamp to nearest
    if prev_event.nil? || next_event.nil?
      nearest = @events.min_by { |e| (e[:time].to_f - t).abs }
      return nearest ? nearest[:height] : 0
    end

    progress = (t - prev_event[:time].to_f) / (next_event[:time].to_f - prev_event[:time].to_f)
    h0 = prev_event[:height]
    h1 = next_event[:height]
    h0 + (h1 - h0) * (1 - Math.cos(Math::PI * progress)) / 2.0
  end
end
