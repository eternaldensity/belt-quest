# Wildforge compatibility verification

Two checks are recorded here: the maintainability refactor (2026-09-06)
and the follow-up engine update (2026-10-30). Both needed **no
`mods/belt_quest/` content changes**.

# 1. Post-refactor update verification (2026-10-30)

WildForge advanced from `6383f2c6` (PR #88 merge) through `c3489c7`.
The seven intervening commits are engine runtime and presentation work,
recorded in Wildforge's `.design/maintainability-progress.md`:

- multiplayer authority checks, TLS certificate verification, and DNS
  resolver hardening (`d8fafc6`, `1b50883`);
- terrain streaming and shoreline reconciliation performance
  (`d8fafc6`);
- raycast resident-chunk reuse and terrain-light cache reuse
  (`.design/maintainability-progress.md` §2026-10-09);
- frame/GPU profiling and the render-work capture protocol
  (`eeaa31b`, `9c4d917`, `c3489c7`);
- renderer point-light shadow skipping (`2abb4cb`).

None of these changed the mod contract: TOML schemas and defaults,
`world_api = 2`, schema versions, the Rhai host function set, `PROTOCOL`
(46), save codecs (`entities.toml` version 11), content identities, or
assembly/quest/registry semantics. The mod therefore remains
byte-compatible; see the content-pin note below.

## What was exercised

The tested artifact is a fresh `target/debug/wildforge.exe` built from
WildForge `c3489c7` (2026-10-30, `cargo build --locked`, 5 m 19 s;
SHA-256 `427b0610bb784cd6feff418dba75bf9544a4c10c91a7de58bb0b3cec0855d6fd`).
The belt-quest content under test is this repo's `mods/belt_quest`
(content tree at verification; later doc-only commits do not change it). It is byte-identical to
Wildforge's installed `mods/belt_quest` (`diff -rq` clean) and to the
published pin `0f09088` (`git diff 0f09088..HEAD -- mods/` is empty;
later documentation/tooling commits do not touch that tree).

```sh
# from the WildForge checkout
./target/debug/wildforge.exe --mod-qualification mods          # PASS
./target/debug/wildforge.exe --mod-qualification ../belt-quest/mods  # PASS
cargo test --locked tests::playtest::                          # 6 passed
cargo test --locked tests::registry                            # 53 passed
cargo test --locked --lib -- --skip tests::agent::             # see note
```

From this repo:

```sh
python3 src/tools/lint.py                                      # PASS
```

The qualification run directly against `../belt-quest/mods` is the
important one: it proves the repo content itself, not a stale installed
copy, loads and passes the engine's material/texture/obtainability/script
battery. The playtest suite drives the real shipped mods tree through
the real world sim (Haven stamp and NPCs, quest callbacks, conduit
sequence, depot appetite, Brood Gallery spawning, Custodian thresholds).

Generated exploration: all 256 four-press valve orders were dispatched
through the real Rhai `on_screen_click` hook against a fresh script host.
Exactly one order — `d,a,c,b` — completed `mines_conduits`; every other
order produced no quest progress. This drove the same script and command
queue as the shipped screen, not a copy of the valve logic.

## Results

| Check | Result |
|---|---|
| `--mod-qualification mods` | PASS, no failures |
| `--mod-qualification ../belt-quest/mods` | PASS, no failures |
| `cargo test --locked tests::playtest::` | 6 passed, 0 failed (12.02 s) |
| `cargo test --locked tests::registry` | 53 passed, 0 failed (1.74 s) |
| `python3 src/tools/lint.py` | PASS |
| Full lib suite (parallel, 1st run) | 1220 passed, 1 failed, 25 ignored (95.27 s) |
| Full lib suite (parallel, 2nd run) | 1221 passed, 0 failed, 25 ignored (129.16 s) |

The one first-run failure was
`tests::machines::furnace::charged_furnace_fuel_and_inputs_leave_no_orphan_current`
(`left: 256`, `right: 512`, "ember fuel disorders its exact charge").
It uses `base_reg()` (base content only; `belt_quest` is not loaded),
passed on the second parallel run, and passed 10/10 times when run alone
with `--exact` (0.34–0.43 s). It is an engine test-isolation flake in the
updated WildForge tree, not a belt-quest content failure.

### Client / GPU evidence: partially verified via lavapipe

Following the approach used by `cardshop-cleanup` (accept lavapipe CPU
adapters instead of refusing them, render into an offscreen capture
texture), the Wildforge adapter chooser was temporarily patched to keep
CPU adapters (a one-line change, reverted afterwards). A 1280×720 frame
was then captured under `xvfb-run` with `WGPU_BACKEND=vulkan`:

- Screenshot: `/tmp/opencode/menu-mods.ppm` (2,764,800 bytes, valid P6)
- 37 distinct colours, dominant share 48.9% — a healthy rendered frame,
  not a blank fill.
- The mods screen was shown (`WILDFORGE_SCREEN=mods`), which lists every
  installed mod including `belt_quest`.

The stock Wildforge binary cannot do this on its own: its adapter chooser
filters out CPU devices, so under WSL only the Windows/DX12 binary is
available, and that hangs at `request_device` under WSL interop. The
graphical path is therefore verified only through this temporary
lavapipe experiment, not through the shipped binary. The engine's own
playtest suite (6/6) and headless world sim remain the authoritative
content check.

## Content pin

Wildforge's CI installs the published mod at
`tools/install_test_mods.py` pin `0f09088`. The `mods/belt_quest/` tree
is byte-identical at that pin and at this repo's verification commit;
later documentation and `src/tools/lint.py` changes do not touch it, so
the pin remains valid and does not need to move for a docs/tooling-only
update.

# 2. Maintainability refactor verification (2026-09-06)

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
