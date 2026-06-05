# gemnesis project config. Parsed at build time → src/config.h.
Gemnesis.configure do |g|
  g.title  = "{{NAME}}"   # ROM header title (<= 48 chars, ASCII)
  g.region = :ntsc        # :ntsc | :pal | :both
  g.author = "You"
end
