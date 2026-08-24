# Home Base Upgrade Shop Manual Test — 20 August 2026

**Tester:** Romart Danganan  
**Branch:** `romart/home-base-upgrade-shop`  
**Engine:** Godot 4.7  
**Scene:** `upgrade_shop.tscn` (purchase flow), `home_base.tscn` (navigation), `gameplay_prototype.tscn` (effect verification)

## Purpose

Verify the Home Base upgrade shop (#25): all 7 Permanent Upgrade Tracks from
GDD §2.6.1 can be purchased up to their documented max level for the
documented cost, purchases are blocked when gold is insufficient, and each
track's effect is visible in gameplay immediately after purchase.

## Test setup

- Gold and purchased levels for this pass came from the temporary local
  `UpgradeState` autoload (starting gold: 500), not a persistent save —
  persistence is explicitly out of scope for this issue and belongs to #26.
- Purchase flow tested via Home Base → UPGRADES → Upgrade Shop.
- Effect application tested via Home Base → Launch Mission →
  `gameplay_prototype.tscn`, purchasing an upgrade, then relaunching the
  mission to observe the change.
- Known exclusion: gold/upgrade-level persistence across a full game restart
  was not tested here, since that belongs to #26's save/load system.

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Shop opens | UPGRADES button on Home Base opens the shop, showing all 7 tracks grouped Weapon/Base | Shop opens correctly, all 7 rows present and grouped | Pass |
| Initial gold display | Shop's own gold display matches `UpgradeState` starting gold | Displayed correctly on open | Pass |
| Purchase a track | Buying a level spends the documented gold cost and advances that track's level/value | Gold decremented by exact documented cost; level and current-value labels updated | Pass |
| Cost scaling | Next-level cost shown matches GDD §2.6.1 for each level of each track | Verified against GDD table for all 7 tracks | Pass |
| Max level reached | Buy button reads "MAXED" and disables once a track's final level is bought | Confirmed on all 7 tracks | Pass |
| Insufficient gold | Buy button disables when gold is less than the next level's cost | Confirmed by spending down gold near zero | Pass |
| Back navigation | BACK button returns cleanly to Home Base | Returns correctly, no errors | Pass |
| Fire Rate effect | Shots/s visibly increases after purchase | Faster firing observed after purchasing each level | Pass |
| Bullet Damage effect | Zombies take more damage per hit after purchase | Zombie health drops by the upgraded amount per hit | Pass |
| Magazine Capacity effect | Max ammo shown on HUD increases after purchase | Ammo HUD max value increased to match upgrade | Pass |
| Fortified Wall effect | Wall HUD max HP increases after purchase | Wall HUD max value increased to match upgrade | Pass |
| Extra Life effect | Lives HUD shows purchased life count; wall resets to 50% HP instead of ending the mission when a life remains | Lives icons lit correctly; wall reset to 50% and mission continued on first life loss, returned to Home Base only on the last | Pass |
| Jam Duration effect | Weapon jam lasts the upgraded (shorter) duration after purchase | Jam duration visibly shorter after purchase | Pass |
| Mistake Leniency effect | More consecutive mistakes tolerated before ammo is lost, after purchase | Ammo no longer lost on the first mistake once purchased; still jams at 3 consecutive mistakes regardless | Pass |

## Issues found

- None. All 7 tracks purchased cleanly up to max level and every effect was
  visibly reflected in gameplay on this pass.

## Fixes applied

- N/A — no defects found during this test pass.

## Follow-up

- Re-test gold/upgrade-level persistence once #26 (`ProgressionManager`)
  lands and `UpgradeState` is replaced.
- Re-confirm the Mistake Leniency interpretation against design intent
  during review (documented as a judgment call in the MR).
