# frozen_string_literal: true

# 3x5 pixel bitmap font for Tidbyt LED display rendering.
# Each glyph is a 5-element array of 3-bit row bitmasks (MSB = leftmost pixel).
module BitmapFont
  GLYPHS = {
    "A" => [0b111, 0b101, 0b111, 0b101, 0b101],
    "B" => [0b110, 0b101, 0b110, 0b101, 0b110],
    "C" => [0b111, 0b100, 0b100, 0b100, 0b111],
    "D" => [0b110, 0b101, 0b101, 0b101, 0b110],
    "E" => [0b111, 0b100, 0b110, 0b100, 0b111],
    "F" => [0b111, 0b100, 0b110, 0b100, 0b100],
    "G" => [0b111, 0b100, 0b101, 0b101, 0b111],
    "H" => [0b101, 0b101, 0b111, 0b101, 0b101],
    "I" => [0b111, 0b010, 0b010, 0b010, 0b111],
    "J" => [0b011, 0b001, 0b001, 0b101, 0b111],
    "K" => [0b101, 0b101, 0b110, 0b101, 0b101],
    "L" => [0b100, 0b100, 0b100, 0b100, 0b111],
    "M" => [0b101, 0b111, 0b111, 0b101, 0b101],
    "N" => [0b101, 0b111, 0b111, 0b101, 0b101],
    "O" => [0b111, 0b101, 0b101, 0b101, 0b111],
    "P" => [0b111, 0b101, 0b111, 0b100, 0b100],
    "Q" => [0b111, 0b101, 0b101, 0b111, 0b001],
    "R" => [0b111, 0b101, 0b111, 0b110, 0b101],
    "S" => [0b111, 0b100, 0b111, 0b001, 0b111],
    "T" => [0b111, 0b010, 0b010, 0b010, 0b010],
    "U" => [0b101, 0b101, 0b101, 0b101, 0b111],
    "V" => [0b101, 0b101, 0b101, 0b101, 0b010],
    "W" => [0b101, 0b101, 0b111, 0b111, 0b101],
    "X" => [0b101, 0b101, 0b010, 0b101, 0b101],
    "Y" => [0b101, 0b101, 0b010, 0b010, 0b010],
    "Z" => [0b111, 0b001, 0b010, 0b100, 0b111],
    "0" => [0b111, 0b101, 0b101, 0b101, 0b111],
    "1" => [0b010, 0b110, 0b010, 0b010, 0b111],
    "2" => [0b111, 0b001, 0b111, 0b100, 0b111],
    "3" => [0b111, 0b001, 0b111, 0b001, 0b111],
    "4" => [0b101, 0b101, 0b111, 0b001, 0b001],
    "5" => [0b111, 0b100, 0b111, 0b001, 0b111],
    "6" => [0b111, 0b100, 0b111, 0b101, 0b111],
    "7" => [0b111, 0b001, 0b001, 0b001, 0b001],
    "8" => [0b111, 0b101, 0b111, 0b101, 0b111],
    "9" => [0b111, 0b101, 0b111, 0b001, 0b111],
    " " => [0b000, 0b000, 0b000, 0b000, 0b000],
    "." => [0b000, 0b000, 0b000, 0b000, 0b010],
    ":" => [0b000, 0b010, 0b000, 0b010, 0b000],
    "-" => [0b000, 0b000, 0b111, 0b000, 0b000],
  }.freeze

  GLYPH_WIDTH  = 3
  GLYPH_HEIGHT = 5
  CHAR_SPACING = 1

  # Up arrow (▲) — 5x5
  UP_ARROW = [
    [0, 0, 1, 0, 0],
    [0, 1, 1, 1, 0],
    [1, 1, 1, 1, 1],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
  ].freeze

  # Down arrow (▼) — 5x5
  DOWN_ARROW = [
    [1, 1, 1, 1, 1],
    [0, 1, 1, 1, 0],
    [0, 0, 1, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
  ].freeze

  module_function

  # Draw a string onto a ChunkyPNG image at (x, y) in the given color.
  # Returns the x position after the last character (for chaining).
  def draw_text(image, x, y, text, color)
    cursor_x = x
    text.each_char do |ch|
      glyph = GLYPHS[ch.upcase]
      next unless glyph

      GLYPH_HEIGHT.times do |row|
        bits = glyph[row]
        GLYPH_WIDTH.times do |col|
          if bits & (1 << (GLYPH_WIDTH - 1 - col)) != 0
            px = cursor_x + col
            py = y + row
            image[px, py] = color if px >= 0 && px < image.width && py >= 0 && py < image.height
          end
        end
      end
      cursor_x += GLYPH_WIDTH + CHAR_SPACING
    end
    cursor_x
  end

  # Draw a special arrow glyph (UP_ARROW or DOWN_ARROW) at (x, y).
  def draw_arrow(image, x, y, arrow, color)
    arrow.each_with_index do |row, ry|
      row.each_with_index do |pixel, rx|
        if pixel == 1
          px = x + rx
          py = y + ry
          image[px, py] = color if px >= 0 && px < image.width && py >= 0 && py < image.height
        end
      end
    end
  end

  # Measure the pixel width of a string.
  def text_width(text)
    return 0 if text.empty?
    text.length * (GLYPH_WIDTH + CHAR_SPACING) - CHAR_SPACING
  end
end
