# ROM header

Every Mega Drive ROM starts with a fixed 256-byte header at offset `0x100`.
The console doesn't read most of it — it's metadata for cart labels, region
locking on later models, and SRAM declaration. But it's what shows up when
you inspect a `.bin` file:

```text
$ file out/rom.bin
out/rom.bin: Sega Mega Drive / Genesis ROM image: "MY GAME         " (GM 00000000-00, (C)YOU 2026   )
```

## What gemnesis writes

On every `gemnesis build`, the gem generates `src/boot/rom_head.c` from
`gemnesis.rb`. SGDK's `makefile.gen` declares `src/boot/rom_head.c` as an
**order-only** prerequisite — if the file exists, SGDK uses it as-is and
skips its default. So overwriting it on each build is safe and gives us a
ROM header that reflects the user's config.

Fields driven from `gemnesis.rb`:

| `gemnesis.rb` field | ROM header field | Notes |
|---|---|---|
| `g.title`  | domestic + international title | Padded to 48 chars |
| `g.author` | copyright string               | `(C)<author>` truncated/padded to 16 |
| `g.region` | region code (last 16 bytes)    | `:ntsc` → `U`, `:pal` → `E`, `:both` → `JUE` |

Other header fields keep SGDK's defaults — system identifier, serial,
device support (`JD` = pad + 6-button), ROM/RAM bounds, SRAM signature,
notes. They're not part of the gem's surface yet.

## Overriding manually

If you need full control of the header (custom serial, SRAM enabled, etc.),
write your own `src/boot/rom_head.c` and gemnesis will **not** overwrite it.

> **Heads up:** gemnesis currently overwrites `src/boot/rom_head.c` on every
> build to keep it in sync with `gemnesis.rb`. To opt out today, comment-out
> the `write_rom_header` call in the builder (or use `--no-header` once
> that flag lands — see [PLAN-MVP](../.claude/plans/PLAN-MVP.md) follow-ups).

## Inspecting the ROM

After a build:

```bash
$ file out/rom.bin                               # quick summary
$ xxd -s 0x100 -l 256 out/rom.bin                # raw header dump
$ hexdump -C -s 0x120 -n 48 out/rom.bin          # domestic title
```

The Mega Drive itself reads only the region byte (`0x1F0`) on later TMSS
models — everything else is for humans and tooling.
