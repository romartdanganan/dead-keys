# Dead Keys: Technical Design Document (Tech Spec)

| | |
|---|---|
| **Team** | Dead Keys (solo for Milestone 1; open to recruits from the design presentation, see GDD header) |
| **Engine / platform** | Godot 4.7 (GDScript) / Windows, Linux (primary), macOS (secondary) |
| **Companion doc** | `GDD.md`. This document does not restate gameplay numbers; it references them, following Lecture 3, "Reading and Writing GDDs." |
| **Repo** | [add once the course namespace is created] |
| **Doc version** | v0.2 |
| **Last updated** | 2026-07-28 |

## Changelog

| Version | Date | Change | Who |
|---|---|---|---|
| v0.1 | 2026-07-15 | Initial Tech Spec: architecture, system breakdown, data formats, save schema, CI, performance budgets, risk register | Romart Danganan |
| v0.2 | 2026-07-29 | Added the implemented Main Menu and Operations Hub scene architecture, reusable MissionCard component, image placeholders, menu navigation approach, current repository structure, and Issue #6 UI behaviour. | Romart Danganan |


---

## 0. Purpose & scope

The GDD answers *what* the game is and *why* a rule exists. This document answers *how it gets built*: architecture, node/scene layout, data formats, save schema, tooling, and risk. Where a number is gameplay-facing (fire rate, damage, costs, timers), it is defined once in the GDD and only referenced here by name. This document should never need its own copy of a balance number, so the two docs can't drift apart.

The project is solo as of Milestone 1, with the GDD explicitly open to recruits after the design presentation, so the architecture below favours simplicity (signals plus a couple of autoloads) over a large abstraction layer. That keeps the codebase easy for one person to hold in their head right now, and easy to explain to anyone who joins later, rather than assuming either a permanently solo build or a large team from day one.

---

## 1. Engine & platform

Godot 4.7, GDScript only (no C#/GDExtension this trimester, since that's one less toolchain to maintain if the team stays small). Export targets: Windows and Linux desktop as primary, macOS as secondary (build it, but don't spend debug time on Mac-only issues unless time allows). Minimum spec target is low by design (no 3D lighting, no large streamed assets, see GDD §10), so no special GPU-tier testing matrix is needed.

---

## 2. High-level architecture

### 2.1 Autoload singletons (global, persist across scenes)

| Autoload | Responsibility |
|---|---|
| `GameState` | Coins, unlocked upgrade levels, purchased supplies for the current mission, mission-unlock progress, best medals. Source of truth for anything that persists between missions. Read/written by `SaveSystem`. |
| `UpgradeCatalog` | Loads `UpgradeDef` resources, exposes the *current effective* stat for each upgrade track (fire rate, damage, magazine capacity, wall max health, lives max, jam duration, mistake leniency) by reading `GameState`'s purchased levels. Every other system asks this for a number instead of hard-coding one. |
| `SaveSystem` | Serializes/deserializes `GameState` to disk. Called only at mission-complete checkpoints (no mid-mission save, per GDD §2.8). |
| `AudioBus` | Music/SFX playback, the jam/boss-intro ducking rule (GDD §6.2). |

Everything else is scene-local. There are no other cross-scene singletons, to keep the codebase easy to hold in your head and easy to onboard a recruit into, whether or not that happens this trimester.

### 2.2 Scene tree overview

```
scenes/ui/main_menu.tscn
 ├─ replaceable background TextureRect
 ├─ replaceable logo TextureRect
 └─ Start / Settings / Quit controls

scenes/ui/home_base.tscn
 ├─ replaceable Operations Hub background and logo TextureRects
 ├─ gold display with replaceable coin-icon TextureRect
 ├─ Upgrades / Mission Supplies / Ability Loadout placeholder panels
 ├─ MissionGrid
 │   └─ six instances of mission_card.tscn
 └─ selected-mission details panel
	 ├─ selected mission image
	 ├─ title and description
	 ├─ best medal
	 └─ Launch Mission button

scenes/ui/mission_card.tscn
 ├─ mission image
 ├─ mission title
 └─ locked-state overlay

Mission.tscn              (future: instanced per mission and configured by MissionConfig)
 ├─ HUD.tscn
 ├─ WordLabelManager.tscn
 ├─ ZombieManager.tscn
 ├─ AmmoSystem.tscn
 ├─ MistakeSystem.tscn
 ├─ ComboSystem.tscn
 ├─ AbilitySystem.tscn
 ├─ SupplyController.tscn
 ├─ WallController.tscn
 └─ Weapon.tscn
Pause.tscn                (future overlay on Mission.tscn)
MissionEnd.tscn           (future mission-results screen)
```

Communication between sibling systems is via **signals**, not direct references, so any system can be unit-tested in isolation (see §7).

---

## 3. System-by-system breakdown

Each entry maps 1:1 to a GDD §2.2.x system. Numbers referenced (e.g. "5-kill threshold") live in the GDD; only the *mechanism* is specified here.

### 3.1 TypingController
Captures `InputEventKey`, resolved through the OS keyboard layout (not raw physical scancode; this is the GDD §10 flagged risk). Matches typed characters against the currently-targeted zombie's word buffer. Emits `char_correct`, `char_wrong(zombie)`, `word_completed(zombie)`.

### 3.2 AmmoSystem
Listens to `word_completed`. Looks up bullet count via a data-driven `word_length_to_bullets` table (see §5) rather than a hard-coded if/else, so GDD tier changes (like the v0.9 revision) are a data edit, not a code change. Adds to the ammo pool, capped at `UpgradeCatalog.magazine_capacity`. Emits `ammo_changed(new_value)`.

### 3.3 MistakeSystem
Listens to `char_wrong`. If `GameOptions.mistake_system_enabled` is false, does nothing at all (early return); this is the single toggle point for the accessibility option in GDD §2.2.2/§2.8. Otherwise: decrements ammo (unless already 0), increments a consecutive-mistake counter, triggers a jam at `UpgradeCatalog.jam_threshold` (mistake leniency upgrade raises this), starts a `UpgradeCatalog.jam_duration`-second timer during which `Weapon.fire()` is a no-op. Emits `combo_reset` (consumed by ComboSystem).

### 3.4 ComboSystem
Single `combo_count`. Increments on zombie-killed, resets to 0 on either `combo_reset` (from a mistake) or `wall_hit` (zombie reached the wall), whichever fires first. At the GDD-defined threshold, emits `ability_charged` and locks in the charge (a separate bool, `charge_available`, that survives further combo resets; see GDD §2.2.3 edge case).

### 3.5 AbilitySystem
Holds `equipped_ability` (set pre-mission, immutable once `Mission.tscn` loads). Listens for `ability_charged`. On the next `Weapon.fire()` event after that, consumes the charge and applies the ability's effect. Charge is discarded on `MissionEnd` if unspent.

### 3.6 SupplyController
Tracks `calls_remaining` (set from purchased supplies pre-mission, cap enforced at purchase time in `ShopPanel`, not here). On Supply input (keys 1–3): if the selected slot contains a supply and no crate is currently active, spawn the corresponding crate at the arena's designated `Marker2D` (not a runtime player-relative offset; see GDD §2.2.4 design note), starts a 3 s flight, then an 8 s claim timer. On `word_completed` matching the crate's word, claims it immediately. On timer expiry, removes the crate. There is no collision-based removal path; this was cut from the GDD and there is no code path for it.

### 3.7 ZombieManager / Zombie
One shared state machine (Spawn → Approach → Attack → Dead) implemented once in `Zombie.gd`. Per-type extra behaviour (Medic/Spitter/Commander/Exploder) is an optional attached component node rather than a subclass, so adding a new special behaviour later is "attach a component," not "branch the class hierarchy." Stats (health, speed, word-pool tag) come from an `EnemyType` resource (§5), so balancing is a data edit.

### 3.8 WordLabelManager
Positions and z-orders floating word labels above zombies. Implements the GDD §2.2.1 overlap rule: label priority goes to whichever zombie is closest to the wall; when multiple zombies are equidistant, labels are staggered/offset rather than any being fully hidden. This is implemented as a simple sort-by-distance-to-wall each frame, with a minimum on-screen offset enforced between any two labels whose bounding boxes would otherwise intersect.

### 3.9 Weapon
Handles Fire input, cooldown timer, damage application on hit. Reads `fire_rate`, `damage`, from `UpgradeCatalog` rather than owning its own copy of either number.

### 3.10 UpgradeCatalog (detailed)
The single place that turns "purchased level N of upgrade X" into "current effective stat value." Every gameplay system asks this instead of hard-coding a number, which is what keeps the GDD's upgrade table (§2.6.1) as the one place those numbers are actually defined.

### 3.11 SaveSystem
JSON to disk, written only at `MissionEnd` on completion (never mid-mission, matching GDD §2.8). See schema in §6.

### 3.12 ProgressionManager
Tracks which missions are unlocked (linear, per GDD §2.7) and each mission's best medal.

### 3.13 Main Menu and Operations Hub UI

`main_menu.tscn` is the project main scene. Its background and logo are `TextureRect` placeholders so final illustrated assets can replace the temporary textures without changing the layout. Start changes to `home_base.tscn`, Settings remains a placeholder until its dedicated issue, and Quit closes the scene tree.

`home_base.tscn` implements the Operations Hub layout defined in GDD §3 and §6.1. It contains a replaceable Hub background/logo, gold display with a replaceable coin icon, placeholder access panels for Upgrades, Mission Supplies, and Ability Loadout, a six-card mission grid, and a selected-mission details panel. The details panel repeats the selected mission's image and displays its title, description, best medal, and launch control. Mission 1 begins unlocked; Missions 2–6 are disabled placeholders until progression and saving are implemented.

Navigation between `main_menu.tscn` and `home_base.tscn` uses `SceneTree.change_scene_to_file()` with fixed `res://` paths. The scenes do not export `PackedScene` references to each other, because reciprocal serialized scene references create a circular resource dependency.

### 3.14 MissionCard UI component

`mission_card.tscn` is a reusable `Button` scene backed by `mission_card.gd` (`class_name MissionCard`). Exported properties currently provide the mission id, name, description, image, best medal, and locked state. Its image and title ignore mouse input so the parent button receives the click. A locked card displays an overlay and disables the root button. Selecting an unlocked card sends its exported display data to the Operations Hub details panel.

The current exported properties are suitable for the UI prototype. When `MissionConfigDef` resources are implemented, the card should receive or reference mission data from those resources rather than becoming a second long-term source of mission content.

---

## 4. Signal map (summary)

| Signal | Emitted by | Consumed by |
|---|---|---|
| `char_correct` / `char_wrong(zombie)` | TypingController | AmmoSystem, MistakeSystem |
| `word_completed(zombie)` | TypingController | AmmoSystem, SupplyController |
| `ammo_changed(value)` | AmmoSystem | HUD |
| `combo_reset` | MistakeSystem, WallController (on `wall_hit`) | ComboSystem |
| `combo_changed(value)` / `ability_charged` | ComboSystem | HUD, AbilitySystem |
| `wall_hit(damage)` | Zombie (Attack state) | WallController, ComboSystem |
| `zombie_killed(zombie)` | Weapon (on lethal hit) | ComboSystem, ZombieManager |
| `pressed()` | MissionCard instance | HomeBase mission-details controller |

---

## 5. Data & resource formats

All content below is an external `.tres` Resource, never hard-coded, per GDD §10: tuning is a data edit, not a rebuild.

| Resource | Fields | Used by |
|---|---|---|
| `WordListDef.tres` | mission id, difficulty tier, `Array[String]` words | word spawner, per-mission difficulty |
| `EnemyTypeDef.tres` | health, speed, word-pool tag, special-behaviour tag (optional) | Zombie.gd |
| `MissionConfigDef.tres` | mission id, word list ref, enemy wave schedule, base coin reward, background scene path | Mission.tscn loader |
| `UpgradeDef.tres` | id, track (Weapon/Base/Typing), levels\[] (cost, effect value) | UpgradeCatalog, ShopPanel |
| `SupplyDef.tres` | id, cost, effect type | ShopPanel, SupplyController |
| `AbilityDef.tres` | id, display name, effect script reference | AbilitySystem, AbilitySelectPanel |
| `word_length_to_bullets` table | length bracket → bullet count (GDD §2.2.1) | AmmoSystem |

---

## 6. Save file schema

Checkpoint-based, one write per completed mission (GDD §2.8). Example shape:

```json
{
  "coins": 0,
  "upgrades": {
    "fire_rate": 0,
    "bullet_damage": 0,
    "magazine_capacity": 0,
    "fortified_wall": 0,
    "extra_life": 0,
    "jam_duration": 0,
    "mistake_leniency": 0
  },
  "missions": {
    "mission_1": { "unlocked": true, "best_medal": "gold" },
    "mission_2": { "unlocked": false, "best_medal": null }
  },
  "options": {
    "mistake_system_enabled": true,
    "word_difficulty_assist": false,
    "typing_speed_assist": false
  }
}
```

Upgrade levels are stored as integers (current level per track); `UpgradeCatalog` resolves the integer to an effect value via the matching `UpgradeDef`, so the save file never stores a balance number directly, only "how many levels bought."

---

## 7. Testing strategy

Godot Unit Test (GUT), prioritised by how pure/logic-only each system is (highest value for least setup, a good fit whether the current team size stays at one or grows):

1. **AmmoSystem**: word-length-to-bullet-count lookup, cap-discard behaviour.
2. **MistakeSystem**: jam threshold trigger, ammo-already-0 edge case, toggle-off short-circuit.
3. **ComboSystem**: reset-on-mistake, reset-on-wall-hit, charge-persists-through-reset edge case.
4. **SupplyController**: cap enforcement, no-new-call-while-crate-live rule, 0-calls-remaining no-op.

Manual/integration test pass at each milestone checkpoint against the timings and numbers claimed in GDD §11 (Playtesting Plan): that section already defines what gets measured, this section just defines what gets automated first.

---

## 8. CI/CD pipeline

GitLab is used for version control throughout development. Every change is committed and pushed to the repository to maintain a complete history of the project.

Automated CI/CD is not currently configured. The project is built and tested locally in Godot during development. If time permits in later milestones, a GitLab CI pipeline may be added to automate project validation and Windows builds.
---

## 9. Performance budgets

Primary named risk (GDD §10): HUD performance with 20+ concurrent floating word labels on screen. Mitigation approach: pool `Zombie` and word-label nodes rather than instancing/freeing per spawn; keep the per-keystroke validation path (TypingController) allocation-free, since it runs on every frame a word is being typed; profile with the Godot profiler at the vertical-slice checkpoint (week 8) against real on-screen enemy counts, not synthetic ones.

---

## 10. Risk register

| Risk | Likelihood | Impact | Mitigation | Prove by |
|---|---|---|---|---|
| Keystroke capture unreliable across keyboard layouts | Medium | High (whole game depends on it) | Use layout-resolved `InputEventKey`, test on at least one non-QWERTY layout early | Week 3 (first thing built, per GDD §10) |
| HUD frame drop with many word labels | Medium | Medium | Pooling + profiling, see §9 | Week 8 (vertical slice) |
| Dev bandwidth across 8 enemy types + 2 bosses, if the team stays solo | Medium | Medium | MoSCoW already defers 4 of 8 enemies and 1 boss to Final milestone (GDD §1.6); a recruit joining after the design presentation would ease this further | Ongoing, reviewed weekly (GDD §12.3) |
| Data-driven resources drift out of sync with GDD balance numbers | Low | Medium | UpgradeCatalog/EnemyTypeDef are the only place numbers live; GDD references them, doesn't restate them | Ongoing |

---

## 11. Repo & folder structure (proposed)

```
GDD.md
Dead_Keys_TechSpec.md
README.md
project.godot
/images/                    (figures referenced by the GDD)
/assets/
  /audio/
  /fonts/
  /sprites/
/scenes/
  /ui/                      (main_menu.tscn, home_base.tscn, mission_card.tscn)
  /entities/
  /missions/
/scripts/
  /ui/                      (main_menu.gd, home_base.gd, mission_card.gd)
  /systems/
  /autoload/
  /entities/
/resources/
  /word_lists/
  /enemies/
  /missions/
  /supplies/
  /abilities/
/tests/
/playtesting/
```

---

## 12. Coding conventions

- One `Resource` script per data concept (§5); no ad-hoc dictionaries for anything that will need author-side tuning.
- Signals over polling for cross-system communication (§4); direct node references are acceptable within one scene's own UI subtree.
- Reusable interface elements with repeated structure, such as mission cards, are separate scenes rather than six manually duplicated hierarchies.
- Fixed menu destinations use `change_scene_to_file()` rather than reciprocal exported `PackedScene` fields, preventing circular serialized scene dependencies.
- Autoloads (§2.1) are the only globally-reachable state; no other singletons added without a reason recorded here.
- Balance numbers are never literals inside a `.gd` file if the GDD defines them; they come from `UpgradeCatalog` or a `Def` resource.
- If the team grows past Milestone 1, each system in §3 gets an owner in the same way GDD sections do (GDD §12.3); the signal-based structure above was chosen partly so a new team member can own one system without needing to understand the others first.

---

## 13. Open questions (carried from the GDD)

- GDD §6.3 flags that the Mission-1 onboarding callouts (§5.1) and first-enemy callouts (§2.7) may be the same feature described twice. This needs a single implementation decision before HUD/onboarding code is written, not after.
- Whether the 5-kill Combo-to-ability threshold should be data-driven/upgradeable later (currently fixed per GDD §2.2.3). The architecture above already treats it as a constant read from one place, so making it upgradeable later is a small change, not a rewrite, if the answer turns out to be yes.

---

## 14. AI use declaration

This Tech Spec was drafted collaboratively with Claude (Anthropic), per the CGRA 359 AI Assistance Policy, translating the GDD's existing systems (§2.2.x, §10) into an architecture/implementation-level document. The architecture choices (signal-based systems, single UpgradeCatalog source of truth, data-driven resources) are proposals for review, not fixed: same standing test as the GDD, any section should be defensible out loud, without notice.
