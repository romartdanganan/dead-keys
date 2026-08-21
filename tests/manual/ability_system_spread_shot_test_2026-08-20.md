# Ability System (Loadout + Spread Shot) Manual Test — 20 August 2026

**Tester:** Romart Danganan  
**Branch:** `romart/ability-system`  
**Engine:** Godot 4.7  
**Scene:** `ability_select.tscn` (loadout flow), `home_base.tscn` (navigation), `gameplay_prototype.tscn` (Spread Shot verification)

## Purpose

Verify the Ability System framework and Spread Shot (#24): exactly one
ability can be selected before launch and is locked once the mission starts,
Spread Shot fires correctly the shot after the ability is charged and only
then, and the HUD reflects charged/uncharged state.

## Test setup

- Combo system (#23, assigned to Josiah) is not yet implemented, so the
  ability charge for this pass was set manually via the temporary debug key
  `debug_charge_ability` (F1), which calls the same `AbilityState.set_charged()`
  #23 will call once their combo counter reaches 5.
- Ability Select is only reachable from Home Base, not from an active
  mission — this is how "locked once launched" is enforced, there is no
  separate runtime lock flag to test independently.
- Known exclusion: the actual Combo counter charging the ability from real
  kills was not tested here, since that's #23's scope, not this one's.

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Ability Select opens | Home Base's ABILITY LOADOUT button opens the screen, showing 8 rows | Opens correctly, 8 rows shown | Pass |
| Only Spread Shot selectable | Other 7 rows show "SOON" and are disabled | Confirmed for all 7 | Pass |
| Select Spread Shot | Row updates to "EQUIPPED" | Confirmed | Pass |
| Selection persists to mission | Equipped ability carries from Home Base into the launched mission | `AbilityNameLabel` shows "SPREAD SHOT" on mission start | Pass |
| Selection locked once launched | No way to reach Ability Select from inside a mission | Confirmed — no in-mission path to the screen exists | Pass |
| Charge sets HUD state | Debug charge key sets `AbilityNameLabel` to "SPREAD SHOT (READY)" | Confirmed | Pass |
| Spread Shot fires on the charged shot | Charged shot fires 3 bullets in a cone instead of 1 | Confirmed, 3 projectiles spawned in a visible cone | Pass |
| Charge consumed on use | Immediately after the charged shot, HUD reverts to "SPREAD SHOT" (uncharged) | Confirmed | Pass |
| Only the charged shot is affected | The next shot after that fires normally (1 bullet) | Confirmed | Pass |
| Ammo cost unaffected | Spread Shot's 3-bullet burst still costs only 1 ammo, same as a normal shot | Confirmed via ammo HUD | Pass |

## Issues found

- Initial cone angle (±15°) was too tight to read as a spread — widened to
  ±25°.
- Weapon muzzle sat too far from the WeaponController's own position —
  pulled in from `(0, -30)` to `(0, -22)` local offset.
- Weapon firing position felt too far up the screen — moved the
  `WeaponController` down from `(640, 620)` to `(640, 700)`, closer to the
  bottom edge of the 1280×720 viewport.
- The debug charge key was originally bound to F9, which turned out to be
  Godot's own "suspend/resume embedded project" shortcut and never reached
  the game at all — rebound to F1.
- Pressing the debug charge key surfaced the pre-existing `AttackTimer`
  duplicate-connection bug (documented in `handover.md` since Milestone 2)
  as an actual editor freeze, rather than just a log error — Godot's editor
  debugger pauses on every engine-level error by default, and several
  zombies spawning in sequence stacked into multiple pause points.

## Fixes applied

- `weapon_controller.gd`: `SPREAD_SHOT_ANGLE` increased from 15° to 25°.
- `gameplay_prototype.tscn`: `MuzzlePoint` local position changed from
  `(0, -30)` to `(0, -22)`; `WeaponController` position changed from
  `(640, 620)` to `(640, 700)`.
- `project.godot`: `debug_charge_ability` rebound from F9 to F1.
- `zombie.gd`: guarded the `AttackTimer.timeout` connection in `_ready()`
  with `is_connected()` so it's no longer made twice (once in `zombie.tscn`,
  once in script) — removes the duplicate-connection error entirely.
  Incidental fix, not part of #24's actual scope; flagged separately below
  since it touches William's file.

## Follow-up

- Re-test with the real Combo counter once #23 lands, and remove the
  `debug_charge_ability` debug key at that point.
- `zombie.gd`'s `AttackTimer` fix should be pointed out to William directly
  since it's his file, even though it was applied here to unblock testing.
