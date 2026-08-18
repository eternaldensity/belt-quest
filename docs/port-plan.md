# belt-quest — Port Plan

Port the game at `dev/belts/` (working title "belts", a Bevy factory-RPG
through RPG Phase 8) into WildForge as a **pure data + script mod**, under
the name **belt-quest**.

This document is the plan for that port. It assumes the reader knows both
codebases; key facts are summarized where decisions depend on them.

---

## 0. Decisions locked (2026-08-18)

1. **Pure mod, engine-first.** `belt-quest` is only TOML data + Rhai
   scripts. Every engine capability it needs must first land in WildForge
   as a *generic* capability. No WildForge fork; no engine code in this
   repo.
2. **First milestone = the upstream capability backlog.** Build the
   generic WildForge engine extensions (Part 2 below) before writing any
   belt-quest content, because nearly all belt-quest content is meaningless
   without them (a skill tree mod without a skill-tree engine, a modular
   equipment mod without equipment frames, a dungeon mod without zones).
3. **Third-person, faithfully.** Add an over-shoulder third-person camera
   (no wall-clipping) + stamina-gated combat (combos, dodge i-frames,
   block, backstab) to the engine and port belts' combat near-verbatim.
   This is the most expensive engine item and the least negotiable from
   belts' design.
4. **Plan lives here.** `docs/port-plan.md` (this file). Task briefs for
   individual upstream capabilities will go into WildForge's
   `docs/extension-plans/` as they are scheduled.

---

## 1. Vision & ethos

### 1.1 What belt-quest is

belts' central claim — quoted from `rpg-plan/00-vision.md`:

> "This is not 'Factorio with a character' or 'Skyrim with conveyor belts.'
> Both halves are load-bearing."

belt-quest keeps that claim. It is a factory-RPG hybrid: a third-person
action RPG where the factory is the crafting system, the settlement
network is the quest infrastructure, and dungeons are destination content
that hands materials back to the factory.

### 1.2 The five pillars, mapped onto WildForge

| belts pillar | WildForge vehicle |
|---|---|
| Build to Explore, Explore to Build | Factory (belts/rails/multiblock machines) → gear → dungeons → components → better factory. WildForge's rails/local-structures/belt layer is the factory core. |
| Modular Over Disposable | **New engine capability E6** (frames + slot components, reconfiguration-not-replacement). |
| Dungeons as Destination Content | **New engine capability E10** (instanced dungeon zones). Hand-authored templates + procedural assembly. |
| Factory as Power Projection | WildForge rails + LocalStructures + outposts; supply lines via belts/rail. Already present; needs E8 belt-geometry depth. |
| Living World, Not Treadmill | A **ruleset** (E1) that removes the punishing survival meters; ecology that rewards tending without demanding it. |

### 1.3 What it explicitly is NOT (mod-out list)

belts' negative space drives which WildForge systems get disabled or
repurposed:

| belts says | WildForge system today | Disposition |
|---|---|---|
| No punishing hunger/thirst | Food survival loop (`world/soil.rs`, belly/hunger) | **Mod out** via ruleset (E1): hunger off. Keep food as items/consumables for buffs, not survival. |
| Ire is an industrial-response gradient, not a moral ledger | Ire = moral meter (extraction/kill raises it) | **Repurpose** (E12): factory output feeds ire instead of extraction. This *is* WildForge spec 3.7. |
| No tower defense core | (no such loop) | n/a — turrets are logistics-integrated, situational. |
| Not a looter-shooter | Loot tables are weighted random | Keep tables for materials; **guaranteed drops** for boss components via quest/flag-gated rewards. |
| No survival-grind treadmill | Tech-gate-only progression | Keep tech gates; **add** skill tree (E5). WildForge's "no skill trees" non-goal is explicitly overridden for belt-quest. |
| No fast-travel that bypasses logistics | Waystones/signs exist | Do not add fast-travel content; trains-on-rails stay the long-distance transport. Waystones remain as landmarks only. |

### 1.4 Tone

Grounded sci-fi / industrial frontier, optimistic, functional. Not grimdark.
This is content direction, not engine work — see Part 4 (mod content).

---

## 2. Upstream engine capability backlog (FIRST MILESTONE)

All of these are **generic WildForge capabilities** (usable by any mod),
not belt-quest-specific. Each is a WildForge feature branch with tests.
Ordered by dependency; lower numbers gate higher ones.

> **E0 — Mod test harness.** ✅ **LANDED** (WildForge `feat/capability-ramp`,
> `src/mod_lint.rs`). `wildforge --mod-qualification <mods_dir>` runs the
> shared qualification battery — mod load errors, material/arcane errors,
> missing textures, content-graph obtainability, and script compile — and
> exits non-zero on failure. The engine's own content-graph suite delegates
> to it. belt-quest CI installs the mod into a WildForge checkout's `mods/`
> tree and gates on `--mod-qualification` exit 0. Task brief:
> `docs/extension-plans/wildforge-task-brief-capability-e0-mod-harness.md`.

| ID | Capability | Scope | Gates |
|---|---|---|---|
| E1 | **Ruleset / game-mode system** | ✅ **LANDED** (WildForge `feat/capability-ramp`, `src/ruleset.rs`). Mods declare `[[mode]]` in `modes.toml` (base + 10 toggles: creative, hunger, fall_damage, drowning, lava_burn, hostile_spawns, ire, hearts, weather_extremes, pvp); `Registry::ruleset_for` / `World::ruleset` resolve the world's `mode` string; world + client gates wired. belt-quest ships `modes.toml` and creates worlds with its mode. Task brief: `docs/extension-plans/wildforge-task-brief-capability-e1-ruleset.md`. | everything (belt-quest ruleset) |
| E2 | **Third-person camera** | ✅ **LANDED** (WildForge `feat/capability-ramp`, `src/camera.rs`). Over-shoulder chase cam (wall push-out, mouse aim), Tab toggle to orbit "factory" cam (drag spins, scroll zooms 2–20), persists camera per world (`camera = "first"|"third"|"orbit"` in `world.toml`); local avatar body + held item in chase/orbit; multiplayer Tab stays the roster and guests keep first-person. Task brief: `docs/extension-plans/wildforge-task-brief-capability-e2-third-person-camera.md`. | combat depth, all combat content |
| E3 | **Player combat depth** | ✅ **LANDED** (WildForge `feat/capability-ramp`, `src/game/combat.rs`). Stamina (0–10) gates sprint/swing/heavy/dodge/block with exertion-delayed regen and a guard break; light/light/heavy combo (0.9 s window, heavy 2.5×); Alt dodge (11 blocks/s dash, 0.4 s i-frames, 0.8 s cooldown); F block (65% damage+knockback reduction, 45% guard walk, hold + per-hit drain); backstab 2× beyond 110° off the mob's facing; floating damage numbers; world-space health bars over damaged/hostile mobs (mob health rides snapshots, PROTOCOL 41); stamina HUD bar; E3 task brief `docs/extension-plans/wildforge-task-brief-capability-e3-combat-depth.md`. | E4 (stats feed stamina/hearts) |
| E4 | **Player stat surface** | ✅ **LANDED** (WildForge `feat/capability-ramp`, `src/stats.rs` + `src/game/stats.rs`). Generic modifier surface `StatKind`/`StatModifier`/`StatBlock`: `effective = (base + flat) × permille`; equipment (`ItemDef.stats` + `carry_weight`, `[[item.stats]]`) and consumable (`PreparationModifiers` gains health/stamina-regen/carry/reach/scan/move-speed channels) sources multiply into one block. Routed: `max_health`, stamina max/regen (combat HUD + tick), **carry weight** (512-unit capacity, survival pickup gate + burden meter), build range (`reach()` at every interaction raycast), scan range (arcane-ecology observation radius), move speed (`physics::Input.speed_mult`). Suite 943 passing, clippy + mod-qual clean, visual/geode hashes refreshed. Task brief: `docs/extension-plans/wildforge-task-brief-capability-e4-stat-surface.md`. | E5, E6 |
| E5 | **Skill tree system** | Data-driven trees (branches, nodes, point cost, tier gates), XP sources with diminishing returns, level cap, effects applied to E4. **Overrides the "no skill trees" non-goal.** | E4 |
| E6 | **Modular equipment** | Item model: frame + typed slots; components slot in/out intact; derived stats from loadout; durability to 0 but never destroyed (repairable); loadout presets. | E4 |
| E7 | **Data-driven machine kinds** | Open the closed `MachineKind` enum / `interaction` match so mods define new machines (Workbench, Armory, Tannery, Sensor Tower, Turret, Assembler…) with recipes + screens. | E0 (testability), E11 (screens) |
| E8 | **Belt geometry & persistence** | Curves, inclines, switches, splitters/mergers, orientable belts, and **persisted belt cargo** (currently transient runtime state). Extends `world/belt.rs` (its scoping comment already defers this). | E7 (machine feed), E10 (dungeon/lair feeds) |
| E9 | **Enemy AI archetype extension + nests** | New generic behavior archetypes (Rusher/Tank/Sniper/Support/Swarm/Controller/Phaser/Shield-Bearer) as data-driven `behavior` values; **nests/dens as spawn-gate blocks** (clearing stops respawns). | E3 (damage/backstab interaction) |
| E10 | **Instanced dungeon zones** | Separate-zone load/unload (overworld freezes on entry), room-graph generation from templates, checkpoints + dungeon respawn, loot tables, world-timer reset on exit. Sits on/alongside `pieces.toml` + `LocalStructure`. | E8 (feeds), E11 (HUD) |
| E11 | **Mod-extensible UI screens** | Allow mods to add screens: skill tree, equipment/loadout, dungeon HUD, factory HUD mode, quest board. `Screen` is currently a closed enum — needs a generic mod screen layer. | E5, E6, E7, E10 |
| E12 | **Industrial response gradient (ire repoint)** | Spec 3.7: factory output (buildings, machines, pollution-adjacent) feeds regional ire instead of / alongside extraction; tiers drive wildlife aggression gradient. | E1 |
| E13 | **Settlement depot logistics + economy** | Depot block with belt/rail ports feeding settlement needs; credits item + barter + market pricing hooks on top of the stall system. | E8, E11 |
| E14 | **Save/load completeness** | Persist belt cargo, dungeon progress, skill allocation, equipment loadouts, settlement depot state in the world save. | E5, E6, E8, E10, E13 |

### 2.1 Dependency ordering

```
E0 (test harness)
 └─ E1 (ruleset) ─ E2 (3rd-person cam) ─ E3 (combat depth) ─ E4 (stat surface)
                    E4 → E5 (skill tree), E6 (equipment)
       E7 (machine kinds) ─ E8 (belt geom/persist) ─ E10 (zones) ─ E13 (depot/economy)
       E9 (AI + nests)  needs E3
       E11 (screens) needs E5/E6/E7/E10 to be meaningful, but UI layer itself can
                      be built early and adopted by each
       E12 (ire) needs E1; independent of combat chain
       E14 (save) folds into each capability's own persistence work
```

Suggested WildForge branch sequence: **E0 → E1 → E2 → E3 → E4 → E5 →
E6 → E7 → E8 → E9 → E10 → E11 → E12 → E13**. E11 can be pulled forward
once E0..E4 exist, since the screens layer is standalone.

### 2.2 Each capability ships with

- Generic engine tests in WildForge (mirroring WildForge's existing
  `cargo test --lib` culture, clippy `-D warnings` clean).
- A data-only sample mod in WildForge proving the capability is reachable
  from mod-land without Rust.
- A `docs/extension-plans/` task brief in WildForge.

### 2.3 Scope guard

The capability backlog is deliberately the **whole** generic surface
belt-quest needs. Do not conflate "engine capability" with "belt-quest
content": none of E1–E14 ships belt-quest theme. belt-quest stays a pure
mod forever.

---

## 3. Mapping: belts system → WildForge system

Authoritative, current as of WildForge HEAD `30e1c42` / belts `f176fb7`.

| belts system (rpg-plan doc) | WildForge counterpart | Verdict |
|---|---|---|
| 01 Player character (stats, movement, cam) | physics.rs + input.rs; first-person | **Adapt**: first-person exists; third-person is E2; stats are E4; movement (sprint/jump) reused, dodge/climb/zipline deferred |
| 02 Modular equipment | items.toml (armor `{slot,points}`, durability) | **Build E6** — frames/slots/reconfiguration are new |
| 03 World & settlements | pieces.toml + settlements (rep reveal) + stall | **Reuse** pieces/settlements/rep; **build E13** (needs/supply depot + economy) |
| 04 Dungeons | pieces.toml assemblies + LocalStructure | **Build E10** (instanced zones) on top |
| 05 Combat | mobs.rs (attack wheels, resist, archetypes) | **Reuse** mob AI/damage classes; **build E3** (player-side depth) |
| 06 Skill tree | tech gates + learn_recipe (no skill tree) | **Build E5**; keep tech gates as factory progression |
| 07 Quests & narrative | quests.toml + dialogue.toml + npcs.toml + journal | **Reuse wholesale** (data format already fits) |
| 08 Enemies & ecology | animals.toml + ecology.rs + ire tiers | **Reuse**; **build E9** (nests + new archetypes) + E12 (ire repoint) |
| 09 Alien arc | npcs/quests/dialogue + enemy content | **Reuse**; content-only (C8) |
| 10 Factory-RPG integration | belts/rails/machines + quests | **Reuse** engine, **build E8/E13** |
| 11 Implementation phases | — | see Part 5 phasing below |
| 12 Combat depth & encounters | attack wheels, resist, damage classes | **Reuse**; extend damage-class set to 7 types (content, E6 resists) |
| 13 New player experience | starter settlements (data) | Content (C4) |
| 14 Chronarch arc (Act 3) | — | **Redesign/defer**; depends on E5 (Temporal branch) + time/reload semantics; post-slice |
| 15 Data-driven architecture | WildForge mod system (TOML + Rhai) | **Reuse** — this is the port's home |
| 16 Visual overhaul | atlas tiles + box models, pixel-voxel | **Accept voxel aesthetic** for v1 (see Risks); no GLTF import capability exists |
| 17 UI/UX | UiBatch immediate-mode, closed Screen enum | **Build E11** |
| 18 Testing framework | WildForge test culture (914 tests) | **Reuse**; E0 unlocks mod-side tests |

---

## 4. Mod content plan (belt-quest repo)

Pure data + scripts. Each content chunk maps to belts phases; content
ships **only after** the capabilities it consumes exist.

| C# | Content | Consumes | Source (belts phase) |
|---|---|---|---|
| C1 | Core blocks/items/recipes: factory buildings, belts feed, materials, consumables | E7, E8 | M1–M6 factory base |
| C2 | Modular equipment: frames, components, loadout presets, assembler/workbench recipes | E6, E11 | Phase 2 |
| C3 | Combat content: weapons (7 damage types), ammo, turrets, 5 fauna tiers + corrupt/machine enemies | E3, E9, E12 | Phases 1, 6 |
| C4 | World: starter settlements, 6 biome templates, reputation, needs/supply, discovery | E1, E13 | Phases 0, 3 |
| C5 | Dungeons: 6 types, bosses, puzzles, checkpoints, blueprint rewards | E10, E11 | Phase 4 |
| C6 | Skill tree data: 7 branches, ~120 nodes, 65 points; XP sources with diminishing returns | E5, E11 | Phase 5 |
| C7 | Economy: credits, barter, market pricing, settlement orders | E13 | Phase 8 |
| C8 | Alien arc: Shapers/Custodian, first-contact, alien resources/buildings/enemies, The Archive | E9, E11, E13 | Phase 7 |
| C9 | Chronarch arc (Act 3, hidden): Aggression Index, Temporal branch, the Crawler | E5, E10, E12 | Phase 9 (redesigned) |

### 4.1 Script hooks belt-quest relies on (existing today)

`on_world_start`, `on_tick`, `on_block_break/place` (cancellable),
`on_interact`, `on_craft`, `on_animal_killed`, `on_enemy_destroyed`,
`on_hurt`, `on_attack`, `on_player_respawn`, `on_mode_change`, plus
dialogue `condition`/`callback`. KV storage (`storage_get/set`, saved in
`modstore.toml`) carries quest/rep/settlement state.

### 4.2 What belt-quest mods out (per ruleset E1)

- Hunger/food survival off (food = buffs only).
- Ire sourced from **factory output** (E12), not extraction.
- Hearts/offerings loop disabled in the belt-quest mode.
- No fast-travel content; no fall-damage grind.
- Creative-only and survival-only content rules: belt-quest runs its own
  mode with its own content gating.

---

## 5. Phasing

**Milestone A — Capability ramp (WildForge, generic).**
A1: E0 test harness + E1 ruleset + E2 third-person cam.
A2: E3 combat depth + E4 stat surface.
A3: E5 skill tree + E6 modular equipment (+ E11 screens layer pulled
forward).
A4: E7 machine kinds + E8 belt geometry/persistence + E9 AI/nests.
A5: E10 dungeon zones + E12 ire repoint + E13 depot/economy (+ E14 folds
in per-capability).

**Milestone B — belt-quest slice (this repo).**
A playable vertical slice: starter settlement (C4), small factory (C1),
modular gear (C2), starter dungeon + one boss (C5), first quest arc (C7
reused quest format). This mirrors belts Phases 0–2 as a thin but complete
loop and proves the factory↔RPG fusion end to end.

**Milestone C — Content completion.**
C3 combat breadth → C5 dungeon set → C6 skill tree data → C8 alien arc →
C7 economy → C9 Chronarch. Reuses belts' authored content wholesale where
formats permit.

---

## 6. Repo layout & CI

```
belt-quest/
  mods/belt_quest/          # the mod: mod.toml + *.toml + main.rhai + textures/
  docs/                     # this plan + capability task briefs once owned here
  src/tools/                # helper scripts (content lint, .toml schema checks)
  Cargo.toml                # dev-only: test harness pinning a WildForge checkout
  .gitmodules               # WildForge pinned (submodule or git dep) for CI
```

CI (E0 landed): install the mod into a pinned WildForge checkout's `mods/`
tree, then run:
1. `cargo test --lib` and `cargo clippy --lib --tests -- -D warnings` on
   the WildForge checkout (the shared harness + full suite prove content).
2. `wildforge --mod-qualification mods` — gate on exit 0. This is the
   mod-content lint: all ids register, recipes balance against the
   material ledger, textures exist, every item is reachable in survival,
   and every `main.rhai` compiles.

Until content exists, this repo carries the plan + content skeletons only.

---

## 7. Risks & decisions to confirm

1. **Aesthetic.** WildForge is pixel-voxel; belts' docs explicitly reject
   "voxel art" (doc 16). v1 accepts voxel aesthetics. A GLTF/model-import
   capability would be a large E-item; decide after the slice whether the
   stylized-industrial art direction justifies it.
2. **Skill tree non-goal.** E5 deliberately reverses WildForge's stated
   "no skill trees / no recipe locks" economy non-goal. It is additive and
   mode-gated (E1), so Survival/Creative remain unchanged; still, this is
   a philosophical change worth an explicit callout in WildForge's docs.
3. **Third-person in a voxel engine.** Over-shoulder camera + melee arcs
   + i-frames must be tuned against voxel geometry (blocky corners, 1 m
   grid). Combos/backstabs are aimed-at-the-crosshair — acceptable.
4. **Instanced zones vs continuous world.** belts despawns the overworld
   inside dungeons (factory frozen). That's an ethos match (dungeons are
   destination content), but it's a big change from WildForge's always-
   loaded sim. E10 must decide between true zone swap and a "reduced-tick
   overworld" variant early.
5. **Belt persistence.** Belt cargo is currently transient (empty after
   reload); E8 persists it. That's a save-format/version bump in WildForge.
6. **Chronarch (Act 3).** Time-travel bootstrap-paradox content depends on
   save/reload semantics that interact with E14. Defer; design after the
   slice, not before.
7. **Content volume.** belts is ~45k lines of Bevy through Phase 8. The
   port's content is the same volume, but as data (much smaller in
   TOML). Still the long pole of Milestone C.

---

## 8. Immediate next actions

1. Land **E0** (mod test harness) in WildForge — unblocks this repo's CI.
2. Land **E1** (ruleset) — unblocks the mod-out story and every gated
   capability.
3. Land **E2** (third-person camera) — the ethos-critical combat item.
4. File the E3–E14 task briefs in WildForge `docs/extension-plans/` as
   the capability ramp proceeds.
5. Scaffold `mods/belt_quest/mod.toml` + a starter-world demo mod in this
   repo as soon as E0+E1 exist.
