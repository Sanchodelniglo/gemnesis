# gemnesis

> **pre-alpha — API will change**

Make Sega Mega Drive / Genesis games using Ruby tooling.

```bash
gem install gemnesis
gemnesis new my_game
cd my_game
gemnesis run
```

Four commands, ~30 seconds, and a playable ROM with a hero sprite you can move
with the D-pad is running in your emulator.

## Why?

The Mega Drive (1989) is dead silicon — you can't `bundle add genesis-sdk`. To
build a homebrew ROM today you have to wrestle a C cross-compiler, a Japanese
SDK called SGDK, a Makefile system, and a half-dozen Java JARs. Most people
give up at step two.

gemnesis hides all of it. You write a Ruby config + (for now) some C, and the
gem handles the rest.

## What it does

- **`gemnesis new NAME`** drops a hello-world template: 1 C file, 1 sprite PNG,
  1 Ruby config (`gemnesis.rb`).
- **`gemnesis build`** spins SGDK in Docker, cross-compiles to m68k assembly,
  packs assets, produces a real cartridge image (`out/rom.bin`) you could burn
  to a Flash cart and play on actual hardware.
- **`gemnesis run`** builds, then opens the ROM in RetroArch (Genesis Plus GX
  core) or BlastEm — whichever you have installed.
- **`gemnesis doctor`** checks your environment in one shot.
- **`gemnesis clean`** removes build artifacts.

## Who it's for

Ruby devs who always wanted to ship a Mega Drive game but never wanted to learn
a C build system. Hobbyists. Retro enthusiasts. Anyone who'd rather write
`g.title = "My Game"` than fight a 1000-line Makefile.

## What it isn't (yet)

A Ruby-to-C transpiler. You still write game logic in C — gemnesis just makes
everything around it disappear. A real DSL is planned post-0.1.

## Requirements

- macOS, Apple Silicon (Intel + Linux deferred)
- [Docker](https://orbstack.dev) running (OrbStack recommended, Docker Desktop
  tolerated)
- An emulator: [RetroArch](https://www.retroarch.com/) with the Genesis Plus GX
  core (`brew install --cask retroarch`, then download the core from RetroArch's
  Core Downloader), or BlastEm if you can find an arm64 build.
- Ruby 3.4+ (managed via mise, rbenv, or asdf — `.ruby-version` is set)

> **Note:** the SGDK Docker image is x86-only. On Apple Silicon it runs under
> Rosetta — builds are a few seconds slower than native, no other downside.

## Configure your game

`gemnesis.rb` lives at the project root:

```ruby
Gemnesis.configure do |g|
  g.title  = "My Game"   # ≤48 ASCII chars, becomes the ROM header
  g.region = :ntsc       # :ntsc | :pal | :both
  g.author = "You"       # becomes the copyright string
end
```

These values land in the cartridge header — see `out/rom.bin`'s `file` output
or [`docs/rom-header.md`](./docs/rom-header.md) for details.

## Roadmap

A 10-lesson curriculum that teaches Mega Drive hardware (palettes, sprites,
scrolling, sound, DMA) one ROM at a time. Pair with `/mentor` mode for live
tutoring while you write each lesson.

See [`.claude/plans/`](./.claude/plans/) for the working plans:

- `PLAN-ENV.md` — environment + toolchain contract
- `PLAN-MVP.md` — 0.1.0 scope (essentially what's running today)
- `PLAN-LESSONS.md` — the curriculum

## Contributing

Issues + PRs welcome once 0.1.0 ships. For now, expect breaking changes
between commits.

## License

MIT — see [LICENSE.txt](./LICENSE.txt).
