# Combo Overcount on Pooled Zombie Death Fix Manual Test — 02 September 2026

**Tester:** Romart Danganan
**Branch:** `romart/fix-combo-overcount-on-pooled-zombie-death`
**Engine:** Godot 4.7
**Scene:** `gameplay_prototype.tscn`

## Purpose

Verifies that killing a zombie previously recycled through the object pool
(#28) increments the Combo counter by exactly 1 per kill, instead of
over-counting from duplicate signal connections stacked up across
respawns of the same pooled instance.

## Test setup

- Played a full mission normally from Home Base, no debug shortcuts used
  to isolate the combo path.
- Played long enough for multiple waves to spawn, so some zombies were
  recycled through the pool more than once before being killed again.
- Observed the Combo counter on the HUD after each kill.

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Normal play through multiple waves, tracking Combo after each kill | Combo increases by 1 per kill, no jumps | No duplicate or inflated combo increments observed | Pass |

## Issues found

- None during this pass. Prior to the fix, Combo would occasionally jump
  by 3-4 on a single kill once a zombie had been recycled through the
  pool multiple times.

## Fixes applied

- `unregister_target()` in `typing_controller.gd` now only emits
  `target_unregistered` when a target was actually removed, instead of
  unconditionally on every call.
- `gameplay_prototype.gd` now connects a guarded, named `_on_zombie_died`
  handler to a spawned zombie's `died` signal instead of a fresh anonymous
  lambda on every spawn, preventing duplicate connections from stacking up
  on a reused pooled node.

## Follow-up

- Worth spot-checking William's own pooling test scenes
  (`tests/zombies/zombie_pooling_test`) for the same unguarded lambda
  pattern on `died`, since they predate this fix.
