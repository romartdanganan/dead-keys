# Mission Supplies System Manual Test — 21 August 2026

**Tester:** Romart Danganan  
**Branch:** `romart/mission-supplies-system`  
**Engine:** Godot 4.7  
**Scene:** `mission_supplies.tscn` (purchase flow), `home_base.tscn` (navigation), `gameplay_prototype.tscn` (call/claim/effect verification)

## Purpose

Verify the Mission Supplies system (#29, GDD §2.2.4): up to 3 supplies can
be purchased into numbered slots, calling a supply via number keys 1–3
drops a crate after a delay, typing its word within 8s claims it and
applies the correct effect, and the loadout resets between missions.

## Test setup

- Gold came from the shared `UpgradeState.gold` pool, the same one the
  Upgrade Shop (#25) uses, not a separate pool.
- Purchase flow tested via Home Base → Supplies.
- Call/claim/expiry flow tested via Home Base → Launch Mission, using the
  purchased loadout.
- This test pass includes two rounds of fixes made after issues were found
  during earlier manual testing (see Issues found / Fixes applied below),
  both re-verified before this record was written.

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Shop opens | Supplies button on Home Base opens the shop with 3 loadout slots and a 2x2 grid of 4 crate cards | Opens correctly | Pass |
| Purchase into empty slot | Buying a crate spends gold and fills the selected slot | Gold deducted correctly, slot updated | Pass |
| Cannot overwrite an occupied slot | Buying while an occupied slot is selected does nothing destructive | BUY button shows "SLOT FULL" and disables, no purchase possible | Pass |
| Sell an equipped supply | Hovering an occupied slot shows "SELL FOR X GOLD?"; clicking refunds the cost and empties the slot | Confirmed, gold refunded exactly, slot cleared | Pass |
| Select an empty slot | Clicking an empty slot marks it as the active purchase target | Confirmed, border highlights green | Pass |
| Insufficient gold | BUY disables when gold is short of a crate's cost | Confirmed | Pass |
| Loadout carries into mission | HUD supply slot icons reflect the purchased loadout on mission start | Confirmed, occupied slots lit, empty slots dimmed | Pass |
| Call a supply | Pressing 1/2/3 for an occupied slot starts a 3s countdown shown on screen | "[CRATE NAME] landing in 3... 2... 1..." displayed correctly, no silent wait | Pass |
| Crate lands clearly visible | Crate appears above `CombatUtilityPanel`, not overlapping it | Confirmed after repositioning to the panel's right side | Pass |
| Claim a crate | Typing the crate's word within 8s claims it and applies its effect | Confirmed for all 4 crate types | Pass |
| Miss a crate | Letting the 8s timer expire despawns it with no effect | Confirmed | Pass |
| One crate at a time | Calling a second supply while one is active/pending does nothing | Confirmed | Pass |
| Slot used once per mission | Calling the same slot again after use does nothing | Confirmed | Pass |
| Ammo Crate effect | Refills ammunition to maximum | Confirmed | Pass |
| Medical Crate effect | Repairs 50% of max wall health | Confirmed | Pass |
| Combat Crate effect | +50% bullet damage for the rest of the mission | Confirmed | Pass |
| Emergency Crate effect | Halves wall damage taken for 15s and refills 50% ammunition | Confirmed, damage reduction expires correctly after 15s | Pass |
| Loadout resets after mission | Returning to Home Base (win, lose, or manual return) empties all 3 slots | Confirmed via all three exit paths | Pass |

## Issues found

- First pass: buying into or clicking an occupied slot silently overwrote/
  cleared it with no refund, an actual money-loss bug, not just missing
  polish.
- First pass: crate landing point overlapped the left edge of
  `CombatUtilityPanel`, partially obscuring the crate.
- First pass: the 3s flight delay was a silent wait with no on-screen
  feedback.
- First pass: Emergency Crate's jam-clear effect was weak in practice,
  typing the crate's own word takes about as long as the jam it would
  clear.
- Second pass: the fix for the overwrite bug (a plain clear) still lost the
  player's gold, just without also losing a second purchase on top of it.

## Fixes applied

- `SupplyState.purchase_into_slot()` now refuses to write into an occupied
  slot at the data level, not just in the UI.
- Added `SupplyState.sell_slot()`: refunds the original cost and empties
  the slot. Hovering an occupied slot now previews "SELL FOR X GOLD?";
  clicking it sells rather than silently discarding it.
- Moved `SupplyLandingPoint` clear of `CombatUtilityPanel`, now above its
  right side rather than overlapping its left.
- Added a HUD countdown label showing "[CRATE] landing in N..." during the
  flight delay.
- Redesigned Emergency Crate: 50% wall damage reduction for 15s plus a 50%
  ammo refill, instead of jam-clear.

## Follow-up

- GDD §2.2.4 doesn't currently specify crate effects or exact numbers;
  needs a design note once these are considered final, documenting all 4
  effects as implemented and the Emergency Crate change and why.
- BUY button styling (white bold text, black outline) is missing true bold
  weight since no font asset exists yet in `assets/fonts/`; outline-only
  for now.
- Effect numbers (refill amounts, damage percentages, durations) are a
  first-pass judgment call, not GDD-specified; worth a second look once
  playtesting gives real data, per the same note already in `SupplyCatalog`.
