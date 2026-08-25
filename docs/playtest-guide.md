# Belt-Quest Playtest Guide

Walkthrough for exercising every implemented feature of the belt-quest mod
on WildForge `main`. Organized as a sequential progression — each section
builds on the last — with checkboxes so you can track what you've covered.

---

## 0. Setup

### Install the mod

Copy or symlink the belt-quest mod into WildForge's mods tree:

```
ln -s /path/to/belt-quest/mods/belt_quest /path/to/Wildforge/mods/belt_quest
```

(Or just copy the folder. The path is git-ignored so it won't pollute commits.)

### Create a world

1. Launch `wildforge.exe`.
2. On the title screen, pick **Survival** (or **Creative** for unrestricted testing).
3. Name and create the world.

> **Known gap:** the title screen doesn't yet list mod-declared game modes.
> To play with the belt_quest ruleset (no hunger, skills + equipment on,
> nest spawns on, hostile ring off), quit after world creation and edit
> `mode = "belt_quest"` inside `<save_dir>/world.toml`, then relaunch.
>
> Without this edit, the world runs stock survival: hunger drains, hearts
> loop fires, ring wardens spawn, and the skill/equipment screens stay locked.

### Find Haven

Haven generates in plains and forest biomes (rarity 200, so roughly 1-in-200
eligible chunks). Look for limestone-and-cobblestone buildings with wooden
roofs. If you spawn near a coastline or desert, travel inland until the
ground turns grassy.

You'll know you've found Haven when you see:
- A stone hall with Marek standing outside and a **Quest Board** on the wall
- A market stall with Ava behind a barter counter
- A workshop with Sal, a **Smelter**, an **Assembler**, and a chest of materials
- A wall section where Jonas patrols

---

## 1. The Quest Arc (E4 quests + E11 screens + E2 dialogue)

### Settling In

- [ ] Right-click Marek → "What needs doing?" → quest accepted
- [ ] Talk to Ava, Sal, and Jonas (each is a dialogue tree)
- [ ] Read the Quest Board (right-click the board block)

**What to verify:** quest accepted toast; three distinct NPC voices;
the board screen shows labels, KV readouts, and a working button.

### First Errand

- [ ] Return to Marek → herbs available topic → accept
- [ ] Gather 5 medicinal herbs (bushes in the meadow)
- [ ] Return to Marek

**Rewards:** 50 coins, iron pickaxe, +15 Haven reputation.

### The Spark (factory tutorial)

- [ ] Talk to Sal → "Teach me." → accepts quest and gives firebrick/ore/coal
- [ ] Place the Smelter from your inventory (4 firebrick recipe, or use
      the pre-placed one in the workshop)
- [ ] Feed raw iron + charcoal into the Smelter (right-click to open)
- [ ] Wait for the firing to complete (~90 s per batch)
- [ ] Collect the iron ingot from the output slot

**What to verify:** machine opens as a container screen with charge/fuel/
output slots; lit state swaps the texture; industrial ire ticks while lit.

### First Threat (combat tutorial)

- [ ] Talk to Jonas → "Give me a reason to fight back." → receives Light
      Melee Frame
- [ ] Accept First Threat
- [ ] Kill 3 wolves in the west meadow

**Combat systems to try:**
- Left-click light attack (0.9 s combo window)
- Hold left-click heavy attack (2.5× damage, more stamina)
- Alt-dodge (i-frames, stamina cost, 0.8 s cooldown)
- F-block (65% damage reduction while held, guard drain per hit)
- Attack from behind for backstab (2× damage beyond 110° cone)

**What to verify:** stamina bar drains on sprint/swing/dodge/block;
regen kicks in after exertion delay; floating damage numbers appear;
wolf health bars visible when damaged.

---

## 2. Modular Equipment (E6 frames + components)

### Crafting

- [ ] Craft a **Light Harness** at the free grid (4 leather)
- [ ] Craft an **Iron Blade** (4 iron ingot, 2×2 grid)
- [ ] Craft a **Wood Grip** (2 plant fiber)
- [ ] Wear the Harness (chest armor slot) and wield the Melee Frame

### Slotting components

1. Open your inventory (Tab or E)
2. With the Harness worn, click a component in your inventory, then click
   the frame's plate/lining slot on the loadout screen (L key)

**What to verify:** components slot in/out INTACT; their stat bonuses
(+hearts, +carry, +speed) apply only while the frame is worn AND intact;
frames disable at 0 durability but are never destroyed.

### Loadout presets

- [ ] Configure a loadout
- [ ] Save it as a preset (loadout screen, save button)
- [ ] Swap components, then apply the preset to restore

---

## 3. Skill Tree (E5)

- [ ] Press K to open the skill screen
- [ ] Earn XP by mining, building, crafting, smelting, killing, harvesting
- [ ] Level up and allocate points into branches
- [ ] Verify tier gating: need 3 allocated tier-(N-1) nodes in-branch to
      unlock tier N
- [ ] Try the respec button

**Branches:** Survivalist, Warrior, Engineer, Logistics, Diplomat,
Explorer, Temporal (hidden — see §8 Chronarch arc).

---

## 4. Factory Production (E7 machines)

### The Assembler

The workshop's Assembler is a **workbench-handler station**: right-click to
open its recipe list. Station recipes are NOT craftable on the free grid.

Station recipes to try:
- Copper Wire (1 copper ingot → 2 wire)
- Circuit (plate + 2 wire → 2 circuits)
- Health Stim (2 herbs + coal)
- Iron Plate Component (3 iron ingot)
- Steel Blade (3 steel ingot)
- Coil Carbine (wire + gear + iron)

**What to verify:** station recipes appear ONLY at the assembler; crafting
consumes from inventory; Sfx plays; on_craft hook fires (feeds settlement
order objectives).

### The Smelter

Forge-handler machine: feed charge + fuel, wait for the batch.
Try the alien-tier conversions once you have chitin/corrupted tissue
(see §6).

---

## 5. Depot Logistics (E13 settlement economy)

- [ ] Locate the Depot block in the workshop (blue-glass-topped box)
- [ ] Hold bread (or planks, or raw iron) and right-click the depot

**What to verify:** toast appears ("Haven appreciates the bread (+2 standing)");
reputation key increments in your player KV; depositing non-needed items
produces a refusal toast; once staged stock fills the window, further
deposits are refused.

### Settlement orders

Three production contracts are available from NPCs:
- Haven: produce 8 iron plates (talk to Marek, craft at assembler)
- Emberwatch: assemble 2 machine frames (find the mountains outpost)
- Saltmarsh: draw 10 copper wire (find the scrubland outpost)

Each pays credits + reputation. Progressed by the on_craft script hook.

### Barter counters

Stall counters exist at Haven's market and Saltmarsh's yard. Claim one
(right-click first), stock goods, set a barter price, and other players
(or you) can buy from the till.

---

## 6. Dungeons (E10 instanced zones + E9 nests)

### Getting below

Craft a **Deep Door** (4 limestone bricks) and place it. Right-click to
enter the dungeon bound to that door. Each assembly has its own run.

### The Brood Gallery (starter)

Your first Deep Door leads here: gate → corridors → hoard chamber.

- [ ] Burrow spiders manifest from nest blocks (rusher archetype: sprint
      toward you at 2.2× speed)
- [ ] The Brood Mother holds her den: controller archetype, summons cave
      spiders every 18 s, resists slash/pierce
- [ ] Collect chitin and venom sacs from kills
- [ ] Find the Way Out block and right-click to exit
- [ ] Leave the area empty for ~15 min: the run resets (chunks dropped)

### The Abandoned Mines (conduit puzzle)

Craft/place another Deep Door variant or find one at an outpost.
This dungeon has a **conduit puzzle**: a Conduit Hub block opens an E11
screen with four valve buttons.

- [ ] Press valves in the wrong order → lock resets
- [ ] Find the authored order (humming, brass, steel, copper)
- [ ] Solving completes a hidden quest whose reward sets the flag that
      unseals a feature-gated corridor
- [ ] The Foreman boss: controller archetype, summons scrap hounds,
      resists pierce/slash, drops his schematic (blueprint item)

### The Alien Ruins (Custodian content)

Shaper-stone pieces lit from within. Custodian Sentinels use the
shield-bearer archetype (front-facing damage reduction — attack from
behind). Hackable with the hack tool.

### Creature Lair

A short two-piece fight den: bear den + spider burrow + cache chest.

---

## 7. Enemy AI Archetypes (E9)

Each archetype exercises different combat behavior:

| Archetype | Test creature | What to observe |
|---|---|---|
| Rusher | Cave Spider | Closes at sprint speed |
| Tank | Corrupted Boar / Cave Bear | Barely flinches from hits |
| Sniper | Corrupted Stalker | Holds distance band, spits acid |
| Support | Willowkeeper (test mod) | Heals nearby allies |
| Swarm | Brood Mother | Spawns spiders on death |
| Controller | Cinderlord / The Foreman | Summons minions periodically |
| Phaser | Wisp Phantom | Blinks toward target instead of walking |
| Shield-Bearer | Custodian Sentinel | Front-facing damage reduction |

**Nest mechanics:** every hostile arrives through a nest block. Breaking
the nest stops respawns. Nest blocks are per-species (a burrow ≠ a lair).

---

## 8. Industrial Response Gradient (E12 ire repoint)

- [ ] Run a Smelter continuously for several minutes
- [ ] Check regional ire (if the HUD shows it, or via console)
- [ ] At ire tier 2+: notice wildlife acting bolder (wolves/deer don't
      flee as far)
- [ ] Place multiple machines and watch ire climb faster

---

## 9. The Alien Arc (C8)

### Strange Signals → Into the Deep

After The Spark, Sal offers a follow-up chain about energy readings.
Complete it to unlock alien-tier content.

### Custodian Contact

Find the Custodian NPC (spawned via surface ruins or the alien ruins
dungeon). Dialogue choices set your initial relationship tone.

- [ ] Choose cooperative or hostile opening
- [ ] Check custodian_rep storage channel

### Alien Fabricator

Build one (alien alloy + energy crystal + circuit at the assembler).
Station recipes include the Alien Exoframe and Archive Gate.

### Path-locked tech

- Cooperative (+300 standing): unlocks Custodian Beacon recipe
- Hostile (−300 standing): unlocks salvaged beam emitter + reactive plating
- Crossing thresholds completes hidden quests automatically (polled by
  main.rhai on_tick)

### The Custodian Beacon

Placeable structure that registers as a nest for beacon sentinels —
non-hostile guards that hunt frontier predators within 24m. Break the
beacon to stand them down.

---

## 10. The Chronarch Arc (C9 — hidden storyline)

### Triggering

The arc activates when ALL of these hold:
1. Your aggression index ≥ 600 (tracked by main.rhai from proactive kills)
2. You're past the early game
3. Custodian standing < +300
4. You've killed proactively across multiple species

To test quickly: kill deer/boar/goats (each +8 aggression), kill Watchers
(+15), avoid completing First Threat (quest kills don't count).

- [ ] Cross the threshold → "Something watches from the ridge."
- [ ] First Crow quest accepted → kill a Watcher

### Chronarch units

| Unit | Archetype | Behavior |
|---|---|---|
| Watcher | Phaser | Blinks toward/away, temporal fragment drops |
| Rook | Tank | 15% knockback, wing-slam + resistances |
| Raven | Support | Heals allied Chronarchs |
| The Reflection | Controller | Summons cave spiders, drops Temporal Core |

### Temporal branch

Once triggered, the Temporal skill branch becomes allocatable (7th
branch, 7 nodes). Access via the skill screen.

### Temporal Engineering

Temporal fragments drop from Chronarch kills. Spend them at the alien
fabricator on temporal shield plates and disruptors (tech-gated).

---

## 11. Multiplayer (E13 depot logistics)

- Host a world (or join one)
- Both players visit a depot
- Guest deposits goods → host validates → guest sees the appreciation toast
- Reputation pays into the GUEST'S local KV namespace

---

## Feature Coverage Checklist

| System | Capability | Section |
|---|---|---|
| Ruleset / game modes | E1 | §0 |
| Third-person camera + combat | E2/E3 | §1 |
| Stamina, dodge, block, backstab | E3 | §1 |
| Quest system + journal | E4 | §1 |
| Skill tree (7 branches) | E5 | §3 |
| Modular equipment + loadout presets | E6 | §2 |
| Machine kinds (smelter/assembler/converter/fabricator) | E7 | §4 |
| Belt geometry & persistence | E8 | *(place belts, verify cargo persists)* |
| Enemy AI archetypes ×8 | E9 | §7 |
| Instanced dungeon zones | E10 | §6 |
| Mod-extensible screens | E11 | §1, §5, §8 |
| Industrial response gradient | E12 | §8 |
| Settlement depot logistics | E13 | §5 |
| Guard archetype (mob-vs-mob combat) | E15 | §7, §9 |
| Aggression Index + Chronarch faction | C9 | §10 |
| Alien fabricator tier | C8 | §9 |
| Matter Converter | C8 w3 | §6 |
| Conduit lock puzzle | C5 | §6 |
| Growth tiers (rep-gated buildings) | C4 | §5 |
| Barter counters | C7 | §5 |
| Settlement production orders | C7 | §5 |
