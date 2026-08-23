// belt-quest slice script: quest-board flavor, kill tracking for First
// Threat, and the dialogue callbacks the Haven voices dispatch.

fn on_screen_click(screen, action) {
    if screen == "belt_quest:board" && action == "pin_notice" {
        hud_message("Marek will want to hear that idea. Find him at the hall.");
    }
    if screen == "belt_quest:conduits" && action.starts_with("valve_") {
        on_screen_click_valve(action.substr(6));
    }
}

// First Threat: Jonas counts wolves. Base's wolf is `base:wolf`.
fn on_animal_killed(name, face, u, y, v) {
    if name == "base:wolf" {
        quest_progress("first_threat", "wolves", 1);
    }
    if name == "belt_quest:cave_spider" {
        quest_progress("brood_gallery_cull", "spiders", 1);
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
