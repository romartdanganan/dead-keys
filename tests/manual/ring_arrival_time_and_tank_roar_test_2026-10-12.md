# Ring Arrival Time and Tank Roar Manual Test - 12 October 2026

**Tester:** Romart Danganan
**Branch:** `romart/boss-fight-and-endless-mode`
**Engine:** Godot 4.7
**Scene:** scenes/missions/mission_1.tscn, scenes/missions/mission_3.tscn

## Purpose

Verifies two changes made after William's barrier ring (#55) was merged into this branch.

- **#71:** every wave zombie reaches the barrier ring in the same time, whichever side of the screen it spawns from, and the game is back to the pace it had before the ring.
- **#67:** when the player breaks the Tank's 66% or 33% phase while it is at the ring, the Tank roars. It pushes itself and nearby zombies away from the base, and its helpers spawn behind it instead of inside the ring.

## Test setup

- Ran a local smoke scene in Mission 3 that spawns five walkers at the same moment from the right, bottom, left, top and a corner, and records when each one starts attacking the ring.
- The same smoke scene places the Tank 113 px from the base with one walker beside it and one walker on the far side, then breaks 66% with a real bullet.
- Played Missions 1 and 3 in the editor to check the pace and the roar by eye.
- GUT suite: 295/295 with no orphans.
- Boss helpers and other `spawn_extra` zombies are placed mid fight, so they keep their normal speed and are not part of the equal arrival check.

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Arrival from every side | Walkers spawned together from all sides reach the ring at about the same time | Right 24.0 s, bottom 24.4 s, left 24.4 s, top 24.4 s, corner 24.8 s | Pass |
| Speed per side | Side zombies slow down, top and bottom slow down more, corners stay about the same | Side 0.87, top and bottom 0.48, corner 1.0 | Pass |
| Pace before the ring | A side zombie takes as long to reach the ring as it used to take to reach the base | Matched in GUT and by eye in Mission 1 | Pass |
| Speed setting and Commander | The accessibility zombie speed setting and the Commander boost still apply on top | Matched in GUT | Pass |
| Roar ring | A pale blue ring bursts from the Tank when 66% breaks | As expected | Pass |
| Tank pushed back | A Tank at the ring is knocked out to ring + 180 px | Ended 285 px from the base (105 + 180) | Pass |
| Nearby zombies pushed | Zombies within 150 px of the Tank are knocked away from the base | Walker beside the Tank moved 109 px | Pass |
| Far zombies untouched | Zombies further than 150 px keep walking | Walker 305 px away only walked its normal 21 px | Pass |
| Far Tank untouched | A Tank already far from the ring is not moved by the roar | Matched in GUT | Pass |
| Helpers behind the Tank | Cats and dogs spawn further from the base than where the Tank landed | Cats at 354 and 372 px, Tank at 285 px | Pass |
| Barrier ring attack | A zombie forced into ATTACK on the ring edge resumes attacking after a freeze | Matched in GUT | Pass |

## Issues found

- Top and bottom zombies walked about 360 px less than side zombies, so they arrived much sooner. The ring shortened every walk again, so the whole game felt faster than before.
- A Tank at the ring would have spawned its phase helpers on top of the base.
- Running GUT from the command line failed to find the `BarrierRing` class name in `mission_1.gd`, because the class cache did not know the new class yet.
- The roar's impact ring was first created before the deferred call, which left 9 orphan nodes in GUT when the scene was freed first.

## Fixes applied

- `zombie_manager.gd` gives every wave zombie a `travel_scale` at spawn: its walk to the ring divided by a side zombie's old walk to the base. `ZOMBIE_PACE` can tune the whole game later.
- `zombie.gd` multiplies its speed by `travel_scale` and resets it in `setup()` so pooled zombies start fresh.
- `boss_fight.gd` roars on each phase break, then summons helpers behind the Tank's landing spot.
- `mission_1.gd` preloads the barrier ring script instead of using the class name.
- The roar ring is now created inside the deferred call.

## Follow-up

- Let William know about `travel_scale` in `zombie.gd` and `zombie_manager.gd`.
- Lower `ZOMBIE_PACE` after playtest 3 if the game still feels fast.
- Decide with William whether zombie to zombie collision stays.
