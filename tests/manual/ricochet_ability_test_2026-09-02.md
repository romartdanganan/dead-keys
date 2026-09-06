# Ricochet Ability Manual Test — 02 September 2026

**Tester:** Romart Danganan
**Branch:** `romart/ricochet-ability`
**Engine:** Godot 4.7
**Scene:** scenes/missions/gameplay_prototype.tscn

## Purpose

Verifies the Ricochet ability (#36): a charged shot hits its initial target,
then bounces to the 2 nearest not-yet-hit active zombies, for 3 zombies hit
total per charged shot.

## Test setup

- Ricochet selected as the equipped ability via the Ability Select screen
- `debug_charge_ability` input used to force a charge without needing to
  build a real 5-kill Combo streak first
- Tested against groups of Walkers spawned via the normal wave flow

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Charged shot, 3+ zombies in range | Hits 3 distinct zombies, full damage on each | Confirmed | Pass |
| Charged shot, only 1 zombie on screen | Behaves like a normal shot, no bounce | Confirmed | Pass |
| Non-charged shot | Despawns on first contact as before, no bounce | Confirmed | Pass |
| Ability charge consumption | Charge consumed exactly once per triggered shot | Confirmed | Pass |

## Issues found

- None.

## Fixes applied

- None, first pass worked as designed.

## Follow-up

- Bounce range is currently unbounded (nearest active zombie anywhere on
  screen), not distance-limited. Worth revisiting once more enemy types and
  larger arenas exist, a max bounce radius may be needed so it doesn't feel
  like it's picking targets from off-screen.
- No manual test yet for Ricochet against a mixed-type wave (only Walkers
  tested so far), worth another pass once Brute/Medic land.
