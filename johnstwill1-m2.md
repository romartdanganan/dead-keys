# William - Milestone 2

## Role and what I own
Gameplay & Mechanics Programmer. I own the Walker enemy, the wave spawning system, and the basic zombie type that can be scaled into more types of zombies. All the tests under the tests/zombie folder are mine as well.

- `Zombie` - shared state machine (Spawn → Approach → Attack → Dead), used
  by every enemy type
- `EnemyTypeDef`, `WaveEntry`, `MissionConfigDef` - data-driven enemy stats
  and wave schedules, so pacing/balance can be adjusted in the Godot Editor rather than code
- `ZombieManager` - wave spawning, spawn-point selection, and wave gating
  (a wave only advances once every zombie from the previous wave is dead)
- Integrating all of the above into the shared `gameplay_prototype` scene
- `Test/Zombie` - testing each component such as shooting the zombie, the waves system, and the initial walking towards the wall system.

## What I contributed to the MVP
- Built the Walker enemy end to end: 3 HP, configurable speed, a word
  displayed above its head, a collision shape for projectile hits, straight
  -line movement to the wall that stops on contact, a `died` signal, and
  removal on death
- Built the wave system as data (`WaveEntry`/`MissionConfigDef`) rather than
  hardcoded spawn loops, and `ZombieManager` to read that data
- Fixed a real bug where waves were advancing as soon as spawning finished
  instead of once the wave was actually cleared. The waves now correctly wait
  for `active_zombies` to empty before the next one starts, and
  `all_waves_cleared` only fires once the whole mission is genuinely done
- Wired `ZombieManager` into the shared `gameplay_prototype` scene: mission
  config, spawn points, and wall target are assigned and the mission starts
  automatically on scene load
- Connected each spawned Walker to the typing system (registering it as a
  valid word target) and to the wall-damage handler (`wall_hit` →
  `wall_health`), so a Walker reaching the wall has a real, testable
  consequence
- Wired mission completion (`all_waves_cleared`) to return the player to
  `home_base.tscn` - no end screen, per the MVP scope, but a full playable
  loop start to finish
- Added a manual single-zombie test scene, a manual full-wave test scene,
  and GUT unit tests for `take_damage()`

## What's real vs faked right now
Walker movement, combat, wave gating, and the full mission-to-home-base
loop are real and working. Not yet real: death animations, zombie object
pooling (currently `queue_free()`s and reinstantiates), and any enemy type
beyond Walker. The state machine supports other types by design, but
Runner/Medic/Spitter/Commander/Exploder aren't built. Wave pacing numbers
(count/interval) are placeholders not yet tuned.

## What I intend to have built by Milestone 3
- Runner as a second enemy type, proving the data-driven system holds up
  beyond one type
- Object pooling for zombies once enemy counts grow
- A real difficulty-scaling pass across waves (currently fixed at 2 waves
  for testing)
- Death animation/feedback instead of an instant despawn
- A balance pass on enemy stats and wave pacing against actual playtest data
- In the case that I hand this component over to Josiah Natanielu and take over the Combat & Juice / FX Programmer role I plan to do this:
- Work on Animations, particle effects, combat hit-feedback, screen shake, visual polish, and making the core typing/shooting loop feel good for the user.
