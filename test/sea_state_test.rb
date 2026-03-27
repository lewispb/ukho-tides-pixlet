# frozen_string_literal: true

require_relative "test_helper"
require "sea_state"

class SeaStateTest < Minitest::Test
  def test_douglas_scale
    assert_equal "Calm",        SeaState.describe(0.0)
    assert_equal "Smooth",      SeaState.describe(0.3)
    assert_equal "Slight",      SeaState.describe(1.0)
    assert_equal "Mod",         SeaState.describe(2.0)
    assert_equal "Rough",       SeaState.describe(3.0)
    assert_equal "V.Rough",     SeaState.describe(5.0)
    assert_equal "High",        SeaState.describe(7.0)
    assert_equal "V.High",      SeaState.describe(12.0)
    assert_equal "Phenomenal",  SeaState.describe(15.0)
  end
end
