# Changelog

All notable changes to this project are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `gemnesis new NAME` — scaffolds a hello-world ROM project from a built-in
  template (Ruby config + SGDK C source + 16x16 hero sprite + Makefile).
- `gemnesis doctor` — environment check: Ruby ≥ 3.4, Docker on PATH and
  reachable, SGDK image pulled, BlastEm available. ✓/✗/⚠ table output.
- `gemnesis build` — parses `gemnesis.rb`, writes `src/config.h`, invokes
  SGDK image via Docker (`docker run --rm -v $PWD:/src … make`), reports
  `out/rom.bin` size. Auto-pulls image on first run.
- `gemnesis run` — builds then launches BlastEm; falls back gracefully with
  a brew install hint if BlastEm isn't on PATH.
- `gemnesis clean` — removes `out/`, `src/config.h`, generated resource
  files, and `.o/.elf/.lst/.map` artifacts. Idempotent.
- `gemnesis version` — prints gem version.
- Ruby config DSL (`Gemnesis.configure { |g| ... }`) with validation for
  title (≤48 ASCII chars), region (`:ntsc`/`:pal`/`:both`), author.
- `GEMNESIS_SGDK_IMAGE` env var to override the pinned SGDK image tag.
- Apple Silicon arch detection — warns on Rosetta fallback.
- All shell-outs use `Open3` array form — no injection via env vars or paths.
- GitHub Actions CI: lint + unit specs on every push; real-Docker
  integration build gated on main pushes via `GEMNESIS_INTEGRATION=1`.
- `.github/` issue + PR templates.

### Security
- `gemnesis.rb` is loaded via `Kernel.load` — the trust model matches a
  `Makefile`/`Rakefile`: it runs Ruby in the user's own project, treated
  as user-owned code. Documented in source comments.

## [0.1.0] - TBD

Initial public release. See [PLAN-MVP](./.claude/plans/PLAN-MVP.md) for scope.
