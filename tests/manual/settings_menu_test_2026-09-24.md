# Settings Menu Manual Test — 24 September 2026

**Tester:** Romart Danganan
**Branch:** `romart/settings-menu`
**Engine:** Godot 4.7
**Scene:** res://scenes/ui/main_menu.tscn (entry point)

## Purpose

Verify the Settings menu opens correctly from all three entry points, that
audio volume sliders work in real time, that the mistake penalty toggle
affects gameplay, that Display options are correctly disabled in the editor,
that Controls rebinding works for fire and supply keys, that duplicate and
a-z bindings are rejected, and that sold supply slot icons reset correctly.
Also verifies that left-clicking a zombie word label no longer blocks fire.

## Test setup

- Run from Main Menu (default entry scene)
- No prior settings.cfg to avoid carry-over from earlier test runs
  (delete user://settings.cfg if present)
- Mission Supplies requires gold; use debug ammo controls if needed to
  verify supply slot icon reset in-mission

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Settings opens from Main Menu | Settings panel appears with AUDIO tab | Pass | Pass |
| Settings opens from Home Base | Settings panel appears with AUDIO tab | Pass | Pass |
| Settings opens from Pause (mid-mission) | Settings layers on top of Pause menu | Pass | Pass |
| Back closes Settings, returns to correct screen | Correct originating screen visible | Pass | Pass |
| Escape closes Settings (not listening) | Settings closes | Pass | Pass |
| Master slider audibly changes volume | All audio louder/quieter in real time | Pass | Pass |
| Music slider only affects music | SFX unchanged while dragging Music | Pass | Pass |
| SFX slider only affects sound effects | Music unchanged while dragging SFX | Pass | Pass |
| Volume percentages update as sliders move | 0% to 100% labels update live | Pass | Pass |
| Settings persist after closing and reopening | Slider values retained | Pass | Pass |
| Mistake Penalties toggle OFF mid-mission | Typos cost no ammo, no jam triggered | Pass | Pass |
| Mistake Penalties toggle ON mid-mission | Typos cost ammo, jam triggers at 3 | Pass | Pass |
| Display tab: editor shows disabled controls | Both dropdowns greyed, note visible | Pass | Pass |
| Controls tab: Fire shows current binding | Shows "Left Click" by default | Pass | Pass |
| Click Fire, press Space | Fire binds to Space, works in mission | Pass | Pass |
| Click Fire, press Right Click | Fire binds to Right Click | Pass | Pass |
| Click Fire, press Left Click | Fire binds to Left Click (restore) | Pass | Pass |
| Click Fire, press a letter (e.g. A) | Flashes NOT ALLOWED (A-Z), keeps listening | Pass | Pass |
| Escape while listening | Cancels listen, no binding change, menu stays open | Pass | Pass |
| Supply 1 bind to same key as Supply 2 | Flashes ALREADY USED, keeps listening | Pass | Pass |
| Supply 1 bind to right click | Flashes KEYS ONLY, keeps listening | Pass | Pass |
| Supply 1 bind to F5 | Binds to F5, saved and shown on button | Pass | Pass |
| Bindings persist across session | Reload game, bindings still applied | Pass | Pass |
| Click on zombie word label with left click fire | Weapon fires, no click blocked | Pass | Pass |
| Click on supply crate word label | Weapon fires, no click blocked | Pass | Pass |
| Sell a supply in Mission Supplies loadout | Slot icon resets to faded placeholder | Pass | Pass |
| Buy new supply into same slot | New crate icon shown correctly | Pass | Pass |
| BuyButton on supply cards is green | Green colour matching upgrade shop Buy | Pass | Pass |

## Issues found

- None. The AttackTimer double-connection warning from zombie.gd:38 is a
  pre-existing issue from William's scene (noted in handover, not part of
  this branch).

## Fixes applied

- None during testing.

## Follow-up

- Controls tab: Fire is currently mouse-only rebindable in the UI but
  accepts keyboard keys too. Both work correctly.
- Display tab: window mode and resolution need testing in an exported build
  or running the game outside the editor (editor always reports embedded
  window cannot be resized/moved).
- Word difficulty assist and typing speed assist (GDD §2.8) are not exposed
  in the Settings menu yet as no gameplay system backs them. Deferred.
- Colourblind palette and screen-shake/flash toggles: no implementation
  exists yet, intentionally absent from this menu.
- AttackTimer double-connection in zombie.gd: pre-existing, William's file,
  worth a separate issue.
