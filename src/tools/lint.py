#!/usr/bin/env python3
"""Repo-local static checks for the belt-quest mod.

This is the helper promised by the README (`src/tools/`): fast checks
that run without a Wildforge checkout or a Rust toolchain. They do not
replace the authoritative gates — `wildforge --mod-qualification mods`
plus the Wildforge playtest/registry suites (see
docs/refactor-verification.md) — but they catch local mistakes early.

Deliberately tolerant TOML handling: content files use multi-line
inline tables that strict TOML 1.0 parsers (e.g. Python's `tomllib`)
reject, while Wildforge's loader accepts them. So this lint parses
`mod.toml` strictly and scans the rest with line-oriented checks plus
`id` cross-referencing instead of a full strict parse.

Usage:
    python3 src/tools/lint.py [--mod mods/belt_quest]

Exit 0 when all checks pass, 1 with a `failure: ...` line per problem.
"""

from __future__ import annotations

import argparse
import re
import sys
import tomllib
from pathlib import Path

MOD_ID = "belt_quest"
REQUIRED_FILES = [
    "mod.toml",
    "modes.toml",
    "blocks.toml",
    "items.toml",
    "recipes.toml",
    "machines.toml",
    "screens.toml",
    "skills.toml",
    "animals.toml",
    "nests.toml",
    "structures.toml",
    "pieces.toml",
    "quests.toml",
    "dialogue.toml",
    "npcs.toml",
    "features.toml",
    "main.rhai",
]

# Files whose first line must be `schema_version = 1`.
SCHEMA_VERSION_FILES = ("machines.toml", "screens.toml", "skills.toml")

# Rhai host functions the mod may call (Wildforge script API, refactor-safe).
KNOWN_HOST_FNS = {
    "set_block",
    "get_block",
    "surface_height",
    "give",
    "hud_message",
    "open_screen",
    "play_sound",
    "spawn_animal",
    "quest_progress",
    "quest_accept",
    "log",
    "storage_get",
    "storage_set",
}

# Script event hooks the engine dispatches.
KNOWN_HOOKS = {
    "on_world_start",
    "on_tick",
    "on_block_break",
    "on_block_place",
    "on_interact",
    "on_craft",
    "on_animal_killed",
    "on_enemy_destroyed",
    "on_hurt",
    "on_attack",
    "on_player_respawn",
    "on_mode_change",
    "on_screen_click",
}

ID_RE = re.compile(r'^\s*id\s*=\s*"([^"]+)"')
SECTION_RE = re.compile(r"^\s*\[\[?([A-Za-z0-9_.]+)\]?\s*\]")
QUAL_REF_RE = re.compile(r'"(belt_quest:[A-Za-z0-9_]+)"')
FN_DEF_RE = re.compile(r"(?m)^\s*fn\s+([A-Za-z0-9_]+)\s*\(")


def fail(problems: list[str], msg: str) -> None:
    problems.append(msg)


def check_required_files(mod: Path, problems: list[str]) -> None:
    for name in REQUIRED_FILES:
        if not (mod / name).is_file():
            fail(problems, f"missing required file: {name}")


def check_mod_manifest(mod: Path, problems: list[str]) -> None:
    try:
        data = tomllib.loads((mod / "mod.toml").read_text())
    except Exception as exc:  # strict parse is safe here; mod.toml is simple
        fail(problems, f"mod.toml does not parse: {exc}")
        return
    if data.get("id") != MOD_ID:
        fail(problems, f"mod.toml id is {data.get('id')!r}, want {MOD_ID!r}")
    if data.get("world_api") != 2:
        fail(problems, f"mod.toml world_api is {data.get('world_api')!r}, want 2")
    if "base" not in data.get("depends", []):
        fail(problems, "mod.toml depends should include base")


def check_schema_versions(mod: Path, problems: list[str]) -> None:
    for name in SCHEMA_VERSION_FILES:
        text = (mod / name).read_text()
        if not re.search(r'(?m)^\s*schema_version\s*=\s*1\s*$', text):
            fail(problems, f"{name} must declare schema_version = 1")


def collect_defined_ids(mod: Path) -> set[str]:
    """Collect `belt_quest:<id>` for every `id = ...` in table-array files."""
    defined: set[str] = set()
    for path in mod.glob("*.toml"):
        if path.name in ("mod.toml", "modes.toml"):
            continue
        for line in path.read_text().splitlines():
            m = ID_RE.match(line)
            if m:
                defined.add(f"{MOD_ID}:{m.group(1)}")
    return defined


def collect_script_fns(mod: Path) -> set[str]:
    text = (mod / "main.rhai").read_text()
    return set(FN_DEF_RE.findall(text))


def check_internal_refs(mod: Path, problems: list[str]) -> None:
    defined = collect_defined_ids(mod)
    script_fns = collect_script_fns(mod)
    # Dialogue callbacks/conditions resolve through ScriptHook to Rhai
    # functions, not the content-id registry: `belt_quest:accept_x` means
    # Rhai `fn accept_x`. Validate those against the script instead.
    dialogue_text = (mod / "dialogue.toml").read_text()
    dialogue_refs = set(QUAL_REF_RE.findall(dialogue_text))
    for ref in sorted(dialogue_refs):
        fn = ref.split(":", 1)[1]
        if fn not in script_fns:
            fail(problems, f"dialogue.toml: callback/condition {ref} has no fn {fn} in main.rhai")
    for path in mod.glob("*.toml"):
        if path.name == "dialogue.toml":
            continue
        text = path.read_text()
        for ref in QUAL_REF_RE.findall(text):
            # `feature:<id>` and `spawn:*` markers carry prefixes after the
            # colon split; only check the simple `belt_quest:<word>` shape.
            if ":" in ref[11:]:
                continue
            if ref not in defined:
                # Allow well-known cross-kind refs resolved outside the id
                # registry: dungeon assemblies referenced by blocks, depot
                # settlements referenced by blocks, machine mouths.
                # Those ARE in `defined` today; anything left is a real gap.
                fail(problems, f"{path.name}: undefined ref {ref}")


def check_brackets_balanced(mod: Path, problems: list[str]) -> None:
    for path in mod.glob("*.toml"):
        depth = 0
        in_str = False
        esc = False
        for lineno, line in enumerate(path.read_text().splitlines(), 1):
            stripped = line.split("#", 1)[0]
            for ch in stripped:
                if in_str:
                    if esc:
                        esc = False
                    elif ch == "\\":
                        esc = True
                    elif ch == '"':
                        in_str = False
                    continue
                if ch == '"':
                    in_str = True
                elif ch in "[{":
                    depth += 1
                elif ch in "]}":
                    depth -= 1
                    if depth < 0:
                        fail(problems, f"{path.name}:{lineno}: unbalanced bracket")
                        depth = 0
        if depth != 0:
            fail(problems, f"{path.name}: unbalanced brackets at EOF")


def check_script(mod: Path, problems: list[str]) -> None:
    text = (mod / "main.rhai").read_text()
    defined_fns = set(FN_DEF_RE.findall(text))
    unknown_hooks = {f for f in defined_fns if f.startswith("on_")} - KNOWN_HOOKS
    # `on_screen_click_valve` is a local helper, not an engine hook.
    unknown_hooks.discard("on_screen_click_valve")
    for hook in sorted(unknown_hooks):
        fail(problems, f"main.rhai: unknown on_ hook {hook}")
    # Calls look like `name(` at line start or after `;`, whitespace, or
    # operators; attribute calls (`x.parse_int()`) are Rhai builtins.
    for lineno, line in enumerate(text.splitlines(), 1):
        code = line.split("//", 1)[0]
        if FN_DEF_RE.match(code):
            continue  # the definition itself is not a call
        for m in re.finditer(r"(?<![\w.])([a-z_][a-z0-9_]*)\s*\(", code):
            name = m.group(1)
            if name in ("if", "else", "for", "while", "let", "fn", "return"):
                continue
            if name in defined_fns or name in KNOWN_HOST_FNS:
                continue
            # Rhai builtins used by this script.
            if name in {"parse_int", "to_string", "clamp", "starts_with"}:
                continue
            fail(problems, f"main.rhai:{lineno}: unknown function {name}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--mod", default="mods/belt_quest")
    args = ap.parse_args()
    mod = Path(args.mod)
    problems: list[str] = []
    if not mod.is_dir():
        print(f"failure: mod dir not found: {mod}")
        return 1
    check_required_files(mod, problems)
    check_mod_manifest(mod, problems)
    check_schema_versions(mod, problems)
    check_brackets_balanced(mod, problems)
    check_internal_refs(mod, problems)
    check_script(mod, problems)
    if problems:
        for p in problems:
            print(f"failure: {p}")
        print("qualification status: FAIL")
        return 1
    print(f"mods: {mod}")
    print("failures: none")
    print("qualification status: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
