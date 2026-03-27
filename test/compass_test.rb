# frozen_string_literal: true

require_relative "test_helper"
require "compass"

class CompassTest < Minitest::Test
  def test_cardinal_directions
    assert_equal "N",  Compass.cardinal(0)
    assert_equal "NE", Compass.cardinal(45)
    assert_equal "E",  Compass.cardinal(90)
    assert_equal "S",  Compass.cardinal(180)
    assert_equal "W",  Compass.cardinal(270)
    assert_equal "N",  Compass.cardinal(350)
  end

  def test_arrow_for_returns_bitmap
    arrow = Compass.arrow_for(180)
    assert_equal 5, arrow.length
    assert_equal 5, arrow.first.length
  end

  def test_arrow_for_all_cardinals
    Compass::CARDINALS.each do |dir|
      assert Compass::ARROWS.key?(dir), "Missing arrow for #{dir}"
    end
  end
end
