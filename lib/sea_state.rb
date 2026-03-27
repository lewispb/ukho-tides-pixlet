# frozen_string_literal: true

# Douglas Sea Scale — classifies wave height into human-readable descriptions.
module SeaState
  def self.describe(wave_height)
    case wave_height
    when 0...0.1    then "Calm"
    when 0.1...0.5  then "Smooth"
    when 0.5...1.25 then "Slight"
    when 1.25...2.5 then "Mod"
    when 2.5...4.0  then "Rough"
    when 4.0...6.0  then "V.Rough"
    when 6.0...9.0  then "High"
    when 9.0...14.0 then "V.High"
    else                 "Phenomenal"
    end
  end
end
