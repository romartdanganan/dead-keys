# Piercing Shot Ability and HUD Fire-Through Fix Manual Test — 07 September 2026

**Tester:** Romart Danganan
**Branch:** `romart/piercing-shot-ability`
**Engine:** Godot 4.7
**Scene:** `scenes/ui/ability_select.tscn`, `scenes/missions/gameplay_prototype.tscn`

## Purpose

Verifies the Piercing Shot ability (#38) end to end, from Ability Select
purchase through in-mission firing behaviour, and a related HUD fix found
during this session where the crosshair could not fire while hovering over
non-interactive HUD elements.

## Test setup

- Fresh play session, 500 starting gold
- Mission 1 (Defend the Suburbs) used for all in-mission tests
- Ricochet and Spread Shot re-tested alongside Piercing Shot to confirm no
  regression from the shared `_try_damage_target()` dedupe guard

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Piercing Shot card in Ability Select | Shows "Piercing Shot" and "BUY: 200 GOLD" | Correct name and cost shown | Pass |
| Purchase Piercing Shot | Gold deducts, card becomes equippable | Gold deducted, equipped | Pass |
| Charged shot fired into a line of zombies | Damages every zombie in the line, no cap | All zombies in line damaged | Pass |
| Charged shot past the last zombie in line | Projectile keeps travelling, does not free on hit | Continued travelling | Pass |
| Charged shot reaches screen edge | Despawns via existing screen-exit notifier | Despawned correctly | Pass |
| Normal uncharged shot on a zombie | Despawns on first contact as before | Despawned on contact | Pass |
| Ricochet charged shot | Still bounces between targets as before | Unaffected, works as before | Pass |
| Spread Shot charged shot | Still fires spread pattern as before | Unaffected, works as before | Pass |
| Fire while crosshair hovers wall health bar | Shot fires | Shot fired | Pass |
| Fire while crosshair hovers ammo panel | Shot fires | Shot fired | Pass |
| Fire while crosshair hovers lives panel | Shot fires | Shot fired | Pass |
| Fire while crosshair hovers mission name panel | Shot fires | Shot fired | Pass |
| Fire while crosshair hovers combo/ability panel | Shot fires | Shot fired | Pass |
| Fire while crosshair hovers supply slots | Shot fires | Shot fired | Pass |
| Click Return To Hub button | Still returns to Home Base, does not fire | Returned to Home Base correctly | Pass |

## Issues found

- `ability_select.tscn`'s fourth `AbilityRow` node still had its exported
  `ability_id` hardcoded to the old placeholder value `ability_4`, left over
  from before this ability was implemented. This caused the card to show
  fallback placeholder text instead of "Piercing Shot" and blocked purchase
  entirely, confirmed via Godot debug output:
  `WARNING: AbilityRow has unknown ability_id: ability_4`.
- Separately, most HUD panels, labels and progress bars in
  `gameplay_prototype.tscn` did not have `mouse_filter` set, so they defaulted
  to `MOUSE_FILTER_STOP` and intercepted the fire click whenever the crosshair
  was positioned over them. Unrelated to #38, found during manual testing of
  this branch.

## Fixes applied

- Updated the fourth `AbilityRow` node's `ability_id` in `ability_select.tscn`
  from `ability_4` to `piercing_shot`, matching the renamed catalog entry.
- Set `mouse_filter = 2` (Ignore) on all non-interactive HUD container, label
  and progress bar nodes under `HUDRoot` in `gameplay_prototype.tscn`, so
  clicks pass through to the fire input. `ReturnHomeBaseButton` was left
  untouched since it is meant to intercept clicks.

## Follow-up

- `test_ability_catalog.gd` on `romart/gut-testing-setup` hardcodes a
  locked-ability id list and will need `ability_4` removed and the remaining
  slot count updated once that branch is next synced, matching the same
  pattern already hit once before when `ability_2` was renamed to `ricochet`.
- No other HUD scenes currently exist outside `gameplay_prototype.tscn`, but
  this `mouse_filter` convention should be applied to any future mission HUD
  scenes from the start rather than retrofitted.
