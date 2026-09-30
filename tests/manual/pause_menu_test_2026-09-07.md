# Pause Menu Manual Test — 07 September 2026

**Tester:** Romart Danganan
**Branch:** `romart/pause-menu`
**Engine:** Godot 4.7
**Scene:** `scenes/missions/mission_1.tscn`

## Purpose

Verifies the Pause menu (#44): opening/closing via Escape and buttons,
gameplay actually freezing and resuming correctly, Return to Home Base
working from the new menu, and the two timer fixes (wave spawn pacing and
Emergency Crate wall-damage-reduction) respecting pause instead of ticking
through it.

## Test setup

- Fresh play session, Mission 1 (Defend the Suburbs)
- Tested after opening the project in the Godot editor once, to resolve
  the class_name registration needed for a fresh checkout

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Press Escape mid-mission | Pause overlay appears, gameplay freezes (zombies stop moving, weapon stops rotating) | Confirmed | Pass |
| Press Escape again while paused | Pause closes, gameplay resumes exactly where it left off | Confirmed | Pass |
| Click Resume | Same as above | Confirmed | Pass |
| Click Return To Hub from Pause | Returns to Home Base correctly | Confirmed | Pass |
| Settings button | Shows disabled with tooltip, matching Main Menu convention | Confirmed | Pass |
| Fire/type while Pause is open | Neither reaches gameplay behind the menu | Confirmed | Pass |
| Pause mid wave-spawn-countdown, wait, then resume | Next zombie does not spawn early, waits out remaining interval | Confirmed | Pass |
| Visual check after HUD shrink reapplied onto mission_1.tscn | Mission and Lives panels aligned, no clipping | Confirmed | Pass |

## Issues found

- None during this session.

## Fixes applied

- N/A, this file records testing of the Pause menu feature itself and the
  timer fixes below, not a defect found during this test.

## Follow-up

- None outstanding.
