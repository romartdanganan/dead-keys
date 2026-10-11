# Boss Fight Overhaul and Endless Mode Manual Test - 11 October 2026

**Tester:** Romart Danganan
**Branch:** `romart/boss-fight-and-endless-mode`
**Engine:** Godot 4.7
**Scene:** scenes/missions/mission_3.tscn, scenes/missions/endless.tscn, scenes/ui/main_menu.tscn, Settings Accessibility tab

## Purpose

Verifies three issues.

- **#67:** the Mission 3 Tank fight.
  - It has an entrance, two phases and screen shake.
  - Phase 2 (66%) staggers the Tank and summons two cats. Phase 3 (33%) cracks its armour, summons two dogs and enrages it.
  - Killing the boss ends the mission with a cinematic: zoom in and slow motion on the Tank death, then a zoom out while every other zombie dies, then Mission Complete.
- **#68:** Endless mode from the Main Menu.
  - It has a gentle round ramp, a Tank every 5th round, saved high scores and a new game over screen.
- **#69:** bullets now pass through a zombie that is playing its death animation.

## Test setup

- Played Mission 3 through Home Base and Endless from the Main Menu, in the editor.
- Turned Reduce screen shake on and off in the Accessibility tab.
- Also ran local smoke scenes that fire real projectiles at zombies, and checked the debugger for physics errors.
- GUT suite run after each unit: 262/262 after the boss unit, 279/279 after the Endless unit.

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Boss entrance | BOSS INCOMING banner, shake, zoom pulse, boss bar slides in with 66% and 33% marks | As expected | Pass |
| Phase 2 at 66% | Tank stops for 2.5 s, two cats with short words spawn above and below it | As expected | Pass |
| Phase 3 at 33% | ARMOUR CRACKED, a third of the remaining health removed, two dogs spawn, Tank turns red and speeds up slightly | As expected | Pass |
| Shooting summoned zombies | Every summoned cat and dog can be hit and killed | All took damage from real bullets | Pass |
| Bullet past a dying zombie | Bullet flies through the corpse and hits the zombie behind it | Hit the zombie behind | Pass |
| Boss kill cinematic | Spawning stops, leftover words hide, camera zooms on the slowed Tank death | Zoom reached about 1.8x at quarter speed | Pass |
| Zoom out | Camera returns to normal while every other zombie plays its death animation | All zombies died together, zoom back to 1x | Pass |
| Mission end | Mission Complete with medal shows after the cinematic, wall takes no damage during it | As expected | Pass |
| Reduce screen shake | No shake on wall hits, lost lives or boss moments | No shake | Pass |
| ENDLESS MODE button | Main Menu button reads ENDLESS MODE with no score | As expected | Pass |
| Endless round 1 | Exactly 3 cats with the shortest words | 3 cats, short words | Pass |
| Round progression | ROUND CLEAR, wall repair and a 3 s break, then the next round | As expected | Pass |
| Endless boss round | Tank on round 5, killing it only gives a short slow motion and the run carries on | As expected | Pass |
| Game over screen | Spaced card with the score and BEST side by side, then kills, accuracy and WPM cards, plus Play Again and Main Menu | As expected | Pass |
| UI built as scenes | Game over screen, mission camera, boss bar phase marks, both medal icons and the hit effects come from .tscn nodes and look the same as before | Screenshots matched the earlier versions | Pass |
| No typing | Accuracy and WPM show a dash instead of 100% | Dashes shown | Pass |
| WPM timing | WPM only counts the time between keys inside a word, not breaks, gaps between words or long mid word pauses | Matched in GUT with fixed timings (5 keys 0.2 s apart = 60 WPM) | Pass |
| New best | NEW BEST! badge only when the score beats the saved best | As expected | Pass |
| Game over buttons | Play Again restarts Endless, Main Menu goes back to the Main Menu | As expected | Pass |

## Issues found

- The summoned dogs could not be shot, so they walked to the base unkillable.
- Bullets stopped on zombies that were playing their death animation.
- Both had the same root cause. Bullets damage zombies inside Godot's physics callback, and changing a hitbox there is refused ("Can't change this state while flushing queries").
  - A killing hit never turned the corpse's hitbox off.
  - Zombies summoned during a hit got broken hitboxes.
- In the first prototype the leftover zombies' words cluttered the finale close up.
- The prototype's Endless start was too hard: round 1 had 5 walkers with medium words.
- The prototype's Endless game over screen was plain text lines.
- BEST sat in the stat row next to WPM, so it read like best WPM.
- WPM divided by the whole run time, including round breaks and quiet moments, so it read lower than the player's real speed.
- Several pieces of UI were built node by node in scripts instead of scenes, so they could not be edited in the Godot editor.

## Fixes applied

- `zombie.gd` turns collision on and off with `set_deferred`. `projectile.gd` ignores zombies that are already dead.
- Boss summons are deferred until after the bullet hit.
- Leftover word labels are hidden when the finale starts.
- Endless round 1 is now 3 walkers with the shortest words, and no round grows by more than 3 zombies.
- A new `endless_game_over.tscn` screen replaces the plain text stats, and the mission fail overlay is unchanged.
- BEST now sits beside the score.
- `mission_rating.gd` now measures typing time from the gaps between keys inside each word, skipping any gap over 1.5 s.
- The game over screen, camera, boss bar phase marks, medal icons, death burst, ammo popup and impact ring are now scene nodes. Their scripts only handle behaviour.

## Follow-up

- Let William know about the deferred collision change in `zombie.gd` and `spawn_extra()` in `zombie_manager.gd`.
- Watch Mission 3 difficulty in playtest 3. It may be very slightly hard, but the speed setting and upgrades should cover it.
- Endless high scores could get a leaderboard screen later if there is time.
