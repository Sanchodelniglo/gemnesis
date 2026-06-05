#!/usr/bin/env ruby
# frozen_string_literal: true

# Regenerates the placeholder hero sprite PNG bundled with the hello_world template.
# Pure Ruby + Zlib (no image-lib dependency). 16x16, indexed-color, SGDK-friendly.

require "zlib"

WIDTH = 16
HEIGHT = 16

# 16-color palette (max for SGDK sprites). RGB triples.
palette = [
  [0,     0, 0], # 0: transparent
  [40, 24, 16], # 1: outline (near-black)
  [240, 200, 160], # 2: skin
  [200, 50, 50], # 3: shirt red
  [255, 255, 255], # 4: eye white
  [0, 0, 0], # 5: pupil
  [80, 48, 32] # 6: hair / shadow
].concat(Array.new(9) { [0, 0, 0] }) # pad to 16

# Pixel grid — `.` = transparent, digits = palette index.
grid = <<~PIXELS
  ................
  ....6666666.....
  ...666666666....
  ..16222222261...
  ..16222222261...
  ..162455425221..
  ..162455425221..
  ..162222222221..
  ..162222222221..
  ...1622222221...
  ....11111111....
  ...3333333333...
  ..333333333333..
  ..333333333333..
  ..133333333331..
  ...11......11...
PIXELS

pixels = []
grid.lines.first(HEIGHT).each do |line|
  chars = line.chomp.chars
  WIDTH.times { |x| pixels << ((chars[x] || ".") == "." ? 0 : chars[x].to_i) }
end

# Build raw IDAT stream: filter byte (0=None) + pixel bytes per row.
raw = String.new(encoding: "BINARY")
HEIGHT.times do |y|
  raw << "\x00"
  WIDTH.times { |x| raw << pixels[(y * WIDTH) + x].chr }
end

def chunk(type, data)
  type_bytes = type.b
  crc = Zlib.crc32(type_bytes + data)
  [data.bytesize].pack("N") + type_bytes + data + [crc].pack("N")
end

ihdr = [WIDTH, HEIGHT].pack("N2") + [8, 3, 0, 0, 0].pack("C5")
plte = palette.flatten.pack("C*")
trns = "\x00".b # alpha=0 for palette index 0
idat = Zlib::Deflate.deflate(raw)

png = String.new("\x89PNG\r\n\x1a\n", encoding: "BINARY")
png << chunk("IHDR", ihdr)
png << chunk("PLTE", plte)
png << chunk("tRNS", trns)
png << chunk("IDAT", idat)
png << chunk("IEND", "".b)

target = ARGV[0] || File.expand_path("../lib/gemnesis/templates/hello_world/res/hero.png", __dir__)
require "fileutils"
FileUtils.mkdir_p(File.dirname(target))
File.binwrite(target, png)
puts "Wrote #{png.bytesize} bytes to #{target}"
