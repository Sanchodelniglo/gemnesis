# gemnesis project config. Parsed at build time → src/config.h + rom_head.c.
Gemnesis.configure do |g|
  g.title  = "{{TITLE}}"   # ROM header title (<= 48 chars, ASCII)
  g.region = :{{REGION}}   # :ntsc | :pal | :both
  g.author = "{{AUTHOR}}"
end
