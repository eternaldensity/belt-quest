// belt-quest slice script: quest-board flavor, kill tracking for First
// Threat, and the dialogue callbacks the Haven voices dispatch.

fn on_screen_click(screen, action) {
    if screen == "belt_quest:board" && action == "pin_notice" {
        hud_message("Marek will want to hear that idea. Find him at the hall.");
    }
    if screen == "belt_quest:archive_terminal" && action == "request_directive" {
        let rep = storage_get("custodian_rep");
        let n = if rep == "" { 0 } else { rep.parse_int() };
        if n >= 300 {
            hud_message("'Cooperative threshold met. The deepest stacks open for you.'");
        } else if n <= -300 {
            hud_message("'Hostility archived. The deepest stacks close for you.'");
        } else {
            hud_message("'Assessment ongoing. Maintain, wait, teach those who ask.'");
        }
    }
    if screen == "belt_quest:conduits" && action.starts_with("valve_") {
        // This rhai has no substr; map the whole action name instead.
        let letter = if action == "valve_a" {
            "a"
        } else if action == "valve_b" {
            "b"
        } else if action == "valve_c" {
            "c"
        } else {
            "d"
        };
        on_screen_click_valve(letter);
    }
}

// First Threat: Jonas counts wolves. Base's wolf is `base:wolf`.
fn on_animal_killed(name, face, u, y, v) {
    if name == "base:wolf" {
        quest_progress("first_threat", "wolves", 1);
        // Proactive wolf kills (not First Threat) raise the index.
        let ft = storage_get("quest_first_threat");
        if ft != "accepted" && ft != "done" {
            aggression_delta(8);
        }
    }
    if name == "belt_quest:cave_spider" {
        quest_progress("brood_gallery_cull", "spiders", 1);
    }
    // Neutral fauna: unprovoked.
    if name == "base:deer" || name == "base:boar" || name == "base:goat" {
        aggression_delta(8);
    }
    // Corvid kills are always proactive — they observe, they don't attack first.
    if name == "belt_quest:chronarch_watcher" || name == "belt_quest:chronarch_rook" {
        aggression_delta(15);
    }
}

// ---- dialogue callbacks (condition/callback fns) ----

fn accept_settling_in() {
    quest_accept("settling_in");
    hud_message("Quest accepted: Settling In.");
}

fn herbs_available() {
    storage_get("quest_first_errand") != "done"
}

fn accept_first_errand() {
    quest_accept("first_errand");
    hud_message("Five blue-flowered herbs, west meadow.");
}

fn accept_the_spark() {
    quest_accept("the_spark");
    give("base:firebrick", 8);
    give("base:raw_iron", 4);
    give("base:coal", 4);
    hud_message("Sal hands you firebrick, ore, and coal.");
}

fn greet_first_threat() {
    // The blade arrives once; the offer never re-gifts.
    if storage_get("jonas_blade") != "given" {
        give("belt_quest:light_melee_frame", 1);
        storage_set("jonas_blade", "given");
    }
}

fn accept_first_threat() {
    quest_accept("first_threat");
}

// ---- C5: the Foreman's conduit lock ----
// Valves must be pressed in the authored order (humming, brass, steel,
// copper). A wrong press resets the lock. Solving completes the hidden
// quest whose reward unseals the corridor and teaches the Scrap Rig.

fn on_screen_click_valve(order) {
    let n = storage_get("valves");
    let seq = if n == "" { "" } else { n };
    let next = seq + order;
    // The authored order, one letter per valve: d, a, c, b.
    if !"dacb".starts_with(next) {
        storage_set("valves", "");
        hud_message("The conduits hiss and reset.");
        return;
    }
    storage_set("valves", next);
    if next == "dacb" {
        hud_message("Deep below the floor, something unlocks.");
        quest_progress("mines_conduits", "routed", 1);
        play_sound("craft");
    } else {
        hud_message("The hub clicks. Another valve hums awake.");
    }
}

// ---- C8: first contact ----

fn custodian_cooperative() {
    let rep = storage_get("custodian_rep");
    let base = if rep == "" { 0 } else { rep.parse_int() };
    storage_set("custodian_rep", (base + 50).to_string());
    hud_message("The Custodian logs: provisional cooperative intent.");
}

fn custodian_hostile() {
    let rep = storage_get("custodian_rep");
    let base = if rep == "" { 0 } else { rep.parse_int() };
    storage_set("custodian_rep", (base - 50).to_string());
    hud_message("The Custodian logs: provisional hostile intent.");
}

fn strange_signals_done() {
    storage_get("quest_strange_signals") == "done"
}

fn accept_into_the_deep() {
    quest_accept("into_the_deep");
}

// Archive data slates feed the Custodian relationship when delivered by
// hand to any depot bound to the archive facility.
// ---- C7: settlement order contracts (crafting feeds the meter) ----

fn on_craft(item_name) {
    if item_name == "belt_quest:iron_plate_component" {
        quest_progress("order_haven_plates", "plates", 1);
    }
    if item_name == "belt_quest:machine_frame" {
        quest_progress("order_emberwatch_frames", "frames", 1);
    }
    if item_name == "belt_quest:copper_wire" {
        quest_progress("order_saltmarsh_wire", "wire", 1);
    }
}

// ---- C8 wave two: the relationship economy ----
// Killing Custodian constructs costs standing; solving their problems
// pays it. Threshold crossings complete the path quests, which unlock
// the path technologies.

fn custodian_rep_delta(delta) {
    let rep = storage_get("custodian_rep");
    let n = if rep == "" { 0 } else { rep.parse_int() };
    let next = (n + delta).clamp(-1000, 1000);
    storage_set("custodian_rep", next.to_string());
}

fn custodian_thresholds() {
    let rep = storage_get("custodian_rep");
    let n = if rep == "" { 0 } else { rep.parse_int() };
    if n >= 300 && storage_get("quest_custodian_alliance") == "" {
        quest_accept("custodian_alliance");
        quest_progress("custodian_alliance", "assessed", 1);
        hud_message("'Assessment complete. Provisional partners.'");
    }
    if n <= -300 && storage_get("quest_custodian_enmity") == "" {
        quest_accept("custodian_enmity");
        quest_progress("custodian_enmity", "assessed", 1);
        hud_message("'Assessment complete. Salvage protocols enabled.'");
    }
}

fn on_tick(dt) {
    chronarch_trigger_check();

    custodian_thresholds();
}

fn on_enemy_destroyed(name, face, u, y, v) {
    if name == "belt_quest:archive_warden" {
        quest_progress("the_archive_open", "warden", 1);
    }
}

// ---- C9: the Aggression Index ----

fn aggression_delta(points) {
    let cur = storage_get("aggression_index");
    let n = if cur == "" { 0 } else { cur.parse_int() };
    storage_set("aggression_index", (n + points).clamp(0, 2000).to_string());
}

fn chronarch_trigger_check() {
    let agg = storage_get("aggression_index");
    let n = if agg == "" { 0 } else { agg.parse_int() };
    let crep = storage_get("custodian_rep");
    let cr = if crep == "" { 0 } else { crep.parse_int() };
    if n >= 600 && cr < 300 && storage_get("quest_first_crow") == "" {
        quest_accept("first_crow");
        hud_message("Something watches from the ridge.");
    }
}
