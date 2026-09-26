# Dead Keys: Technical Design Document (Tech Spec)

| | |
|---|---|
| **Team** | Dead Keys (four members from Milestone 2, see GDD header) |
| **Engine / platform** | Godot 4.7 (GDScript) / Windows, Linux (primary), macOS (secondary) |
| **Companion doc** | `GDD.md`. This document does not restate gameplay numbers; it references them, following Lecture 3, "Reading and Writing GDDs." |
| **Repo** | https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys |
| **Doc version** | v0.4 |
| **Last updated** | 2026-09-26 |

## Changelog

| Version | Date | Change | Who |
|---|---|---|---|
| v0.1 | 2026-07-15 | Initial Tech Spec: architecture, system breakdown, data formats, save schema, CI, performance budgets, risk register | Romart Danganan |
| v0.2 | 2026-07-29 | Added the implemented Main Menu and Operations Hub scene architecture, reusable MissionCard component, image placeholders, menu navigation approach, current repository structure, and Issue #6 UI behaviour. | Romart Danganan |
| v0.3 | 2026-08-24 | Milestone 2/3 documentation sync (#16, overdue from Milestone 2). §2.1 autoloads rewritten to match what actually exists (`UpgradeState`/`AbilityState`/`SupplyState`, not the originally planned `GameState`/`SaveSystem`/`AudioBus`), with the Catalog-as-static-class architecture decision documented. §3 system entries renamed/corrected to match actual code (`AbilitySystem`→`AbilityState`, `SupplyController`→`SupplyState` + `gameplay_prototype.gd`, `Weapon`→`WeaponController`), and flagged the AmmoSystem word-length-scaling gap as a known prototype limitation, not a GDD change. §4 signal map and §5 data formats corrected to match real signal names/signatures and real resource types (the planned `UpgradeDef`/`SupplyDef`/`AbilityDef` `.tres` files and `word_length_to_bullets` table were never built). §7 Testing strategy updated to reflect GUT actually being set up (#34), not just planned: replaced the planned test-target list with what's actually implemented, including catalog/state systems (`UpgradeCatalog`, `AbilityCatalog`, `SupplyCatalog`, `SupplyState`) that didn't exist when this section was first written. | Romart Danganan |
| v0.4 | 2026-09-26 | Sprint 5 documentation sync (#51). §2.1 autoloads rewritten again: `UpgradeState` was replaced by Nicole's `ProgressionManager` (#26), and the `Audio` autoload (#40) exists; `SettingsState` noted as arriving with #46. §3 updated for the current code: AmmoSystem word-length gap closed (#50), Combo counter implemented inside `MistakeSystem`, all four abilities handled in `WeaponController`, gameplay scene is now `mission_1.gd` (#42), Medic `SUPPORT` state on `Zombie` (#39). §4 signal map combo rows are no longer planned. §5/§6 save format corrected from the planned JSON file to the `ConfigFile` saves that actually ship. §7 test list updated with the current GUT files. | Romart Danganan |


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

*Note: this table originally described the planned architecture before implementation began. Updated (#16) to reflect what actually exists; see the changelog entry below for what changed and why.*

| Autoload | Responsibility |
|---|---|
| `ProgressionManager` | Gold, purchased Upgrade Track levels, owned abilities and the highest unlocked mission (#26). Exposes `get_gold()`, `add_gold()`, `spend_gold()`, `get_upgrade_level()`, `get_upgrade_value()`, `purchase_upgrade()`, `is_ability_owned()`. Saves to `user://progression.cfg` (see §6). Replaced the temporary `UpgradeState` autoload from #25. `highest_unlocked` is stored but not yet read by the Home Base, that wiring is #32. |
| `AbilityState` | The currently equipped ability and the current mission's charge flag (#24). Exposes `equip()`, `set_charged()`, `consume_charge()`, `reset_for_mission()`. `MistakeSystem`'s Combo counter calls `set_charged(true)` at 5 kills. |
| `SupplyState` | The 3-slot Mission Supplies loadout (#29). Exposes `get_slot()`, `purchase_into_slot()`, `sell_slot()`, `clear_loadout()`. Spends from `ProgressionManager`'s gold, the same pool as Upgrades. |
| `Audio` | Music and SFX playback (`audio_bus.gd`, #40). Exposes `play()`, `clear_music()`, `is_playing()`, and bus volume helpers used by the Settings menu. |
| `SettingsState` | Arrives with the Settings menu (#46, in review): volumes, mistake-system toggle, window mode/resolution, and fire/supply key bindings, saved to `user://settings.cfg`. |

**Architecture change from the original plan:** upgrade/ability/supply *definitions* (costs, effect values, display names) turned out simpler as static data tables (`UpgradeCatalog`, `AbilityCatalog`, `SupplyCatalog`, plain `RefCounted` classes under `scripts/resources/`, not autoloads, not `.tres` resources) rather than the originally planned per-item `.tres` Resources loaded by an autoload. This was a pragmatic implementation call made while actually building #24/#25/#29, not a deliberate GDD-level redesign: it avoids needing a resource-authoring workflow for content that's currently small and code-defined anyway. Each Catalog exposes lookup functions (e.g. `UpgradeCatalog.get_track(id)`) that the equivalent *state* autoload above calls into. This keeps the door open to migrating to real `.tres` resources later without changing how any consumer calls in, only how the Catalog itself is implemented internally.

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
Captures `InputEventKey`, resolved through the OS keyboard layout (not raw physical scancode; this is the GDD §10 flagged risk). Matches typed characters against a shared typed-prefix across all currently-active targets (Zombies and, since #29, Supply crates), not a single target's word buffer as originally scoped, needed once multiple simultaneous Zombies had to share one input stream (#22). Emits `typing_mistake`, `correct_stroke`, `word_completed(word, ammunition_reward)`, `supply_word_completed(crate, word)`.

### 3.2 AmmoSystem
Listens to `word_completed` (via `mission_1.gd`). The reward amount is decided in `TypingController.get_ammo_reward_for_word()`, a static function mapping word length to bullet count per GDD §2.2.1 (#50, closing the flat-1-ammo gap flagged in v0.3). Adds to the ammo pool, capped at the Magazine Capacity upgrade value from `ProgressionManager`. Emits `ammunition_changed(current, maximum)`.

### 3.3 MistakeSystem
Listens to `typing_mistake` (emitted by `TypingController`). The GDD's accessibility toggle (§2.2.2/§2.8) is `SettingsState.mistake_system_enabled`, arriving with #46; when off, `_typing_mistake()` returns early. Otherwise: decrements ammo (unless already 0, still building toward the jam), increments a consecutive-mistake counter, triggers a jam at 3 consecutive mistakes (Mistake Leniency upgrade delays *when* ammo is lost, not the jam threshold itself, an interpretation of the GDD's upgrade table flagged for review during #25), starts a jam timer (the Jam Duration upgrade value) during which firing is a no-op. Also owns the Combo counter, see §3.4.

### 3.4 Combo counter (inside MistakeSystem)
Built as part of `mistake_system.gd` rather than a separate `ComboSystem` node, since both react to the same typing signals. `combo` increments when a target is unregistered (a kill), and `combo_reset()` sets it to 0 on a mistake or when a zombie's `wall_contact` signal fires. At `COMBO_MAX` (5) it calls `AbilityState.set_charged(true)`; the charge lives in `AbilityState` and survives later combo resets (GDD §2.2.3 edge case). A leftover debug key in `mission_1.gd` can still force a charge and should be removed before submission.

### 3.5 AbilitySystem
Implemented as the `AbilityState` autoload plus effect-specific logic in the consuming system (currently just `WeaponController` for Spread Shot), rather than a dedicated `AbilitySystem` node. All four launch abilities (Spread Shot #24, Ricochet #36, Freeze Round #37, Piercing Shot #38) are handled as branches in `WeaponController.try_fire()`. Holds the equipped ability id (set pre-mission via the Ability Select screen, immutable once a mission loads, enforced structurally since there's no in-mission path back to that screen rather than a separate runtime lock flag) and a charge bool. `WeaponController.try_fire()` checks `AbilityState.is_charged` and consumes it via `AbilityState.consume_charge()` on the next shot. Charge resets to false at mission start (`AbilityState.reset_for_mission()`), so nothing carries between missions.

### 3.6 SupplyState (renamed from the originally planned SupplyController)
Loadout selection lives in the `SupplyState` autoload (see §2.1); the call/spawn/claim flow itself lives directly in `mission_1.gd` (renamed from `gameplay_prototype.gd` in #42) rather than a separate node, since there's currently only one gameplay scene to wire it into. On Supply input (keys 1–3, real input actions, not debug-only): if the selected slot contains a supply, no crate is currently active, and that slot hasn't already been used this mission, starts a 3 s countdown (shown on-HUD, not silent) then spawns a `SupplyCrate` at the arena's fixed `SupplyLandingPoint` `Marker2D`. The crate registers with `TypingController` the same way a `Zombie` does (shared word pool, shared collision-avoidance), an 8 s `Timer` on the crate itself handles expiry. On claim, applies the crate's effect (GDD §2.2.4) directly in `mission_1.gd`. There is no collision-based removal path; this was cut from the GDD and there is no code path for it.

### 3.7 ZombieManager / Zombie
One shared state machine (Spawn → Approach → Attack → Dead) implemented once in `Zombie.gd`. Per-type extra behaviour (Medic/Spitter/Commander/Exploder) is an optional attached component node rather than a subclass, so adding a new special behaviour later is "attach a component," not "branch the class hierarchy." In practice the Medic (#39) was added as an extra `SUPPORT` state inside `zombie.gd` plus `heal_per_second`/`support_radius` fields on `EnemyTypeDef`, and Freeze Round added a `FROZEN` state the same way. Zombies are pooled (`zombie_pool.gd`, #28). Separation/flocking (GDD §8.1) is not built yet. Stats (health, speed, word-pool tag) come from an `EnemyType` resource (§5), so balancing is a data edit.

### 3.8 WordLabelManager
Positions and z-orders floating word labels above zombies. Implements the GDD §2.2.1 overlap rule: label priority goes to whichever zombie is closest to the wall; when multiple zombies are equidistant, labels are staggered/offset rather than any being fully hidden. This is implemented as a simple sort-by-distance-to-wall each frame, with a minimum on-screen offset enforced between any two labels whose bounding boxes would otherwise intersect.

### 3.9 WeaponController (renamed from the originally planned Weapon)
Handles Fire input, cooldown timer, damage application on hit. Reads Fire Rate and Bullet Damage from `ProgressionManager` (which resolves the current value via `UpgradeCatalog`) rather than owning its own copy of either number. Also handles all four ability effects (§3.5) directly when `AbilityState.is_charged`.

### 3.10 UpgradeCatalog / AbilityCatalog / SupplyCatalog (detailed)
The single place each turns "id + purchased level" into "current effective value" (`UpgradeCatalog`), or looks up a display definition (`AbilityCatalog`, `SupplyCatalog`). Every gameplay system asks one of these instead of hard-coding a number, which is what keeps the GDD's upgrade table (§2.6.1) and the Mission Supplies effects table (§2.2.4) as the actual source of truth. See §2.1 for why these are static classes rather than autoloads.

### 3.11 Saving
There is no separate SaveSystem; `ProgressionManager` saves itself with Godot's `ConfigFile` when a mission is completed and after shop purchases (never mid-mission, matching GDD §2.8). See §6.

### 3.12 ProgressionManager
See §2.1. Stores `highest_unlocked` for linear unlocks (GDD §2.7); the Home Base still launches Mission 1 directly until #32 wires cards to it. Best medals are not stored yet because mission ratings do not exist.

### 3.13 Main Menu and Operations Hub UI

`main_menu.tscn` is the project main scene. Its background and logo are `TextureRect` placeholders so final illustrated assets can replace the temporary textures without changing the layout. Start changes to `home_base.tscn`, Settings remains a placeholder until its dedicated issue, and Quit closes the scene tree.

`home_base.tscn` implements the Operations Hub layout defined in GDD §3 and §6.1. It contains a replaceable Hub background/logo, gold display with a replaceable coin icon, placeholder access panels for Upgrades, Mission Supplies, and Ability Loadout, a six-card mission grid, and a selected-mission details panel. The details panel repeats the selected mission's image and displays its title, description, best medal, and launch control. Mission 1 begins unlocked; Missions 2–6 are disabled placeholders until progression and saving are implemented.

Navigation between `main_menu.tscn` and `home_base.tscn` uses `SceneTree.change_scene_to_file()` with fixed `res://` paths. The scenes do not export `PackedScene` references to each other, because reciprocal serialized scene references create a circular resource dependency.

### 3.14 MissionCard UI component

`mission_card.tscn` is a reusable `Button` scene backed by `mission_card.gd` (`class_name MissionCard`). Exported properties currently provide the mission id, name, description, image, best medal, and locked state. Its image and title ignore mouse input so the parent button receives the click. A locked card displays an overlay and disables the root button. Selecting an unlocked card sends its exported display data to the Operations Hub details panel.

The current exported properties are suitable for the UI prototype. When `MissionConfigDef` resources are implemented, the card should receive or reference mission data from those resources rather than becoming a second long-term source of mission content.

---

## 4. Signal map (summary)

*Updated v0.4: the Combo rows are now built (inside `MistakeSystem`), so nothing in this table is planned-only any more.*

| Signal | Emitted by | Consumed by |
|---|---|---|
| `typing_mistake` / `correct_stroke` | TypingController | MistakeSystem |
| `word_completed(word, ammunition_reward)` | TypingController | `mission_1.gd` (adds to AmmoSystem) |
| `supply_word_completed(crate, word)` | TypingController | `mission_1.gd` (claims the crate) |
| `ammunition_changed(current, maximum)` | AmmoSystem | HUD |
| `wall_contact()` | Zombie (reaches the wall) | `MistakeSystem.combo_reset()` |
| `charged_changed(is_charged)` | AbilityState | HUD |
| `wall_hit(damage)` | Zombie (Attack state) | `mission_1.gd` |
| `gold_changed(new_gold)` | ProgressionManager | Home Base and shop UIs |
| `wave_started(wave_number, is_final_wave)` / `all_waves_cleared` | ZombieManager | `mission_1.gd` (wave banner, mission complete) |
| `died(zombie)` | Zombie (on lethal hit) | ZombieManager, TypingController (unregisters the target) |
| `pressed()` | MissionCard instance | HomeBase mission-details controller |

---

## 5. Data & resource formats

Actually-built content is an external `.tres` Resource where noted below. Upgrade/Ability/Supply *definitions* are the one deliberate exception, see §2.1's architecture-change note, they're static data tables in code rather than `.tres` files for now.

| Resource | Fields | Used by |
|---|---|---|
| `EnemyTypeDef.tres` | health, speed, word-pool tag, special-behaviour tag (optional) | Zombie.gd |
| `MissionConfigDef` / `WaveEntry` | mission id, waves (enemy type, count, spawn interval, start delay), base coin reward | ZombieManager |
| `UpgradeCatalog`, `AbilityCatalog`, `SupplyCatalog` | static tables: id, display name, cost/level or per-level effect value (`scripts/resources/`) | `ProgressionManager`, `AbilityState`, `SupplyState` |
| Word list JSON | `theme`, `words` array (`resources/word_lists/`) | `TypingController` |

The word list is currently a single placeholder file; the per-mission system with length buckets is #43. The word length to bullet count mapping is a small static function (§3.2) rather than a data table, since the tiers come straight from GDD §2.2.1.

---

## 6. Save file schema

Checkpoint-based, one write per completed mission (GDD §2.8). The original plan was a single JSON file; what shipped is Godot `ConfigFile` saves, which handle Dictionaries without a custom serializer. Progression and settings are separate files so resetting one never wipes the other.

`user://progression.cfg`, section `[progression]`:

```ini
gold=0
upgrade_levels={ "fire_rate": 0, "magazine_capacity": 1 }
highest_unlocked=1
owned_abilities={ "spread_shot": true }
```

`user://settings.cfg` (arrives with #46): volumes, `mistake_system_enabled`, window mode, resolution, and key bindings.

Upgrade levels are stored as integers (current level per track); `UpgradeCatalog` resolves the integer to an effect value, so the save file never stores a balance number directly, only "how many levels bought." Keys must match between `save_progression()` and `load_progression()`, a mismatch silently falls back to the default instead of erroring. Best medals per mission are not stored yet.

---

## 7. Testing strategy

Godot Unit Test (GUT) is set up (#34), not just planned, GUT is installed as an editor addon, `.gutconfig.json` configures the runner, and tests live in `tests/unit/`. See `README.md` for how to run them.

Current coverage, prioritised the same way originally planned, by how pure/logic-only each system is:

1. **AmmoSystem**: capacity clamping, add/consume edge cases, empty/full state.
2. **MistakeSystem**: 3-mistake jam trigger, jam-during-jam edge case (#20), Mistake Leniency threshold.
3. **UpgradeCatalog, AbilityCatalog, SupplyCatalog**: data-table lookups (level values, costs, max levels), not anticipated when this section was first written, since these systems (#24/#25/#29) didn't exist yet.
4. **SupplyState**: purchase/sell/refund logic, slot-occupancy rules, including the overwrite-prevention fix found during #29's manual testing.
5. **Zombie freeze** (`test_zombie_freeze.gd`, #37): Freeze Round state entry and recovery.
6. **Ammo reward tiers** (`test_ammo_reward.gd`, #50): word length to bullet count, including tier boundaries.

Isolated enemy test scenes (for example the Medic healing test, #39) live under `tests/zombies/`. Not yet covered by GUT: the Combo counter and anything mission-flow-level (covered instead by manual tests under `tests/manual/`, per the existing convention).

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
  /unit/                    (GUT unit tests, #34)
  /manual/                  (dated manual test records)
  /zombies/                 (William's isolated enemy test scenes)
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
