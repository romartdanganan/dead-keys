# Accessibility Options Manual Test - 10 October 2026

**Tester:** Romart Danganan
**Branch:** `romart/medals-accessibility-and-art`
**Engine:** Godot 4.7
**Scene:** Settings menu (ACCESSIBILITY tab), scenes/missions/mission_1.tscn, scenes/missions/mission_3.tscn, How to Play

## Purpose

Verifies the new ACCESSIBILITY tab in Settings (#66), added after playtest #2
where a 40 to 50 WPM tester found the game hard. The options give slower or
newer typists more time without changing the default game: slower zombies,
a longer supply crate timer, larger word text, hold to fire, and Reduce
Flashing moved into the same tab. Also checks the options save between
sessions and that How to Play points players to them.

## Test setup

- Played Mission 1 and Mission 3 from the editor through the normal Home Base
  flow, with the cat zombie art from #35 already in
- Options changed from the Main Menu Settings and from the Pause menu mid
  mission
- At least one supply bought so a crate could be called
- Settings persistence checked by quitting and relaunching the game
- Not covered: exported build and fullscreen at other resolutions

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Accessibility tab layout | Five tabs fit across the top of the wider panel, rows and hint text do not overlap | All five tabs fit, rows and hint readable | Pass |
| Zombie speed 55% | Every zombie walks clearly slower than normal | Zombies noticeably slower | Pass |
| Zombie speed changed mid mission | Switching back to NORMAL from the Pause menu speeds zombies up as soon as play resumes | Zombies sped up straight away | Pass |
| Longer crate timer | Crate timer bar lasts about 12 seconds instead of 8 | Bar lasted about 12 seconds | Pass |
| Large word text on zombies and crates | Words are bigger, not cut off, and sit above the sprite | Bigger and fully readable | Pass |
| Large word text on Tank long words | Long Mission 3 words fit on one line above the Tank | Long words fit | Pass |
| Hold to fire | Holding fire keeps shooting at the weapon's fire rate | Kept firing at the normal rate | Pass |
| Hold to fire with no ammo | Firing stops at 0 ammo with no repeating no ammo sound | Stopped cleanly, no sound spam | Pass |
| Hold to fire while jammed | No repeating jammed sound while the button is held | No sound spam | Pass |
| Hold to fire on the success screen | Clicking success screen buttons does not fire shots | No shots fired | Pass |
| Reduce Flashing in its new tab | Toggle still turns off hit flashes and pulsing warnings | Still works | Pass |
| Settings persistence | All accessibility options are remembered after quitting and relaunching | All options remembered | Pass |
| How to Play | New NEED MORE TIME? section at the bottom points to the Accessibility tab | Section shows correctly | Pass |

## Issues found

- No defects found during this test.

## Fixes applied

- None needed during testing. Hold to fire was built with guards for the
  success, fail and pause screens and for empty or jammed shots before
  testing, since the success screen does not pause the game and empty or
  jammed shots would otherwise play their sound every frame.

## Follow-up

- Mission medals (#65) should not be reduced when accessibility options are
  on, so slower typists are not punished for using them
- Ask playtest #3 testers whether they found the Accessibility tab and which
  options they used
- Record the Accessibility tab in GDD v1.4 and the Tech Spec
