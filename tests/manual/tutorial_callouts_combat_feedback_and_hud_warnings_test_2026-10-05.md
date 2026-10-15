# Tutorial Callouts, Combat Feedback and HUD Warnings Manual Test - 5 October 2026

**Tester:** Romart Danganan
**Branch:** `romart/debug-keys-and-tutorial-callouts`
**Engine:** Godot 4.7
**Scene:** scenes/missions/mission_1.tscn, Mission 2 (inherits mission_1.gd), scenes/ui/home_base.tscn, Settings menu

## Purpose

Verifies everything on this branch together before it goes to `dev`:
debug shortcuts limited to debug builds (#59), Mission 1 tutorial callouts
and first-sighting enemy callouts (#60), combat feedback and HUD clarity
(#61: hit flash, death burst, ammo popups, out of ammo prompt, wave counter,
mission name label, focus pause), the low wall health warning and ability
ready glow (#62), and the new Reduce Flashing setting on the Settings menu
(#46).

## Test setup

- Played from the editor on a save with the tutorial reset (Home Base R key,
  which now also resets `TutorialState`)
- Played Mission 1 and Mission 2 through the normal Home Base flow
- Ability bought and equipped through Ability Select so the charge and glow
  could be checked
- Reduce Flashing tested both off and on from the Settings menu
- Not covered here: Brute and Commander callouts (enemies not in the game
  yet, William's #30), and a real exported release build (no export preset
  yet), so the release side of #59 and alt-tab pausing in an export rely on
  `OS.is_debug_build()` and `Engine.is_embedded_in_editor()` plus GUT

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Debug keys in the editor | Home Base G/H/S/R and Mission debug keys still work in a debug run | Confirmed | Pass |
| Home Base R reset | Save and tutorial callouts both reset | Confirmed | Pass |
| Wave 1 typing callout | "Type the word above a zombie to load ammo" banner shows once at wave 1 | Confirmed | Pass |
| Supply callout | Only shows when a supply is equipped, shows the bound keys | Confirmed | Pass |
| Fire callout | Shows after the first completed word with the bound fire key | Confirmed | Pass |
| Callout queueing | A second callout waits for the first to finish instead of overwriting it | Confirmed | Pass |
| Jam and ability callouts | Show once the first time the gun jams and the ability charges | Confirmed | Pass |
| Runner and Medic callouts | One line the first time each type appears | Confirmed | Pass |
| Callouts shown once | Replaying the mission does not show seen callouts again | Confirmed | Pass |
| Hit flash | Zombie sprite flashes bright white on each hit | Confirmed | Pass |
| Death burst | Particle burst in the zombie's colour where it died | Confirmed | Pass |
| Ammo popup | "+N AMMO" rises above the zombie whose word was finished, "AMMO FULL" when the magazine is full | Confirmed | Pass |
| Out of ammo prompt | Firing empty shows "TYPE A WORD TO RELOAD" at the cursor and the ammo panel flashes red, no stacking when spam clicking | Confirmed | Pass |
| Wave counter | "WAVE X / Y" under the wall bar, hidden until wave 1, updates each wave | Confirmed | Pass |
| Mission name label | Mission 2 shows its own name instead of THE SUBURBS | Confirmed | Pass |
| Editor Game tab speed change | Changing speed to 1.25x or 1.5x does not open the pause menu or freeze the game | Confirmed | Pass |
| Low wall health warning | Wall panel pulses red at 25% wall health or below, normal above it | Confirmed | Pass |
| Ability ready glow | Ability section glows while charged and returns to normal after the ability shot | Confirmed | Pass |
| Reduce Flashing toggle | Toggle on the GAMEPLAY tab, saved between sessions | Confirmed | Pass |
| Reduce Flashing on | No hit flash, no red ammo panel flash, wall warning and ability glow hold a steady colour | Confirmed | Pass |
| GUT Run All | All tests pass | 154/154 across 23 scripts | Pass |

## Issues found

- The HUD mission name label was hardcoded to "MISSION: THE SUBURBS" in
  `mission_1.tscn`, so Mission 2 showed the wrong name.
- The new focus pause opened the pause menu and froze the game when the
  editor Game tab speed was changed, because clicking the editor toolbar
  takes focus away from the embedded game.

## Fixes applied

- `mission_1.gd`: the mission name label is set from
  `mission_config.mission_name` when the mission starts.
- `mission_1.gd` `_notification()`: the focus pause also requires
  `not Engine.is_embedded_in_editor()`, so it only fires in its own window or
  an exported build.

## Follow-up

- Josiah's mission failed screen (#56) needs adding to the
  `_open_pause_menu()` check so alt-tab can't open the pause menu over it.
- Check the debug keys are dead in a real release export once an export
  preset exists.
- Brute and Commander callout lines are ready and will show once William's
  enemies land.
- Wider playtest (#33) to judge the 25% wall threshold and glow strength.
