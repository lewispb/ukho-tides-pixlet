# frozen_string_literal: true

# Converts wind/swell direction in degrees to cardinal direction
# with 5×5 pixel arrow bitmaps for display.
module Compass
  CARDINALS = %w[N NE E SE S SW W NW].freeze

  # 5×5 pixel arrows for each cardinal direction
  ARROWS = {
    "N"  => [[0,0,1,0,0],[0,1,1,1,0],[1,0,1,0,1],[0,0,1,0,0],[0,0,1,0,0]],
    "NE" => [[0,1,1,1,0],[0,0,1,1,0],[0,1,0,1,0],[1,1,0,0,0],[1,0,0,0,0]],
    "E"  => [[0,0,1,0,0],[0,1,0,0,0],[1,1,1,1,1],[0,1,0,0,0],[0,0,1,0,0]],
    "SE" => [[1,0,0,0,0],[1,1,0,0,0],[0,1,0,1,0],[0,0,1,1,0],[0,1,1,1,0]],
    "S"  => [[0,0,1,0,0],[0,0,1,0,0],[1,0,1,0,1],[0,1,1,1,0],[0,0,1,0,0]],
    "SW" => [[0,0,0,0,1],[0,0,0,1,1],[0,1,0,1,0],[0,1,1,0,0],[0,1,1,1,0]],
    "W"  => [[0,0,1,0,0],[0,0,0,1,0],[1,1,1,1,1],[0,0,0,1,0],[0,0,1,0,0]],
    "NW" => [[0,1,1,1,0],[0,1,1,0,0],[0,1,0,1,0],[0,0,0,1,1],[0,0,0,0,1]],
  }.freeze

  def self.cardinal(degrees)
    index = ((degrees + 22.5) % 360 / 45).floor
    CARDINALS[index]
  end

  def self.arrow_for(degrees)
    ARROWS[cardinal(degrees)]
  end
end
