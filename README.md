# gemnesis

> **pre-alpha — API will change**

Scaffold, build, and run Sega Mega Drive / Genesis homebrew ROMs from a Ruby CLI.

## Why?

Megadrive homebrew today means wrangling SGDK, Makefiles, and a C toolchain by hand. `gemnesis` wraps that toolchain in Docker and gives you a Ruby-flavored project layout — `gem install`, `gemnesis new my_game`, `gemnesis run`, and you're playing your ROM in BlastEm.

## Quickstart

```bash
gem install gemnesis
gemnesis new my_game
cd my_game
gemnesis run
```

## Requirements

- macOS, Apple Silicon
- [Docker](https://orbstack.dev) (OrbStack recommended) running
- [BlastEm](https://www.retrodev.com/blastem/) — `brew install blastem`
- Ruby 3.4+

> **Apple Silicon note:** the SGDK Docker image may run under Rosetta. First build pulls the image automatically; expect slower compiles than native arm64.

## What this is

- A thin Ruby CLI around SGDK
- A scaffolder that gives you a runnable "hello world" ROM with text + a D-pad-moveable sprite
- A learning track ([lessons/](./lessons/) — coming post-0.1.0) covering palettes → sprites → scrolling → audio → DMA

## What this isn't (yet)

- A Ruby → C transpiler (planned)
- A WASM live-reload server (planned)
- A sound/music DSL (planned)
- Cross-platform (Mac-only for now)

## Roadmap

See [`.claude/plans/`](./.claude/plans/) for active plans:

- `PLAN-ENV.md` — environment + toolchain
- `PLAN-MVP.md` — 0.1.0 scope
- `PLAN-LESSONS.md` — Megadrive curriculum

## Contributing

Issues + PRs welcome once 0.1.0 ships. For now, expect breaking changes between commits.

## License

MIT — see [LICENSE.txt](./LICENSE.txt).
