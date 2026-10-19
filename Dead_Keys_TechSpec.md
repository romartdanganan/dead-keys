# Dead Keys: Technical Design Document (Tech Spec)

| | |
|---|---|
| **Team** | Dead Keys (four members from Milestone 2, see GDD header) |
| **Engine / platform** | Godot 4.7 (GDScript) / Windows, Linux (primary), macOS (secondary) |
| **Companion doc** | `GDD.md`. This document does not restate gameplay numbers; it references them, following Lecture 3, "Reading and Writing GDDs." |
| **Repo** | https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys |
| **Doc version** | v0.7 |
| **Last updated** | 2026-10-17 |

## Changelog

| Version | Date | Change | Who |
|---|---|---|---|
| v0.1 | 2026-07-15 | Initial Tech Spec: architecture, system breakdown, data formats, save schema, CI, performance budgets, risk register | Romart Danganan |
| v0.2 | 2026-07-29 | Added the implemented Main Menu and Operations Hub scene architecture, reusable MissionCard component, image placeholders, menu navigation approach, current repository structure, and Issue #6 UI behaviour. | Romart Danganan |
| v0.3 | 2026-08-24 | Milestone 2/3 documentation sync (#16, overdue from Milestone 2). §2.1 autoloads rewritten to match what actually exists (`UpgradeState`/`AbilityState`/`SupplyState`, not the originally planned `GameState`/`SaveSystem`/`AudioBus`), with the Catalog-as-static-class architecture decision documented. §3 system entries renamed/corrected to match actual code (`AbilitySystem`→`AbilityState`, `SupplyController`→`SupplyState` + `gameplay_prototype.gd`, `Weapon`→`WeaponController`), and flagged the AmmoSystem word-length-scaling gap as a known prototype limitation, not a GDD change. §4 signal map and §5 data formats corrected to match real signal names/signatures and real resource types (the planned `UpgradeDef`/`SupplyDef`/`AbilityDef` `.tres` files and `word_length_to_bullets` table were never built). §7 Testing strategy updated to reflect GUT actually being set up (#34), not just planned: replaced the planned test-target list with what's actually implemented, including catalog/state systems (`UpgradeCatalog`, `AbilityCatalog`, `SupplyCatalog`, `SupplyState`) that didn't exist when this section was first written. | Romart Danganan |
| v0.4 | 2026-09-26 | Sprint 5 documentation sync (#51). §2.1 autoloads rewritten again: `UpgradeState` was replaced by Nicole's `ProgressionManager` (#26), and the `Audio` autoload (#40) exists; `SettingsState` noted as arriving with #46. §3 updated for the current code: AmmoSystem word-length gap closed (#50), Combo counter implemented inside `MistakeSystem`, all four abilities handled in `WeaponController`, gameplay scene is now `mission_1.gd` (#42), Medic `SUPPORT` state on `Zombie` (#39). §4 signal map combo rows are no longer planned. §5/§6 save format corrected from the planned JSON file to the `ConfigFile` saves that actually ship. §7 test list updated with the current GUT files. | Romart Danganan |
| v0.5 | 2026-10-10 | §5 word list format updated for the per-mission themed word list system (#43); schema documented in `resources/word_lists/README.md`. | Nicole Lai |
| v0.6 | 2026-10-16 | Final sync with the Milestone 3 build. §2.1 autoloads (`SettingsState` and `TutorialState` added, `ProgressionManager` now reads `highest_unlocked` and stores best medals). §2.2 scene tree replaced with the real mission scene and the feature-node pattern. §3 updated for the word-based combo and ability input (#64), all eight abilities (#54), edge spawning and equal ring arrival (#63, #71), the barrier ring (#55), pooled death animations, missions as inherited scenes, the boss fight (#67), Endless mode (#68), medals and WPM (#65, #68), settings and accessibility (#46, #66). The unbuilt WordLabelManager is marked as not built. §4 signal map, §6 save files and §7 test list updated (299 tests). §9 and §10 record what was learnt, including the physics callback rule behind #69. | Romart Danganan |
| v0.7 | 2026-10-17 | Consistency pass before submission. §0 describes the four person team, §2.2 lists every Main Menu button, §3 uses the 5 word combo, §3.6 adds the 12 s crate timer option, §3.14 notes `MissionConfigDef` is built in code, §10 records that the bandwidth risk happened, §11 shows the real folder layout. | Romart Danganan |

---

## 0. Purpose & scope

The GDD answers *what* the game is and *why* a rule exists. This document answers *how it gets built*: architecture, node/scene layout, data formats, save schema, tooling, and risk. Where a number is gameplay-facing (fire rate, damage, costs, timers), it is defined once in the GDD and only referenced here by name. This document should never need its own copy of a balance number, so the two docs can't drift apart.

The project was solo at Milestone 1 and a team of four from Milestone 2, so the architecture favours simplicity (signals plus a few autoloads) over a large abstraction layer. That kept the codebase easy to hold in your head and let each teammate own one system without needing to understand the others first.

---

## 1. Engine & platform

Godot 4.7, GDScript only (no C#/GDExtension this trimester, since that's one less toolchain to maintain if the team stays small). Export targets: Windows and Linux desktop as primary, macOS as secondary (build it, but don't spend debug time on Mac-only issues unless time allows). Minimum spec target is low by design (no 3D lighting, no large streamed assets, see GDD §10), so no special GPU-tier testing matrix is needed.

---

## 2. High-level architecture

### 2.1 Autoload singletons (global, persist across scenes)

*Note: this table originally described the planned architecture before implementation began. Updated (#16) to reflect what actually exists; see the changelog entry below for what changed and why.*

| Autoload | Responsibility |
|---|---|
| `ProgressionManager` | Gold, purchased Upgrade Track levels, owned abilities, the highest unlocked mission and best medals (#26, #32, #65). Exposes `get_gold()`, `add_gold()`, `spend_gold()`, `get_upgrade_level()`, `get_upgrade_value()`, `purchase_upgrade()`, `is_ability_owned()`, `purchase_ability()`, `is_mission_unlocked()`, `unlock_next_mission()`, `get_best_medal()`, `set_best_medal()`. Saves to `user://progression.cfg` (see §6). Replaced the temporary `UpgradeState` autoload from #25. |
| `AbilityState` | The currently equipped ability and the current mission's charge flag (#24). Exposes `equip()`, `set_charged()`, `consume_charge()`, `reset_for_mission()`. `MistakeSystem`'s Combo counter calls `set_charged(true)` after 5 typed words in a row (#64). |
| `SupplyState` | The 3-slot Mission Supplies loadout (#29). Exposes `get_slot()`, `purchase_into_slot()`, `sell_slot()`, `clear_loadout()`. Spends from `ProgressionManager`'s gold, the same pool as Upgrades. |
| `Audio` | Music and SFX playback (`audio_bus.gd`, Josiah, #40, #57). Exposes `play()`, `clear_music()`, `clear_sounds()`, `is_playing()`. Music and SFX buses and `set_bus_volume()`/`get_bus_volume()` were added for the Settings sliders (#46). |
| `SettingsState` | Volumes, mistake penalty toggle, window mode and resolution, accessibility options (zombie speed, longer crate timer, large word text, hold to fire, reduce flashing, reduce screen shake) and the Fire, Use Ability and supply key bindings (#46, #64, #66, #67). Saves to `user://settings.cfg` and re-applies bindings to `InputMap` on load. |
| `TutorialState` | Which tutorial and new enemy callouts this save has already shown (#60). Saves to `user://tutorial.cfg`. |

**Architecture change from the original plan:** upgrade/ability/supply *definitions* (costs, effect values, display names) turned out simpler as static data tables (`UpgradeCatalog`, `AbilityCatalog`, `SupplyCatalog`, plain `RefCounted` classes under `scripts/resources/`, not autoloads, not `.tres` resources) rather than the originally planned per-item `.tres` Resources loaded by an autoload. This was a pragmatic implementation call made while actually building #24/#25/#29, not a deliberate GDD-level redesign: it avoids needing a resource-authoring workflow for content that's currently small and code-defined anyway. Each Catalog exposes lookup functions (e.g. `UpgradeCatalog.get_track(id)`) that the equivalent *state* autoload above calls into. This keeps the door open to migrating to real `.tres` resources later without changing how any consumer calls in, only how the Catalog itself is implemented internally.

Everything else is scene-local. There are no other cross-scene singletons, to keep the codebase easy to hold in your head and easy to onboard a recruit into, whether or not that happens this trimester.

### 2.2 Scene tree overview

```
scenes/ui/main_menu.tscn
 ├─ replaceable background TextureRect
 ├─ replaceable logo TextureRect
 └─ Start / Endless Mode / How to Play / Settings / Quit controls

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

scenes/missions/mission_1.tscn   (base mission, script mission_1.gd)
 ├─ Camera (Camera2D, screen_shake.gd)
 ├─ BackgroundColour / Background
 ├─ World
 │   ├─ WallAttackLine (base centre), BarrierRing (barrier_ring.gd)
 │   ├─ WeaponController + MuzzlePoint, ProjectileContainer
 │   └─ SupplyLandingPoint, SupplyContainer
 ├─ AmmoSystem, TypingController, MistakeSystem, StatusTimer
 ├─ HUD (CanvasLayer: wall, lives, mission name, ammo, ability and combo, supply slots)
 └─ WaveAnnouncement
   added in code at mission start (logic only, nothing to lay out):
   ZombieManager, TutorialCallouts, CombatFeedback, HudWarnings, BossFight,
   WaveCounter and BossHealthBar scenes

scenes/missions/mission_2.tscn, mission_3.tscn, endless.tscn
   inherited scenes of mission_1.tscn: override the script, background and word list only

overlays (CanvasLayer, instanced on demand, process_mode always so they work while paused)
   pause_menu.tscn (layer 10), settings_menu.tscn (11), how_to_play.tscn (12),
   mission_success_overlay.tscn, mission_fail_overlay.tscn, endless_game_over.tscn,
   tutorial_callout.tscn (layer 4)
```

Communication between sibling systems is via **signals**, not direct references, so any system can be unit-tested in isolation (see §7).

**Feature-node pattern (sprint 6 onward).** Newer mission features are their own node with a `setup(...)` function that takes exactly the systems it needs (`combat_feedback.gd`, `tutorial_callouts.gd`, `hud_warnings.gd`, `boss_fight.gd`). `mission_1.gd` only adds a short hook for each. This keeps merge conflicts small when several people edit the mission, and lets GUT drive each feature with real signals without building a mission scene.

---

## 3. System-by-system breakdown

Each entry maps 1:1 to a GDD §2.2.x system. Numbers referenced (e.g. the 5 word combo threshold) live in the GDD; only the *mechanism* is specified here.

### 3.1 TypingController
Captures `InputEventKey`, resolved through the OS keyboard layout (not raw physical scancode; this is the GDD §10 flagged risk). Matches typed characters against a shared typed-prefix across all currently-active targets (Zombies and, since #29, Supply crates), not a single target's word buffer as originally scoped, needed once multiple simultaneous Zombies had to share one input stream (#22). Emits `typing_mistake`, `correct_stroke`, `word_completed(word, ammunition_reward)`, `supply_word_completed(crate, word)`.

### 3.2 AmmoSystem
Listens to `word_completed` (via `mission_1.gd`). The reward amount is decided in `TypingController.get_ammo_reward_for_word()`, a static function mapping word length to bullet count per GDD §2.2.1 (#50, closing the flat-1-ammo gap flagged in v0.3). Adds to the ammo pool, capped at the Magazine Capacity upgrade value from `ProgressionManager`. Emits `ammunition_changed(current, maximum)`.

### 3.3 MistakeSystem
Listens to `typing_mistake` (emitted by `TypingController`). The GDD's accessibility toggle (§2.2.2/§2.8) is `SettingsState.mistake_system_enabled`, arriving with #46; when off, `_typing_mistake()` returns early. Otherwise: decrements ammo (unless already 0, still building toward the jam), increments a consecutive-mistake counter, triggers a jam at 3 consecutive mistakes (Mistake Leniency upgrade delays *when* ammo is lost, not the jam threshold itself, an interpretation of the GDD's upgrade table flagged for review during #25), starts a jam timer (the Jam Duration upgrade value) during which firing is a no-op. Also owns the Combo counter, see §3.4.

### 3.4 Combo counter (inside MistakeSystem)
Built as part of `mistake_system.gd` rather than a separate `ComboSystem` node, since both react to the same typing signals. Since #64 the combo counts `word_completed` and `supply_word_completed` (typed words), not kills. `combo_reset()` sets it to 0 on a mistake or when a zombie's `wall_contact` signal fires. At `COMBO_MAX` (5) it calls `AbilityState.set_charged(true)` and pauses until `AbilityState.charged_changed` reports the charge was used, so charges never stack. Debug keys only work when `OS.is_debug_build()` (#59).

### 3.5 AbilitySystem
Implemented as the `AbilityState` autoload plus effect logic in `WeaponController` and `Projectile`, rather than a dedicated `AbilitySystem` node. `WeaponController.try_fire()` is a normal shot; `try_fire_ability()` runs on the separate `use_ability` input, needs a charge, and picks the equipped ability with a `match` (#64). Both share `_take_shot()`, which holds every check (scene set up, not jammed, off cooldown, ammo). Each ability sets flags and numbers on the spawned `Projectile` (bounces, pierce, freeze radius, explosion radius, homing, shockwave), and the projectile applies them on hit. Ricochet and Homing only target on-screen zombies (sprite rect against the visible rect), and area effects measure from the projectile, not the hit zombie, because a killed pooled zombie has already been moved off screen. The equipped ability is immutable once a mission loads (there is no in-mission path back to Ability Select), and the charge resets at mission start.

### 3.6 SupplyState (renamed from the originally planned SupplyController)
Loadout selection lives in the `SupplyState` autoload (see §2.1); the call/spawn/claim flow itself lives directly in `mission_1.gd` (renamed from `gameplay_prototype.gd` in #42) rather than a separate node, since there's currently only one gameplay scene to wire it into. On Supply input (keys 1 to 3, real input actions, not debug-only): if the selected slot contains a supply, no crate is currently active, and that slot hasn't already been used this mission, starts a 3 s countdown (shown on-HUD, not silent) then spawns a `SupplyCrate` at the arena's fixed `SupplyLandingPoint` `Marker2D`. The crate registers with `TypingController` the same way a `Zombie` does (shared word pool, shared collision-avoidance), an 8 s `Timer` on the crate itself (12 s with Longer Crate Timer) handles expiry. On claim, applies the crate's effect (GDD §2.2.4) directly in `mission_1.gd`. There is no collision-based removal path; this was cut from the GDD and there is no code path for it.

### 3.7 ZombieManager / Zombie
One shared state machine in `zombie.gd` (William): SPAWN, APPROACH, ATTACK, SUPPORT (Medic heal, Commander buff), FROZEN and DEAD. Every type is an `EnemyTypeDef` resource, so balancing is a data edit. Zombies attack from the barrier ring edge (`wall_contact_radius`, #55).

- **Spawning (`zombie_manager.gd`):** `spawn_position()` puts a zombie just past the screen edge along its random direction: the distance to the edge is `min(half_width / |dx|, half_height / |dy|)` plus a 100 px margin (#63). `pick_spawn_angle(side_only)` keeps side-only waves within 45 degrees of horizontal.
- **Equal arrival (#71):** `travel_scale_for()` returns `(distance to centre - ring radius) / reference walk`, where the reference walk is `half_width + 100 - 8` (732 px), the old side walk to the base. `get_movement_speed()` multiplies it with the accessibility speed setting and Commander buffs. `spawn_extra()` (boss helpers) uses 1.0.
- **Pooling and death (#28, #35):** the pool returns the most recently released zombie, so a zombie is released only on `death_finished` (end of its death animation), while `died` fires on the killing hit for kills, typing and wave progress.
- **Art per type:** `animation_prefix` and `art_faces_right` on `EnemyTypeDef` pick the cat or dog animations; every animation keys its own sprite sheet, so a recycled zombie can change type. Facing flips by which side of the base the zombie is on.
- **Physics rule (#69):** collision shapes are changed with `set_deferred()`, because death can happen inside a projectile's `area_entered` callback where physics state cannot change.
- **Medic heal delay:** `seconds_since_damaged` resets in `take_damage()`; healing waits for `heal_delay` (2 s).
- Separation/flocking was not built.

### 3.8 WordLabelManager (not built)
The planned overlap and priority manager was not built. Each zombie's `WordLabel` (a `RichTextLabel` with a raised `z_index`) is styled on spawn by `word_label_style.gd`, which sets the font size (22 px, or 30 px with Large Word Text), keeps the label's bottom edge fixed and grows it up and wider. It is idempotent so pooled zombies can be restyled every spawn. Overlap is reduced by spawning instead (§3.7); playtest #3 measured 12% overlap in Mission 2 and 0% elsewhere.

### 3.9 WeaponController (renamed from the originally planned Weapon)
Handles Fire input, cooldown timer, damage application on hit. Reads Fire Rate and Bullet Damage from `ProgressionManager` (which resolves the current value via `UpgradeCatalog`) rather than owning its own copy of either number. Also starts all eight ability shots (§3.5) through `try_fire_ability()`.

### 3.10 UpgradeCatalog / AbilityCatalog / SupplyCatalog (detailed)
The single place each turns "id + purchased level" into "current effective value" (`UpgradeCatalog`), or looks up a display definition (`AbilityCatalog`, `SupplyCatalog`). Every gameplay system asks one of these instead of hard-coding a number, which is what keeps the GDD's upgrade table (§2.6.1) and the Mission Supplies effects table (§2.2.4) as the actual source of truth. See §2.1 for why these are static classes rather than autoloads.

### 3.11 Saving
There is no separate SaveSystem; `ProgressionManager` saves itself with Godot's `ConfigFile` when a mission is completed and after shop purchases (never mid-mission, matching GDD §2.8). See §6.

### 3.12 ProgressionManager
See §2.1. Home Base cards lock and unlock from `is_mission_unlocked()` (#32); `mission_catalog.gd` maps a mission number to its scene path so Home Base and Next Mission never hard-code `mission_1.tscn`. Best medals are stored per mission and only replaced by a better one.

### 3.12.1 Missions
`mission_1.gd` is the base mission: lives, wall, waves, supplies, pause, settings, win and lose, medals and hold to fire. Missions 2 and 3 and Endless extend it and override `_build_mission_config()` (and `mission_number` in `_init()`). Their scenes inherit `mission_1.tscn`, so HUD changes reach every mission.

### 3.12.2 Boss fight (`boss_fight.gd`, #67)
Watches `zombie_spawned` for an enemy id in the boss list, then works on a duplicated `EnemyTypeDef` so changing the Tank's speed never edits the shared `tank.tres`. Phase changes come from the boss's `damaged` signal. Summons and the roar ring are created with `call_deferred()` because they happen inside a bullet hit. The finale is a small stage counter in `_process()` using real time (`delta / Engine.time_scale`) instead of awaited timers, so quitting mid cinematic leaves nothing waiting, and `_exit_tree()` always restores `Engine.time_scale`. Camera focus and zoom use real-time tweens clamped so the zoom never shows past the screen.

### 3.12.3 Endless mode (#68)
`endless_mission.gd` extends `mission_1.gd`; `endless_waves.gd` builds each round from the round number; `endless_scores.gd` keeps the top 5 in `user://endless_scores.cfg`. The game over screen is its own scene (`endless_game_over.tscn`): a fade and pop in (`TRANS_BACK`), a `tween_method` score count-up, BEST beside the score, and dashes for accuracy and WPM if the player never typed.

### 3.12.4 Rating and WPM (`mission_rating.gd`, #65, #68)
A `RefCounted` that listens to `correct_stroke` and `typing_mistake`. `grade()` is a pure static function. WPM times only the gaps between keys inside a word, one character per gap, skips gaps over 1.5 s, ends a word on the same signals the typing controller uses to clear its prefix, and uses `Time.get_ticks_usec()` so slow motion does not affect it. `record_correct_stroke()` takes the timestamp as an argument so tests can feed exact times.

### 3.13 Main Menu and Operations Hub UI

`main_menu.tscn` is the project main scene, with the illustrated background and logo, and Start, Endless Mode, How to Play, Settings and Quit. Start changes to `home_base.tscn`, Endless Mode loads `endless.tscn`, How to Play and Settings open as overlays, and Quit closes the scene tree.

`home_base.tscn` implements the Operations Hub layout defined in GDD §3 and §6.1. It contains a replaceable Hub background/logo, gold display with a replaceable coin icon, placeholder access panels for Upgrades, Mission Supplies, and Ability Loadout, a six-card mission grid, and a selected-mission details panel. The details panel repeats the selected mission's image and displays its title, description, best medal, and launch control. Mission 1 begins unlocked and each win unlocks the next (#32); Missions 4 to 6 stay locked because they were cut. The details panel shows the saved best medal as a sprite (#65).

Navigation between `main_menu.tscn` and `home_base.tscn` uses `SceneTree.change_scene_to_file()` with fixed `res://` paths. The scenes do not export `PackedScene` references to each other, because reciprocal serialized scene references create a circular resource dependency.

### 3.14 MissionCard UI component

`mission_card.tscn` is a reusable `Button` scene backed by `mission_card.gd` (`class_name MissionCard`). Exported properties currently provide the mission id, name, description, image, best medal, and locked state. Its image and title ignore mouse input so the parent button receives the click. A locked card displays an overlay and disables the root button. Selecting an unlocked card sends its exported display data to the Operations Hub details panel.

`MissionConfigDef` is now built in code by each mission script (§3.12.1). If missions move to `.tres` data later, the card should read its title and description from that data rather than becoming a second source of mission content.

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
| `death_finished(zombie)` | Zombie (end of death animation) | ZombieManager (pool release), CombatFeedback (death burst) |
| `damaged(zombie)` | Zombie | CombatFeedback (hit flash), BossFight (phase changes), `mission_1.gd` |
| `zombie_spawned(zombie)` | ZombieManager | `mission_1.gd`, TutorialCallouts, BossFight, BossHealthBar |
| `phase_changed(phase)` / `finale_finished` | BossFight | BossHealthBar, `mission_1.gd` (mission complete) |
| `attempted_fire_without_ammunition` | WeaponController | CombatFeedback (out of ammo prompt) |
| `settings_changed` | SettingsState | open menus and HUD |

---

## 5. Data & resource formats

Actually-built content is an external `.tres` Resource where noted below. Upgrade/Ability/Supply *definitions* are the one deliberate exception, see §2.1's architecture-change note, they're static data tables in code rather than `.tres` files for now.

| Resource | Fields | Used by |
|---|---|---|
| `EnemyTypeDef.tres` | health, speed, word-pool tag, special-behaviour tag (optional) | Zombie.gd |
| `MissionConfigDef` / `WaveEntry` | mission id, waves (enemy type, count, spawn interval, start delay), base coin reward | ZombieManager |
| `UpgradeCatalog`, `AbilityCatalog`, `SupplyCatalog` | static tables: id, display name, cost/level or per-level effect value (`scripts/resources/`) | `ProgressionManager`, `AbilityState`, `SupplyState` |

Words are split into shared theme files that each mission mixes together (#43). Word length buckets reuse the GDD §2.2.1 ammo tiers through `TypingController.get_ammo_reward_for_word()`, and `WaveEntry.allowed_buckets` can narrow them per wave. The full schema is in `resources/word_lists/README_words.md`.


The word length to bullet count mapping is a small static function (§3.2) rather than a data table, since the tiers come straight from GDD §2.2.1. Runners get bucket 1 words and the Tank buckets 3 and 4 through `WaveEntry.allowed_buckets`.

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

`user://progression.cfg` also stores `best_medals` (mission number to medal name).

| File | Contents |
|---|---|
| `user://settings.cfg` | volumes, `mistake_system_enabled`, window mode, resolution, accessibility options, and key bindings for fire, ability and supplies |
| `user://supply_loadout.cfg` | the three equipped supply slots |
| `user://tutorial.cfg` | callout ids already shown |
| `user://endless_scores.cfg` | top 5 Endless scores with their round |

Upgrade levels are stored as integers (current level per track); `UpgradeCatalog` resolves the integer to an effect value, so the save file never stores a balance number directly, only "how many levels bought." Keys must match between `save_progression()` and `load_progression()`, a mismatch silently falls back to the default instead of erroring. On load, `SettingsState` clears old bindings before applying saved ones so swapped keys never clash with the defaults.

---

## 7. Testing strategy

Godot Unit Test (GUT) is set up (#34), not just planned, GUT is installed as an editor addon, `.gutconfig.json` configures the runner, and tests live in `tests/unit/`. See `README.md` for how to run them.

At Milestone 3 there are 299 tests across 33 scripts in `tests/unit/`. They cover: ammo and ammo rewards; the mistake system, jam and word combo; the three catalogs (checked by shape, not by hard-coded ids); ability, supply, settings, tutorial and progression state, including save and reload; key binding and the duplicate guard; the typing controller and word lists; zombie core behaviour, freeze, knockback, pooling, death animation and facing; spawning, edge positions and equal ring arrival; mission catalog and wave configs; combat feedback, HUD warnings, wave counter and boss health bar; the boss fight phases, summons and finale; screen shake; medals, accuracy and WPM; Endless rounds, scores and the game over screen; and projectiles passing dying zombies.

Patterns worth keeping: tests that touch a save file back it up and restore it (`tests/helpers/progression_backup.gd`) or point the autoload at a throwaway path; timing-based code takes timestamps as arguments so results can be worked out by hand; and anything involving physics is tested with real projectiles, because calling `take_damage()` directly skipped the physics callback that caused #69. Isolated enemy test scenes live under `tests/zombies/`. Mission flow and feel are covered by the 22 manual test records under `tests/manual/` and the playtests.

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
| Dev bandwidth across 8 enemy types + 2 bosses | Happened | High (content cut) | Team of four from Milestone 2; scope cut with a fixed decision date for Mission 4 (GDD §1.6) | Cut decided 9 Oct |
| Data-driven resources drift out of sync with GDD balance numbers | Low | Medium | UpgradeCatalog/EnemyTypeDef are the only place numbers live; GDD references them, doesn't restate them | Ongoing |
| Physics state changed inside a physics callback | Happened (#69) | High (corpses blocked bullets, boss helpers unhittable) | `set_deferred()` and `call_deferred()` for anything done from a hit; physics tested with real projectiles | Fixed 11 Oct |
| Signal connections stacking on pooled nodes | Happened (#41) | Medium | Named handlers with `is_connected()` guards, never anonymous lambdas on reused nodes | Fixed 2 Sep |

**Outcome of the original risks:** keystroke capture with `InputEventKey.unicode` worked across layouts from the start. HUD performance was never a problem at the real enemy counts (at most a handful of zombies at once). Team bandwidth was the risk that actually landed, and it is why Missions 4 to 6 were cut (GDD §1.6).

---

## 11. Repo & folder structure (as built)

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
  /testing/                 (isolated technical test scenes)
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
  /helpers/                 (save backup helper for tests)
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

- Resolved: the Mission 1 callouts and first-enemy callouts were one feature and were built once (#60).
- Whether the 5-word combo threshold should rise; playtest #3 saw a charge about every 6 words. It is one constant (`COMBO_MAX`), so changing it is small.
- Known technical debt: `mission_1.gd` is the shared base for every mission and is large; a `mission_base.gd` plus data-only mission configs would be cleaner. Ability effects are flags on `Projectile`; an `AbilityDef` resource per ability would let a new ability be one file.

---

## 14. AI use declaration

This Tech Spec was drafted collaboratively with Claude (Anthropic), per the CGRA 359 AI Assistance Policy, translating the GDD's existing systems (§2.2.x, §10) into an architecture/implementation-level document. The v0.3 to v0.6 syncs were also drafted with Claude from the code and the project log, and checked by Romart. The architecture choices (signal-based systems, single UpgradeCatalog source of truth, data-driven resources) are proposals for review, not fixed: same standing test as the GDD, any section should be defensible out loud, without notice.
