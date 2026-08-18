# belt-quest

A factory-RPG hybrid for **WildForge**, ported from the game at
`dev/belts/` (working title "belts"). belt-quest is a **pure data + script
mod** — no WildForge engine code lives here; every engine capability it
needs is being pushed upstream into WildForge first as a generic feature.

See **[docs/port-plan.md](docs/port-plan.md)** for the full port plan.

## Status

Planning. Milestone A (upstream capability ramp) is the active track:
WildForge is gaining a mod test harness (E0), a ruleset/mode system (E1),
and a third-person camera (E2) first.

## Layout

```
mods/belt_quest/   the mod: mod.toml + content TOML + main.rhai + textures/
docs/              port plan + owned task briefs
src/tools/         helper scripts (content lint, schema checks)
```

## Requirements

- WildForge checkout with the belt-quest capabilities landed (see the
  plan's Milestone A).
- `cargo test --lib` + clippy `-D warnings` clean, run via the E0 test
  harness once it exists.
