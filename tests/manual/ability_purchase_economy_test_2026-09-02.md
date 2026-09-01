# Ability Purchase Economy and UI Polish Manual Test — 02 September 2026

**Tester:** Romart Danganan
**Branch:** `romart/ricochet-ability`
**Engine:** Godot 4.7
**Scene:** scenes/ui/ability_select.tscn

## Purpose

Verifies the ability ownership/purchase economy (flat gold cost, buy-then-
equip flow, Spread Shot owned by default) and the Ability Select UI additions
that came with it: hover feedback on equippable cards, buy state on locked
cards, and the gold panel matching Mission Supplies/the Upgrade Shop.

## Test setup

- Fresh game state, no prior purchases, starting gold 500 (temporary
  `UpgradeState` placeholder pending #26)
- Ability Select screen accessed from Home Base

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Fresh state, Spread Shot | Owned by default, equippable, no cost shown | Confirmed | Pass |
| Fresh state, Ricochet | Locked, shows "BUY: 200 GOLD" | Confirmed | Pass |
| Hover an owned, unequipped ability | Border highlights, "CLICK TO EQUIP" shown | Confirmed | Pass |
| Click a locked ability with enough gold | Gold deducted, ability becomes owned (not yet equipped) | Confirmed | Pass |
| Click the same ability again | Ability becomes equipped | Confirmed | Pass |
| Gold panel | Shows "GOLD: N", sits top-right next to Back, updates live on purchase | Confirmed | Pass |
| Unimplemented ability (e.g. Freeze Round) | Still shows "SOON", not purchasable | Confirmed | Pass |

## Issues found

- Gold panel initially rendered on the wrong side of the screen (left
  instead of top-right next to Back), caused by missing the TopBar's
  `alignment = 2` property when the panel was first added.

## Fixes applied

- Restored `alignment = 2` on `ability_select.tscn`'s TopBar and removed an
  unnecessary spacer control, fixing the gold panel position. This landed
  before any commit was made, so it isn't tracked as a separate fix commit.

## Follow-up

- No test yet for the insufficient-gold case (card dimmed, click does
  nothing), since default gold (500) covers every current ability cost.
  Worth revisiting once real gold economy (#26) is wired in with a more
  realistic starting balance.
- Spread Shot vs Ricochet power balance flagged separately as a design
  follow-up, not a bug, see handover notes.
