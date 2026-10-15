# Mission 3, Tank Boss and Ability Controls Manual Test - 9 October 2026

**Tester:** Romart Danganan
**Branch:** `romart/mission-3-and-tank-boss`
**Engine:** Godot 4.7
**Scene:** scenes/missions/mission_3.tscn, scenes/missions/mission_2.tscn, scenes/missions/mission_1.tscn, Settings menu, How to Play

## Purpose

Verifies everything on this branch together: Mission 3 "Secure the Shopping
Centre" with the Tank boss and boss health bar, the Brute added to Mission 2
(#63), the playtest fixes made along the way (zombies spawning just off
screen, the Tank only spawning from the sides, slower medic healing), the
How to Play wording cleanup (#58), and the ability pivot (#64): the ability
charges from 5 typed words in a row and is fired with its own rebindable
input instead of automatically on the next shot.

## Test setup

- Played Missions 1, 2 and 3 from the editor through the normal Home Base
  flow, reaching Mission 3 through Mission 2's Next Mission button
- Spread Shot equipped for the ability tests
- Rebinding tested in Settings, CONTROLS tab
- Not covered: the Tank using long words only (waiting on the word list
  system, #43), Home Base card unlocking for Mission 3 (Nicole's #32), and
  Spitter, Exploder and Armoured enemies (not in the game)

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Mission 2 Next Mission | Loads Mission 3 | Confirmed | Pass |
| Mission 3 setup | "Secure the Shopping Centre" name, own background colour, shopping centre words, waves 1 to 4 | Confirmed | Pass |
| Mission 2 Brute | A Brute arrives in wave 2 behind the Medic | Confirmed | Pass |
| Tank arrival | Tank spawns in the final wave with the BOSS callout | Confirmed | Pass |
| Tank spawn direction | Tank comes from the left, right or a corner, never straight from the top or bottom | Confirmed | Pass |
| Boss health bar | TANK bar appears under the wave counter, drops when hit, hides when the Tank dies | Confirmed | Pass |
| Mission 3 complete | Killing the Tank and clearing the wave shows the success screen with gold, Next Mission greyed out | Confirmed | Pass |
| Zombies reach the screen quickly | After a wave starts zombies appear within a few seconds from every direction, spawn counts unchanged | Confirmed | Pass |
| Medic healing | A quick 3 shot burst kills a Walker next to a Medic; a zombie left damaged for 2 seconds heals slowly | Confirmed | Pass |
| Commander | Stops and hangs back while other zombies are near it, nearby zombies move faster | Confirmed | Pass |
| Word combo | 5 typed words in a row without a mistake charge the ability, a mistake resets the streak | Confirmed | Pass |
| Ability ready HUD | Bar stays full and shows READY with the ability key, ability glow on | Confirmed | Pass |
| Left click while ready | Normal shot, charge kept | Confirmed | Pass |
| Right click while ready | Ability fires, charge used, combo display resets | Confirmed | Pass |
| Rebind ability | USE ABILITY can be set to another key or mouse button and works in a mission | Confirmed | Pass |
| Duplicate binding | Setting the ability to the fire button or a supply key shows ALREADY USED | Confirmed | Pass |
| How to Play | Ability section describes the new trigger and shows the current ability key, mistakes text reads "turned off" | Confirmed | Pass |
| Mission 1 callout | Ability callout says 5 words in a row and names the ability key | Confirmed | Pass |
| GUT Run All | All tests pass | 193/193 across 26 scripts | Pass |

## Issues found

- Zombies from the top and bottom walked about 474px off screen (about 16s
  for a Walker) before appearing, because every spawn sat on a circle sized
  to clear the screen corners. Waves felt slow even though nothing was
  spawning slowly.
- The Tank could spawn from the top or bottom, the shortest path to the base,
  which made it much harder than from the sides.
- The Medic healed 10 HP/s continuously, so between each shot it put 5 HP
  back and a Walker took about 5 bullets instead of 3.
- The ability fired automatically on the next shot after 5 kills, so players
  could not choose when to use it, and kills depended on aim as much as
  typing.
- Found while adding the ability binding: swapped supply keys (supply 1 on
  "2", supply 2 on "1") failed to load on the next launch.

## Fixes applied

- `zombie_manager.gd`: zombies spawn just past the screen edge along their
  spawn direction; new `side_spawn_only` wave option keeps a wave within 45
  degrees of left or right, used for the Tank.
- `zombie.gd`, `enemy_type_def.gd`, `medic.tres`: medics wait until a zombie
  has gone 2 seconds unhit before healing, and heal 5 HP/s.
- `mistake_system.gd`: combo counts completed words, pauses while a charge is
  stored. `weapon_controller.gd`: `try_fire()` is a normal shot,
  `try_fire_ability()` fires the stored ability on the new `use_ability`
  input (right click by default).
- `settings_state.gd`: one duplicate guard for fire, ability and supply
  bindings; supply keys are cleared before loading so swaps load correctly.

## Follow-up

- Tank long words once the word list system (#43) reads `word_pool_tag`
- Tune the Tank's 500 HP, the 5 word combo and the medic heal numbers in the
  wider playtest (#33)
- GDD and Tech Spec: Medic numbers (2.5), ability trigger and activation
  (2.2.3), controls table, Mission 3 and Tank, spawn behaviour
- Tell William about the `zombie_manager.gd`, `wave_entry.gd`, `zombie.gd`
  and medic changes, and Josiah about the `mistake_system.gd` and How to
  Play changes
