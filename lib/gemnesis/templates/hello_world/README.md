# {{NAME}}

A Sega Mega Drive / Genesis ROM, scaffolded by [`gemnesis`](https://github.com/sanchodelniglo/gemnesis).

## Build & play

```bash
gemnesis build      # builds → out/rom.bin
open out/rom.bin    # opens in your registered Mega Drive emulator
gemnesis doctor     # if anything goes wrong, run this first
```

## What this does

Boots, prints `GEMNESIS` near the top of the screen, and shows a 16x16 hero
sprite at center. Move with the D-pad. That's it — proof your toolchain works.

## Files

- `gemnesis.rb` — Ruby config (ROM title, region, author)
- `src/main.c` — game code (~30 lines, commented)
- `res/resources.res` — sprite/tile manifest for SGDK's resource compiler
- `res/hero.png` — placeholder hero (16x16, 16-color indexed)
- `Makefile` — one-line include of SGDK's standard makefile

## What's next

Edit `src/main.c` to draw your own sprites, scroll a background, or read more
inputs. See SGDK docs: https://github.com/Stephane-D/SGDK/wiki
