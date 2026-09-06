# Mission 1 Wave System Manual Test — 03 September 2026

**Tester:** Romart Danganan
**Branch:** `romart/build-mission-1`
**Engine:** Godot 4.7
**Scene:** scenes/missions/mission_1.tscn (launched via Home Base)

## Purpose

Verifies Mission 1 as a real, standalone mission (replacing the gameplay_prototype
placeholder): staged wave composition, the wave/final-wave announcement widget,
spawn jitter, and the placeholder word list, all launched through the normal
Home Base flow rather than opening the scene directly.

## Test setup

- Launched via Home Base -> Launch Mission button, not by opening mission_1.tscn directly
- No permanent upgrades purchased beforehand, default starting state
- Default supply loadout (whatever was set from Mission Supplies screen)
- Placeholder word list at resources/word_lists/mission_1_words_PLACEHOLDER.json in place

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Home Base launch | Launch Mission button opens mission_1.tscn, not gameplay_prototype.tscn | Correct scene loaded | Pass |
| Wave 1 composition | Walkers only, spaced out, no visible stacking | Walkers only, spawn jitter kept them visually separated | Pass |
| Wave 2 announcement | Single "WAVE 2" shown once, despite Walker + Runner spawning as two batches | One announcement shown, not two | Pass |
| Wave 2 composition | Walker batch followed by Runner batch | Runner batch introduced zigzag movement correctly | Pass |
| Wave 3 announcement | Shows "FINAL WAVE" instead of "WAVE 3" | Correct text shown | Pass |
| Wave announcement animation | Fade in, hold, fade out, readable without blocking play | Timing felt readable | Pass |
| Spawn jitter | Zombies reusing the same spawn point don't spawn exactly stacked | No exact overlap at spawn | Pass |
| Win condition | Clearing all waves returns to Home Base | Returned to Home Base | Pass |
| Lose condition | Wall destroyed with no lives left returns to Home Base | Returned to Home Base | Pass |
| Placeholder word list | Loads without console errors, words appear above zombies | No parser warnings, words displayed correctly | Pass |

## Issues found

- Initial wave pacing (first pass) was too dense for an average typist, zombies
  spawned close enough together to visually overlap on approach
- Zombie approach movement has no separation/flocking between zombies (GDD
  §8.1 calls for this but it isn't implemented), so zombies converging near
  the wall can still crowd together later in their approach even with
  spawn-point jitter applied

## Fixes applied

- Added a small random spawn position offset in ZombieManager so zombies
  reusing the same spawn marker don't walk an identical line
- Retuned wave counts and spawn intervals across all three waves for a more
  forgiving tutorial pace

## Follow-up

- Wave pacing here is a first pass, not validated against a real slower
  typist (~35-40 WPM). Needs checking during the upcoming internal playtest (#33)
- Zombie separation/flocking behaviour is a pre-existing gap, not something
  this MR fixes, tracked separately for William (#44)
- The placeholder word list is intentionally temporary; the real per-mission
  word list system is tracked separately (#43)
