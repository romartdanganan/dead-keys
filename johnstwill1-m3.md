# William – Milestone 3 (CGRA 359)

**Role:** Gameplay & Mechanics Programmer (enemy systems)

## Rubric weights

| Description | Weight |
|----|----|
| Quality of Game | 30 |
| Development process | 25 |
| Use of Engine features | 45 |
| **Total** | **100** |

I have weighted toward *Use of Engine features* because most of my work was
engine-level architecture: Godot custom Resources for data driven enemies and
waves, a signal-driven state machine, object pooling, scene composition and
manual testing. I kept *Development process* and *Quality of Game*
above the minimum because my work was tracked through detailed issues with
acceptance criteria, and it directly shaped  gameplay.

---

## Contribution claims

| Area | Claim | Notes |
|----|----|----|
| `Zombie` shared state machine (Spawn → Approach → Attack → Dead, plus Support) | **All** | Used by every enemy type; Support state added in M3 without new individual type code, and reused for both the Medic (heal) and the Commander (buff) |
| `EnemyTypeDef`, `WaveEntry`, `MissionConfigDef` (data-driven enemies and waves) | **All** | Stats and wave schedules are editable in the Godot Editor |
| `ZombieManager` (wave spawning, spawn-point selection, wave gating) | **All** | Includes the wave-gating fix and the 360° spawning rework |
| Enemy types: Walker, Runner, Medic, Brute, Commander | **All** | All defined through `EnemyTypeDef`, with no special case spawning code |
| Zombie object pool | **All** | Replaced `queue_free()` / re-instantiate with reusable instances |
| Barrier ring (ring radius, drawn ring, ring-edge wall contact and per-zombie stopping point) | **All** | Replaced the single centre-point wall contact with a ring that zombies spread around |
| `tests/zombie` (GUT) and manual test scenes under `tests/manual/` | **All** | Single zombie, full wave, Runner, Medic and pool-reuse scenes |
| `gameplay_prototype` scene integration (mission config, spawn points, wall target, mission-complete → `home_base.tscn`) | **Some** | Shared scene, so others also edited it; the barrier ring was added to this scene |
| Typing system hooks (zombie registers/unregisters as a word target) | **Some** | Connection point into the typing system, which I did not build |
| Wall damage handler (`wall_hit` → `wall_health`) | **Some** | Connected zombie contact to a real gameplay consequence; ring work kept `wall_contact` / `wall_hit` firing the same way |

---

## What I built in Milestone 3

### 360° directional zombie movement
Replaced the original top of screen approach with a Glyphica inspired system.
Zombies now spawn at a randomised angle around the full 360° range, outside
the visible screen, and move toward the player/base at the centre of the play
area, including diagonal approaches. Multiple zombies can spawn from
different directions at once. I removed the obsolete top down spawn variables
and functions, updated the animations and UI that assumed a single spawn
direction, and tested spawning and movement from all directions with no
regressions to shooting, typing or collision.

### Barrier ring around the base
With 360° spawning, every zombie still walked to the single `WallAttackLine`
point at the centre of the arena and only began attacking within 8px of it, so
they all piled on top of each other in the middle. I added a small visible
barrier ring around the base with a configurable radius (first pass around 90
to 120px), drawn as a simple ring (placeholder until real art exists) so the
player can see where the wall is and which line zombies must not reach.

Zombie wall contact now triggers when a zombie reaches the edge of the ring
rather than the centre point. Each zombie stops at its own point on the ring,
so attackers spread around it instead of sliding to one spot, and none walk
into the centre. This also keeps the HUD area around the centre readable.
`wall_contact` and `wall_hit` fire exactly as before, so wall damage, lives,
the Emergency Crate damage reduction and the combo reset on wall contact all
still work. I checked it against Shockwave Round knockback (a pushed zombie
walks back to the ring and resumes attacking) and Freeze Round, and confirmed
supply crates still land and can be claimed because their landing point stays
outside the ring. The ring is in the Mission 1 scene, which Mission 2 inherits.

### Runner enemy
The second enemy type, built to prove that the data driven architecture holds
up beyond a single type. The Runner is created entirely through the existing
`EnemyTypeDef` system, with its own health, speed and movement behaviour. It
spawns through the normal wave system, can be typed, shot and killed, and
damages the wall. Walker behaviour was left unchanged. It has its own manual
test scene.

### Medic enemy
Implements the Medic from the GDD. It has 25 HP and
baseline speed. Rather than writing a new state machine, I added a **Support
state** to the shared `Zombie` state machine. While in Support, the Medic
heals zombies within range at 10 HP/s. Outside Support it behaves like a
normal zombie (Approach/Attack/Dead). It has a distinct silhouette and
word label border colour to meet the accessibility requirement, and a
manual test under `tests/manual/`.

### Brute enemy
A tank enemy from the GDD, built as a scene variant derived from the shared
zombie base and defined through `EnemyTypeDef`. It has 150 HP and a slow
movement speed, and is assigned to the long-word difficulty tier, so it is
visibly tankier, slower and harder to type out than a standard Walker. It
spawns, approaches and dies through the normal shared state machine with no
special case code. It has a distinct silhouette and word-label border colour so
it is identifiable at a glance.

### Commander enemy
A low-word-length support unit that buffs nearby zombies. It is a scene variant
derived from the shared zombie base with the same health as a Walker, a lower
movement speed than a Walker, and a shorter word length, so it is quick to kill
but a high priority target. Instead of a new class, it reuses the **Support
state** I added to the shared state machine for the Medic: while the Commander
is alive and in Support it buffs zombies within range. Killing the Commander
stops the buff immediately. Its distinct silhouette and word-label border
colour make it readable as a high-priority target.

### Zombie object pooling
Dead zombies are returned to a pool instead of being freed, and are fully
reinitialised when reused. I made sure typing registration and unregistration
stay safe (no duplicate registrations), and that wave tracking still waits for
all active pooled zombies to be cleared before the next wave. A manual test
covers repeated spawning and reuse across waves.

---

## Commentary

- **Data-driven design.** Enemy stats and wave schedules live in Resources
  (`EnemyTypeDef`, `WaveEntry`, `MissionConfigDef`) rather than hardcoded
  spawn loops. Adding Runner, Medic, Brute and Commander required only new
  data plus, for the Medic and Commander, the shared Support state, so pacing
  and balance can be tuned in the editor without touching code.
- **Extensible state machine.** The Medic's healing was added as a Support
  state layered onto the shared machine, as the GDD specified, instead
  of a separate class. The Commander's buff then reused that same state, which
  kept every enemy type on one code path.
- **Gameplay readability.** The barrier ring gives the player a clear line that
  zombies must not reach and spreads attackers around the base, so the centre
  of the screen and HUD stay readable even with 360° waves.
- **Real bug found and fixed.** Early on, waves advanced as soon as spawning
  finished rather than when the wave was cleared. Gating on the
  `active_zombies` set fixed this, and `all_waves_cleared` now fires only when
  the whole mission is genuinely complete. The pooling work later had to keep
  this guarantee, so it was covered by acceptance criteria and tests.
- **Scalability.** Pooling was done deliberately ahead of larger waves so
  enemy counts could grow without constant allocation and freeing.
- **Testing.** Zombie behaviour has GUT unit tests plus manual scenes for a
  single zombie, a full wave, Runner, Medic and pool reuse. Each feature's
  manual test was written as part of its acceptance criteria rather than
  afterwards.
- **Planning and tickets.** Each piece of work above was tracked as an issue
  with a goal, a task checklist and acceptance criteria, and all boxes were
  checked before closing.
- **Design accessibility.** The distinct silhouettes and word-label border
  colours on the Medic, Brute and Commander were implemented to satisfy the
  GDD's accessibility requirement, not just as visual flourishes.


### AI use

Claude and the VSCode copilot extension were used throughout the assignment for debugging, using the autocomplete function, and writing merge and commit messages. While they were used, each part built by AI was tested and edited as necessary. Claude was also used in this milestone document to format it in a cohesive way.