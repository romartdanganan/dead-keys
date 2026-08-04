# Weapon and Projectile Manual Test — 3 August 2026

**Tester:** Romart Danganan  
**Branch:** `romart/weapon-projectiles`  
**Engine:** Godot 4.7  
**Scene:** `gameplay_prototype.tscn`  
**Overall result:** All tests passed

## Purpose

Verify that the prototype weapon consumes ammunition, fires projectiles toward
the mouse, removes projectiles safely, and damages a generic target without
depending on the unfinished Walker implementation.

## Temporary controls

| Input | Action |
|---|---|
| F6 | Add one ammunition |
| Left mouse button | Attempt to fire toward the crosshair |

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Fire with zero ammo | No projectile is created | No projectile was created and ammunition remained at zero | Pass |
| Add ammo | F6 increases ammunition | Ammunition increased correctly and the HUD updated | Pass |
| Fire with ammo | One ammunition is consumed | One ammunition was consumed for each successful shot | Pass |
| Mouse direction | Projectile travels toward cursor | Projectiles travelled toward the crosshair in the tested directions | Pass |
| Rotation | Projectile faces travel direction | Projectile rotation matched its direction of travel | Pass |
| Lifetime | Projectile removes itself after timeout | Projectiles were removed after the configured lifetime | Pass |
| Screen exit | Projectile removes itself outside viewport | Projectiles were removed after leaving the visible screen | Pass |
| Dummy damage | `take_damage()` is called | The temporary target lost one health for each valid projectile hit | Pass |
| Dummy death | Target is removed at zero health | The temporary target was removed after its health reached zero | Pass |
| Fire cooldown | Rapid clicks are rate-limited | The firing cooldown prevented uncontrolled rapid projectile creation | Pass |
| Dynamic capacity | Weapon works after capacity changes | Firing continued to work correctly after changing ammunition capacity | Pass |

## Issues found

No defects were found during this manual test.

## Important observations

- The weapon refuses to fire when the AmmoSystem cannot consume ammunition.
- A successful shot consumes exactly one ammunition.
- The WeaponController is independent of the TypingController and Walker.
- Projectiles are instantiated under `ProjectileContainer` rather than directly under the gameplay root.
- Projectile direction is calculated from the fixed muzzle position to the mouse position.
- Projectile rotation follows the travel direction.
- Projectiles clean themselves up through both a maximum lifetime and screen-exit detection.
- Damage uses the generic `take_damage(amount)` interface instead of directly depending on the Walker class.
- The temporary projectile test target proves that collision and damage work before the Walker branch is integrated.
- The fixed muzzle point, placeholder projectile visual and dummy target are prototype-only implementations.

## Temporary implementation

- The weapon fires from a fixed `Marker2D` near the wall.
- The visible weapon model and firing animation are not implemented.
- `ProjectileTestTarget` is testing infrastructure, not a final enemy.
- F6 remains a temporary ammunition-generation control.
- Final Walker damage, enemy death and word replacement integration belongs to Issue #12.

## Follow-up

- Integrate the Walker's `take_damage(amount)` method after Issue #11 is merged.
- Connect completed typed words to ammunition gain after Issue #8 is merged.
- Connect enemy death and replacement in Issue #12.
- Add final weapon visuals, firing feedback and audio later.
- Remove or disable temporary debug controls after the complete prototype loop is integrated.
