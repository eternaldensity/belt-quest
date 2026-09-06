# Wildforge refactor verification (2026-09-06)

Wildforge landed the maintainability refactor as PR #88 (merge
`16420b50`, HEAD `6383f2c6` at verification time). This note records
that belt-quest needed no content changes for it.

## What the refactor was

Structural only, per `.design/maintainability-refactor.md`:

- `src/registry.rs` (~7k lines) split into `src/registry/` modules
  (schema, linking, loading, reading, runtime, …) with re-exports.
- World/client/session/renderer given explicit owners and narrow
  dependency contracts.
- New advisory tooling (`tools/maintainability/`,
  `check_architecture.py`, `check_folder_guides.py`).

Preserved, by design and by check below:

- TOML schemas and defaults, `world_api = 2`, schema versions `1`.
- Rhai host API (same 17 functions; `World` → `WorldView` internally,
  guest mutations now explicitly rejected with a log).
- `PROTOCOL = 46`, save codecs, content identities, tick order.

## Evidence (rebuilt from Wildforge HEAD, belt-quest HEAD `0f09088`)

Run from a Wildforge checkout with this repo's `mods/belt_quest`
installed at `mods/belt_quest` (byte-identical, `diff -r` clean;
matches `tools/install_test_mods.py` pin `0f09088`):

```sh
cargo check --locked                    # clean (14.98 s incremental)
cargo build --locked                    # clean (6 m 48 s)
./target/debug/wildforge.exe --mod-qualification mods
# mods: mods / failures: none / qualification status: PASS
cargo test --locked tests::playtest::    # 6 passed, 0 failed (87.19 s)
cargo test --locked tests::registry_tests::  # 51 passed, 0 failed
python3 tools/check_maintainability.py   # advisory only, no gate
python3 -m unittest discover -s tools/tests -v  # 53 tests OK
```

The pre-existing debug binary (2026-08-26) predates the refactor, so
it was rebuilt before qualifying; do not trust a stale
`target/debug/wildforge.exe` for this check.

## Result

No `mods/belt_quest/` data or `main.rhai` changes required.
Remaining work in this repo is hygiene only: stale status docs and
the long-promised `src/tools/` lint (tracked separately).
