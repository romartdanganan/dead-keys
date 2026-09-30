# Freeze Round Ability and Related Fixes Manual Test — 21 September 2026

**Tester:** Romart Danganan
**Branch:** `romart/freeze-round-ability`
**Engine:** Godot 4.7
**Scene:** scenes/missions/mission_1.tscn

## Purpose

Verifies the Freeze Round ability (#37): a charged shot fully freezes the
hit zombie and any other zombies within a small radius, for a set
duration. Also covers two bugs found during this playtest and fixed on
the same branch: a pause menu Return to Hub crash, and mission music not
returning to the lobby track, plus a word label positioning tweak on
`zombie.tscn`.

## Test setup

- Freeze Round selected as the equipped ability via the Ability Select screen
- `debug_charge_ability` input (F1) used to force a charge without needing
  a real 5-kill Combo streak
- Tested against groups of Walkers spawned via the normal wave flow
- Pause menu Return to Hub tested specifically while zombies were still
  alive mid-wave, the condition that previously crashed
- Music tested by launching a mission from Home Base, then returning to
  Home Base

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Charged shot hits a zombie near others | Hit zombie and nearby zombies within radius freeze (stop moving/attacking) for ~2.5s, then resume | Confirmed | Pass |
| Frozen zombies visually read as frozen | Sprite tints while frozen | Confirmed | Pass |
| Non-charged shot | Behaves like a normal shot, no freeze | Confirmed | Pass |
| Ability charge consumption | Charge consumed exactly once per triggered shot | Confirmed | Pass |
| Return to Hub while zombies still alive mid-wave | No crash | Confirmed | Pass |
| Return to Hub, then check music | Lobby music (main_music) plays again instead of the mission track continuing | Confirmed | Pass |
| Word label above zombie head | Sits close to the sprite, visible promptly as the zombie scrolls in from off-screen | Confirmed | Pass |

## Issues found

- None remaining as of this pass. Two bugs were found during this session
  and fixed before this test pass: the pause menu Return to Hub crash
  (root cause in `zombie_manager.gd`'s wave-clear coroutine) and mission
  music not returning to the lobby track (root cause in `home_base.gd`
  never managing its own music).

## Fixes applied

- `zombie_manager.gd`: `is_inside_tree()` guard added to
  `_wait_for_all_zombies_to_clear()`'s while loop.
- `mission_1.gd`: `return_to_home_base()` now calls
  `zombie_manager.stop_mission()` before the scene change.
- `home_base.gd`: `_ready()` now calls `Audio.clear_music()` then
  `Audio.play("main_music")`.
- `zombie.tscn`: `WordLabel` offset_top/offset_bottom moved from -105/-70
  to -90/-55.
- Several stale GUT test files fixed separately under #34 (not manually
  tested, verified via GUT Run All instead).

## Follow-up

- Freeze duration (2.5s) and radius (140px) are first-pass numbers, not
  GDD-derived, worth revisiting once more enemy types and playtesting
  data exist.
- Pre-existing, unfixed, not blocking: `zombie.tscn` connects
  `AttackTimer.timeout` via both the editor and `_ready()`, still
  flagged, not part of this branch's scope.
