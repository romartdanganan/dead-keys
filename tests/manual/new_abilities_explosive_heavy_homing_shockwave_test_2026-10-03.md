# New Abilities (Explosive Round, Heavy Round, Homing Shot, Shockwave Round) Manual Test - 3 October 2026

**Tester:** Romart Danganan
**Branch:** `romart/new-abilities`
**Engine:** Godot 4.7
**Scene:** scenes/missions/mission_1.tscn

## Purpose

Verifies the four abilities that replace the last four LOCKED slots on the
Ability Select screen: Explosive Round, Heavy Round, Homing Shot and
Shockwave Round. Each is bought for 200 gold, equipped, charged, and fired
on the next shot like the existing abilities. Also covers the fixes made
after the first playtest pass (explosion and shockwave visuals, smooth
knockback, on-screen-only homing, larger explosion radius) and a Freeze
Round radius bug found while building Explosive Round.

## Test setup

- Each ability bought and equipped through the Ability Select screen
- `debug_charge_ability` input (F1) used to force a charge without needing
  a real 5-kill Combo streak
- Tested against Walkers and Runners from the normal Mission 1 wave flow,
  with 360 directional spawning so zombies approach from all sides
- Two playtest passes: the first found three problems, all fixed and
  retested in the second pass below

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Buy each new ability | 200 gold deducted, card changes from BUY to owned | Confirmed | Pass |
| Equip each new ability | Card shows EQUIPPED, HUD shows the ability name in mission | Confirmed | Pass |
| Non-charged shot with any new ability equipped | Behaves like a normal shot | Confirmed | Pass |
| Charge consumption | Charge consumed exactly once per ability shot, HUD "(READY)" clears | Confirmed | Pass |
| Explosive Round hit | Every zombie within 200px of the impact takes 2x bullet damage, hit zombie included | Confirmed | Pass |
| Explosive Round visual | Animated blast with flash, sparks and a ring landing on the damage radius | Confirmed | Pass |
| Explosive Round kills the hit zombie | Explosion still triggers and centres on the impact point | Confirmed | Pass |
| Heavy Round | Single hit deals 5x bullet damage, full health Walker dies in one shot | Confirmed | Pass |
| Homing Shot fired roughly at a moving zombie | Bullet curves onto the nearest on-screen zombie and hits it | Confirmed | Pass |
| Homing Shot with zombies still off-screen | Ignores off-screen zombies, only homes onto zombies at least partly visible | Confirmed | Pass |
| Shockwave Round hit | Hit zombie and zombies within 120px slide back 150px along the shot over 0.3s | Confirmed | Pass |
| Shockwave Round visual | Blue ring shows the shockwave radius | Confirmed | Pass |
| Shockwave on a zombie attacking the wall | Zombie slides back, stops attacking, walks back to the wall | Confirmed | Pass |
| Freeze Round still works | Hit and nearby zombies freeze as before | Confirmed | Pass |

## Issues found

- First playtest pass, Explosive Round: no visual at all, so there was no
  way to tell it worked or how big the radius was.
- First playtest pass, Shockwave Round: zombies teleported 150px back
  instantly, which was hard to read and felt unsatisfying.
- First playtest pass, Homing Shot: homed onto zombies outside the camera
  view, and the bullet was freed on leaving the screen before reaching them.
- First playtest pass, Explosive Round: 120px radius was too small, with
  360 spawning zombies rarely bunch up so it rarely hit more than one.
- Found during development, Freeze Round: the freeze radius was measured
  from the hit zombie, so if the shot killed a pooled zombie (moved
  off-screen on death) nothing nearby froze.
- Pre-existing and not caused by this branch: AttackTimer "already
  connected" error in `zombie.gd` `_ready()` when pooled zombies are reused.

## Fixes applied

- `scripts/effects/impact_ring_effect.gd` (new): animated ring drawn in
  code, used for Explosive Round (orange, with sparks) and Shockwave Round
  (blue), sized to the real effect radius.
- `zombie.gd`: `apply_knockback()` now starts a 0.3s slide that eases to a
  stop instead of moving the zombie instantly, total distance unchanged.
- `projectile.gd`: new `_is_on_screen()` check used when picking a homing or
  ricochet target, so only zombies at least partly visible are chosen.
- `weapon_controller.gd`: `EXPLOSIVE_ROUND_RADIUS` raised from 120 to 200.
- `projectile.gd`: Freeze Round, Explosive Round and Shockwave Round all
  measure their radius from the bullet's impact point.
- `test_zombie_knockback.gd`: GUT tests for `apply_knockback()`, updated
  for the smooth slide, verified via GUT Run All.

## Follow-up

- Ricochet now also only bounces to on-screen zombies (shared target
  search), worth a quick check in the next full playtest.
- All tuning numbers (radii, 2x splash, 5x heavy, 150px knockback) are
  first-pass values for the wider playtest (#33).
- William to look at the pre-existing AttackTimer duplicate connection
  error in `zombie.gd`.
