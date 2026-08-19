# AmmoSystem Manual Test — 30 July 2026

**Tester:** Romart Danganan  
**Branch:** `romart/ammunition-system`  
**Engine:** Godot 4.7  
**Scene:** `gameplay_prototype.tscn`

## Purpose

Verify that the prototype ammunition system correctly adds, consumes, caps,
resets and displays ammunition without depending on the unfinished typing or
weapon systems.

## Temporary controls

| Key | Action |
|---|---|
| F4 | Reset current ammunition |
| F5 | Increase capacity by four |
| F6 | Add one ammunition |
| F7 | Consume one ammunition |

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Initial state | Displays 0 / 8 | Displays 0 / 8 correctly on scene load | Pass |
| Add ammunition | F6 increases current ammo by one | F6 increases ammo counter by +1 | Pass |
| Capacity limit | Ammo does not exceed maximum | Capped at maximum capacity; extra ammo ignored | Pass |
| Consume ammunition | F7 decreases ammo by one | F7 decreases ammo counter by -1 | Pass |
| Empty protection | Ammo never becomes negative | Ammo stays at 0 when consuming at 0 | Pass |
| Empty signal | Attempting to consume at zero reports empty | `ammunition_empty` signal emitted when consuming at 0 | Pass |
| Capacity upgrade | F5 changes maximum from 8 to 12 | F5 increases maximum capacity to 12 | Pass |
| HUD label | Label reflects current and maximum values | Label updates dynamically to match current/max ammo | Pass |
| HUD bar | Bar value and maximum match AmmoSystem | Progress bar value and max_value update accurately | Pass |
| Reset | F4 resets current ammo but preserves capacity | F4 resets current ammo to 0 while keeping current max capacity | Pass |
| Scene reload | Mission-local ammo returns to its starting state | Ammo resets to 0 / 8 upon re-entering scene | Pass |

## Issues found

- `F8` and `F9` function keys collide with Godot editor shortcuts (F8 closes the active scene/game instance). Remapped debug shortcuts to `F4` (Reset) and `F5` (Increase Capacity).

## Follow-up

- Remove or disable temporary debug inputs after integration.
- Connect `TypingController.word_completed` to `add_ammunition`.
- Connect weapon firing to `consume_ammunition`.
- Add automated GUT tests when the test framework is configured.
