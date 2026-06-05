#!/usr/bin/env ruby
# frozen_string_literal: true

# Regenerates the lab background bundled with the hello_world template.
# 320x224 (40x28 tiles), 16-color indexed PNG. Pure Ruby + Zlib.
#
# Composition: dark teal lab back wall with brick texture, swirling portal
# on the left, monitor with scanlines on the right, shelf with 4 shaded
# flasks, wood-grain counter, tiled floor with grout.

require "zlib"
require "fileutils"

WIDTH = 320
HEIGHT = 224

# 16-color palette, ordered for shading: each "family" has dark→light triples
# so dithering between adjacent indices reads as a gradient.
PALETTE = [
  [12,   8,  24],   # 0  black-purple
  [28,  16,  48],   # 1  wall darkest
  [56,  32,  88],   # 2  wall dark
  [88,  56, 144],   # 3  wall mid
  [128, 96, 200],   # 4  wall highlight
  [40,  24,  16],   # 5  brown darkest (counter shadow)
  [96,  56,  24],   # 6  brown mid (counter)
  [176, 120, 56],   # 7  brown light (counter top, shelf)
  [40,  40,  56],   # 8  metal dark (monitor frame, brackets)
  [120, 120, 144],  # 9  metal mid
  [232, 232, 240],  # 10 near-white (highlights, screen text)
  [24,  72,  40],   # 11 green dark (flask shadow)
  [88,  208, 96],   # 12 green light (flask body + monitor screen)
  [24,  88, 144],   # 13 cyan dark (portal mid)
  [120, 216, 248],  # 14 cyan light (portal core)
  [232, 96,  192]   # 15 magenta (portal outer, accents)
].freeze

class Canvas
  attr_reader :pixels

  def initialize(width, height)
    @width = width
    @height = height
    @pixels = Array.new(height) { Array.new(width, 0) }
  end

  def set(x, y, c)
    return if x.negative? || x >= @width || y.negative? || y >= @height

    @pixels[y][x] = c
  end

  def rect(x, y, w, h, c)
    h.times { |dy| w.times { |dx| set(x + dx, y + dy, c) } }
  end

  def hline(x, y, w, c) = rect(x, y, w, 1, c)
  def vline(x, y, h, c) = rect(x, y, 1, h, c)

  # 1px outlined filled box.
  def boxed(x, y, w, h, fill, outline)
    rect(x, y, w, h, fill)
    hline(x, y, w, outline)
    hline(x, y + h - 1, w, outline)
    vline(x, y, h, outline)
    vline(x + w - 1, y, h, outline)
  end

  # Bayer-style 50% dither between two colors over a rect.
  def dither(x, y, w, h, a, b)
    h.times do |dy|
      w.times do |dx|
        set(x + dx, y + dy, ((dx + dy).even? ? a : b))
      end
    end
  end

  def circle(cx, cy, r, c)
    (-r..r).each do |dy|
      (-r..r).each do |dx|
        set(cx + dx, cy + dy, c) if (dx * dx) + (dy * dy) <= (r * r)
      end
    end
  end

  def ring(cx, cy, r, thickness, c)
    inner_sq = (r - thickness)**2
    outer_sq = r * r
    (-r..r).each do |dy|
      (-r..r).each do |dx|
        d = (dx * dx) + (dy * dy)
        set(cx + dx, cy + dy, c) if d <= outer_sq && d > inner_sq
      end
    end
  end

  # Paint from an ASCII grid using a color map (char → palette idx, "." = skip).
  def paste(x, y, grid, map)
    grid.lines.each_with_index do |line, dy|
      line.chomp.chars.each_with_index do |ch, dx|
        next if ch == "."

        c = map[ch] or next
        set(x + dx, y + dy, c)
      end
    end
  end
end

canvas = Canvas.new(WIDTH, HEIGHT)

# === Wall (top 2/3) ===========================================================
# Base color, then a brick pattern using dithered mortar lines.
canvas.rect(0, 0, WIDTH, 160, 2)

# Mortar lines (horizontal, every 16px). Dithered for soft transition.
(0..160).step(16) do |y|
  WIDTH.times { |x| canvas.set(x, y, ((x + y) % 4 < 2 ? 1 : 3)) }
end

# Vertical mortar, brick-offset every other row.
(0..160).step(16) do |y|
  offset = (y / 16).even? ? 0 : 32
  ((offset)..WIDTH).step(64) { |x| canvas.vline(x, y + 1, 14, 1) }
end

# Cornice highlight at top of wall.
canvas.rect(0, 0, WIDTH, 6, 1)
canvas.hline(0, 6, WIDTH, 4)
canvas.hline(0, 7, WIDTH, 3)

# Tech specks / pinpoints scattered on the wall (deterministic).
srand(1989)
40.times do
  x = rand(WIDTH)
  y = rand(150)
  canvas.set(x, y, ((rand < 0.5) ? 4 : 10))
end

# === Portal (left wall) =======================================================
# Outer magenta glow → cyan ring → bright core, with dithered transition bands.
canvas.circle(56, 80, 28, 15)
canvas.ring(56, 80, 26, 2, 0)               # outer dark separator
canvas.circle(56, 80, 22, 13)
canvas.ring(56, 80, 22, 3, 0)
# Dithered band between dark cyan and light cyan
(-18..18).each do |dy|
  (-18..18).each do |dx|
    d = (dx * dx) + (dy * dy)
    next unless d <= 18 * 18 && d > 12 * 12

    canvas.set(56 + dx, 80 + dy, ((dx + dy).even? ? 13 : 14))
  end
end
canvas.circle(56, 80, 12, 14)
canvas.ring(56, 80, 12, 2, 0)
canvas.circle(56, 80, 6, 10)
# Swirl: a few magenta flecks pulled around the core
[[44, 64], [68, 64], [42, 96], [70, 96], [52, 58], [60, 102]].each do |x, y|
  canvas.set(x, y, 15)
  canvas.set(x + 1, y, 15)
end

# === Monitor (right wall) =====================================================
canvas.boxed(208, 40, 88, 64, 8, 0)         # outer bezel
canvas.boxed(212, 44, 80, 56, 9, 0)         # inner bezel
canvas.rect(216, 48, 72, 48, 0)             # black screen well
canvas.rect(218, 50, 68, 44, 11)            # screen dark green
# CRT scanlines
(50..94).step(2) { |y| canvas.hline(218, y, 68, 11) }
(50..94).step(4) { |y| canvas.hline(218, y, 68, 12) }
# Fake "404" text on screen
canvas.paste(232, 64, <<~G, "X" => 10)
  X.X..X..XX.X.
  X.X.XX.X..X.X
  XXX..X.X..X.X
  ..X..X.X..X.X
  ..X.XXX.XX.X.
G
# Status LEDs on bezel
[[218, 100, 15], [228, 100, 12], [238, 100, 10]].each do |x, y, c|
  canvas.rect(x, y, 4, 2, c)
  canvas.set(x, y, 0)
  canvas.set(x + 3, y, 0)
end
# Stand
canvas.boxed(244, 104, 24, 4, 8, 0)
canvas.boxed(234, 108, 44, 4, 8, 0)

# === Shelf ===================================================================
# Brackets (metal triangles)
[[36, 124], [WIDTH - 44, 124]].each do |bx, by|
  canvas.boxed(bx, by, 8, 12, 8, 0)
  canvas.set(bx + 1, by + 1, 10) # speck highlight
end
# Wood plank with grain lines
canvas.rect(32, 124, WIDTH - 64, 6, 7)
canvas.hline(32, 124, WIDTH - 64, 0)
canvas.hline(32, 129, WIDTH - 64, 5)
# Grain (light brown pixels)
(36..(WIDTH - 36)).step(7) { |x| canvas.set(x, 126, 6) }
(40..(WIDTH - 36)).step(11) { |x| canvas.set(x, 127, 6) }

# === Flasks on the shelf ======================================================
# Hand-drawn flask. K=outline, L=liquid color, H=highlight, l=liquid shadow.
# 16 wide × 22 tall: tall neck + bulbous bottom.
flask_grid = <<~G
  ....KKKK....
  ....K..K....
  ....K..K....
  ....K..K....
  ....K..K....
  ....K..K....
  ...KK..KK...
  ..KK....KK..
  .KK......KK.
  KK........KK
  K..........K
  K.HllllllllK
  K.LLLLLLLLLK
  K.LLLLLLLLLK
  K.LLLLLLLLLK
  K.LLLLLLLLLK
  K.LLLLLLLLLK
  K..LLLLLLL.K
  KK.LLLLLL.KK
  .KKllllllKK.
  ..KKKKKKKK..
G

# 4 flasks, varying liquid + neck cap colors.
[[80, [12, 11]], [136, [14, 13]], [192, [15, 13]], [248, [12, 11]]].each do |cx, (light, dark)|
  canvas.paste(cx - 6, 102, flask_grid,
               "K" => 0, "." => nil, "H" => 10, "L" => light, "l" => dark)
end

# === Counter ==================================================================
# Front lip (light brown top), main face (mid brown) with planks.
canvas.rect(0, 160, WIDTH, 4, 7)
canvas.hline(0, 160, WIDTH, 0)
canvas.rect(0, 164, WIDTH, 20, 6)
# Plank seams
(64..WIDTH).step(64) { |x| canvas.vline(x, 164, 20, 5) }
# Wood grain (subtle dark + light flecks)
(0..WIDTH).step(11) { |x| canvas.set(x, 170, 5) }
(0..WIDTH).step(13) { |x| canvas.set(x + 4, 176, 7) }

# === Floor ====================================================================
canvas.rect(0, 184, WIDTH, HEIGHT - 184, 5)
canvas.hline(0, 184, WIDTH, 0)

# Big tiles: 64 wide × 16 tall, mortar 2px wide.
(0..WIDTH).step(64) do |x|
  canvas.rect(x, 188, 2, HEIGHT - 188, 8)
end
canvas.rect(0, 196, WIDTH, 2, 8)
canvas.rect(0, 212, WIDTH, 2, 8)

# Subtle floor highlights (top edge of each tile, 1px lighter brown)
(0..WIDTH).step(64) do |x|
  canvas.hline(x + 2, 188, 60, 6)
  canvas.hline(x + 2, 198, 60, 6)
  canvas.hline(x + 2, 214, 60, 6)
end

# === Door frame (back wall, far right) ========================================
canvas.boxed(WIDTH - 60, 56, 36, 72, 0, 8)
canvas.rect(WIDTH - 56, 60, 28, 64, 1)
# Door panel highlights (lighter purple wash)
canvas.dither(WIDTH - 54, 62, 24, 4, 1, 2)
canvas.dither(WIDTH - 54, 116, 24, 4, 1, 2)
canvas.rect(WIDTH - 36, 92, 3, 4, 10) # handle

# === Encode PNG ==============================================================
raw = String.new(encoding: "BINARY")
HEIGHT.times do |y|
  raw << "\x00"
  WIDTH.times { |x| raw << canvas.pixels[y][x].chr }
end

def chunk(type, data)
  type_bytes = type.b
  crc = Zlib.crc32(type_bytes + data)
  [data.bytesize].pack("N") + type_bytes + data + [crc].pack("N")
end

ihdr = [WIDTH, HEIGHT].pack("N2") + [8, 3, 0, 0, 0].pack("C5")
plte = PALETTE.flatten.pack("C*")
idat = Zlib::Deflate.deflate(raw)

png = String.new("\x89PNG\r\n\x1a\n", encoding: "BINARY")
png << chunk("IHDR", ihdr)
png << chunk("PLTE", plte)
png << chunk("IDAT", idat)
png << chunk("IEND", "".b)

target = ARGV[0] || File.expand_path("../lib/gemnesis/templates/hello_world/res/lab_bg.png", __dir__)
FileUtils.mkdir_p(File.dirname(target))
File.binwrite(target, png)
puts "Wrote #{png.bytesize} bytes to #{target}"
