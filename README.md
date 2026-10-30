# belt-quest

A factory-RPG hybrid for **WildForge**, ported from the game at
`dev/belts/` (working title "belts"). belt-quest is a **pure data + script
mod** — no WildForge engine code lives here; every engine capability it
needs is being pushed upstream into WildForge first as a generic feature.

See **[docs/port-plan.md](docs/port-plan.md)** for the full port plan.

## Status

Milestone B slice + Milestone C waves landed (factory core, modular
gear, combat breadth, Haven + outposts, dungeon set, skill tree,
economy, alien + Chronarch arcs). See docs/port-plan.md for the
per-wave record and docs/playtest-guide.md for the walkthrough.

Wildforge's maintainability refactor (PR #88) and the follow-up update
(October 2026: streaming, lighting, rendering, hydrology, multiplayer
security, identity) needed no content changes; evidence in
docs/refactor-verification.md.

## Layout

```
mods/belt_quest/   the mod: mod.toml + content TOML + main.rhai
                   (textures alias base tiles; no binary art yet)
docs/              port plan + verification records
src/tools/         helper scripts (repo-local content lint)
```

## Requirements

- WildForge checkout at or after the October 2026 update (HEAD
  `c3489c7`) with the belt-quest capabilities (E0–E15) landed — see the
  plan's Milestones A–C.
- `wildforge --mod-qualification mods` PASS with this mod installed,
  plus the WildForge playtest + registry suites green (see
  docs/refactor-verification.md). `src/tools/lint.py` runs the
  repo-local static checks.
