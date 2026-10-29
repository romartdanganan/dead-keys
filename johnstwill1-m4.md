# William Johnston – Milestone 4 (CGRA 359)

**Course:** CGRA 359 (30 points, Trimester 2, 2026)
**Username:** johnstwill1
**Role:** Gameplay & Mechanics Programmer (enemy systems: enemies, wave spawning, pooling)
**Game:** Dead Keys

## Rubric weights

| Description | Weight (min–max) |
|----|----|
| Code video | 10 (10–20) |
| Good Code | 30 (10–30) |
| Bad Code | 15 (10–30) |
| Development process | 15 (10–30) |
| Reflection | 30 (10–40) |
| **Total** | **100** |

I weighted toward *Good Code* because most of my work was
engine-level architecture (custom Resources, a shared state machine, pooling),
which is where I have the most to show and discuss. I kept Reflection at the
default because I have good raw material from the ticket history.

---

## Team Summary (Milestone 3)

### Team members and roles

| Name | Role |
|----|----|
| Romart Danganan | Design lead, lead programmer, producer, integration and testing |
| William Johnston | Gameplay & Mechanics programmer: enemies, wave spawning, pooling |
| Nicole Lai | Tools & systems programmer: progression, gold and save, word lists |
| Josiah Natanielu | Systems programmer: mistake and combo systems, audio |

(All CGRA359 Students)

### Repositories and links

- Game repository (code, GDD, Tech Spec, all assets via Git LFS):
  https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys
- No other repos are needed to assess the game; everything is in the one repo.
- Docs in the repo: `GDD.md`, `Dead_Keys_TechSpec.md`, `README.md` (build and run, controls, tests)
- Test records: `tests/unit/` (GUT), `tests/zombies/` (my isolated enemy scenes), `tests/manual/`, `playtesting/`
- Gameplay video (Milestone 2 MVP): https://youtu.be/PhkkVE3Z474
- Gameplay video (current build): https://www.youtube.com/watch?v=Dwt_8BhijVM

---

## Code video

**Video link:** TODO

The video should show code tied tightly to the Godot engine that is hard to judge
from the text alone. Suggested shots:

1. **Custom Resources in the Inspector.** Open an `EnemyTypeDef`, `WaveEntry` and
   `MissionConfigDef` in the editor, change a stat or wave schedule, run the game,
   and show the change with no code edits.
2. **The shared state machine live.** In a single-zombie test scene show Spawn →
   Approach → Attack → Dead, then a Medic (heals) or Commander (buffs) in the
   Support state, and a Freeze Round putting a zombie into its frozen state.
3. **360° spawning and the barrier ring.** Zombies arriving from several angles,
   each stopping at its own point on the ring, and a Shockwave knockback sending one
   back to the ring to attack again.
4. **Object pooling.** The pool-reuse test scene across several waves: instances
   reused rather than freed, no duplicate typing registrations.
5. **Wave gating.** A wave only advances when `active_zombies` is empty, and
   `all_waves_cleared` fires only at the end of the mission.

---

## Good code

### 1. Data-driven enemies and waves (`EnemyTypeDef`, `WaveEntry`, `MissionConfigDef`)
**Link:**  [EnemyTypeDef](https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys/-/blob/dev/scripts/resources/enemy_type_def.gd?ref_type=heads), [WaveEntry](https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys/-/blob/dev/scripts/resources/wave_entry.gd?ref_type=heads), [MissionConfigDef](https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys/-/blob/dev/scripts/resources/mission_config_def.gd?ref_type=heads)

Enemy stats and wave schedules live in Godot Resources rather than hardcoded spawn
loops (my M2 intent: pacing and balance adjustable in the editor, not in code).
That bet paid off: Runner, Medic, Brute and Commander were all added through
`EnemyTypeDef`, with no special-case spawning code. I was able to tune without
touching scripts, and the Resources are easy to inspect and test.

### 2. Shared `Zombie` state machine with a Support state
**Link:** [Zombie](https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys/-/blob/dev/scripts/entities/zombie.gd?ref_type=heads)

Every enemy runs one state machine (Spawn → Approach → Attack → Dead). When the
Medic needed to heal, I added a Support state (with `heal_per_second` and
`support_radius` fields on `EnemyTypeDef`) instead of a new class, as the GDD specified. The Commander's buff then reused it, so a new support enemy cost
data plus a small behaviour change rather than entirely new code.

### 3. `ZombieManager` wave gating
**Link:** [ZombieManager](https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys/-/blob/dev/scripts/systems/zombie_manager.gd?ref_type=heads)

My M2 bug: waves advanced as soon as spawning finished, not once the wave was
cleared. The fix was on the `active_zombies` set, and `all_waves_cleared` only
fires when the mission is genuinely done. It is good code because the rule is simple
and lives in one place, and it survived pooling and 360° spawning because it was in
the acceptance criteria and tests.

### 4. Zombie object pool (`zombie_pool.gd`)
**Link:** [ZombiePool](https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys/-/blob/dev/scripts/resources/zombie_pool.gd?ref_type=heads)

M2 explicitly listed pooling as not yet real (`queue_free()` and re-instantiate).
In M3 dead zombies return to a pool and are fully reinitialised on reuse. The tricky
parts were typing registration (no duplicates) and keeping wave tracking waiting for
all active pooled zombies.

### 5. Ring-edge wall contact
**Link:** [BarrierRing](https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys/-/blob/dev/scripts/entities/barrier_ring.gd?ref_type=heads)

Wall contact moved from a single centre point to the edge of a configurable ring,
with each zombie stopping at its own point. `wall_contact` and `wall_hit` still fire
exactly as before, so wall damage, lives, Emergency Crate reduction and the Combo
reset (which listens to `wall_contact`) needed no changes. Keeping those signals
stable made a gameplay change low-risk across systems that other people own.

---

## Bad code

### 1. Zombie proximity checks do not scale well

**Link:** [Zombie](https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys/-/blob/dev/scripts/entities/zombie.gd?ref_type=heads)

Support-target selection, Commander detection and movement-speed buffs all
iterate through `get_tree().get_nodes_in_group("zombies")`. These checks can
run for every zombie during every physics frame. As the number of zombies
increases, the amount of work approaches O(n²), because each zombie repeatedly
checks the other zombies.

This is acceptable for small test waves, but it could cause performance
problems in larger missions and makes the shared `Zombie` script responsible
for several global searches.

*Next time:* use a dedicated support or proximity system, cached Commander
data, or a spatial lookup so zombies do not repeatedly scan every zombie in
the scene.

### 2. Important integration behaviour still depends on manual testing

**Link:** [Zombie tests](https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys/-/tree/dev/tests/zombies?ref_type=heads)

Automated tests cover many core cases, including pool reuse, wave gating,
death animation timing, Medic healing, freezing and knockback. However, some
important integration paths still rely on manual scenes and visual judgement.

*Next time:* convert the highest-risk manual checks into deterministic GUT
integration tests. In particular, test that a pooled zombie is registered
with typing exactly once after being reused, or that an ability affects only
zombies inside its radius.

---

## Development process

- **Ticket discipline.** Each piece of work (360° movement, ring, Runner, Medic,
  Brute, Commander, pooling) was an issue with a goal, task checklist and acceptance
  criteria. Manual tests were part of the criteria, not an afterthought.
- **Acceptance criteria as a safety net.** The wave-gating guarantee was written into
  the pooling ticket so the rework could not reintroduce the early-advance bug.
- **Proposing process.** I suggested the `dev` integration branch, adopted by the team
  in sprint 2 to protect `main`.
- **Incremental architecture.** Walker established the machine; Runner proved the
  data-driven design held beyond one type; Medic forced the Support state; Brute and
  Commander confirmed both.
- **What did not work as planned:** Towards the end of our project, I found myself writing less detailed merge and commit descriptions, leaving it to the GitHub copilot extension to write it for me. While I did read and change whatever was needed, the descriptions were brief and less detailed. 

---

## Reflection

### My M2 plan versus what I delivered

| M2 intention | Outcome |
|----|----|
| Runner as a second enemy type, proving data-driven design | Done in M3 |
| Object pooling | Done in M3 |
| Real difficulty-scaling pass across waves (was fixed at 2 test waves) | Done in M3 |
| Death animation / feedback instead of an instant despawn | Taken over by other members |
| Balance pass on enemy stats and wave pacing from playtest data | Done in M3/M4 |
| Contingency: hand enemies to Josiah and move to Combat/FX | Did not happen; I stayed on enemies and added Medic, Brute, Commander, 360° and the ring |


### What went right and wrong

**5 things that went right**
1. Data-driven enemies made each new type cheap, which is the clearest return on an
   early architectural bet.
2. Extending one shared state machine kept every enemy on one code path.
3. Ticket acceptance criteria (including tests) stopped regressions across pooling,
   360° spawning and the ring.
4. Planned technical debt: I knew `queue_free()` and re-instantiate was temporary and
   paid it back with pooling before waves grew.
5. Keeping `wall_contact` / `wall_hit` stable let the ring change land without
   touching other people's systems.

**5 things that went wrong**
1. Waves advanced when spawning finished rather than when they were cleared, found
   only by playing.
2. Zombie stacking at one point, flagged in the GDD but not built, appeared only
   after 360° spawning.
3. Top-down spawn assumptions leaked into animation and UI, forcing a cleanup.
4. Behaviour accumulated inside `zombie.gd` against the Tech Spec's own plan.
5. Balance and pacing work: Since our playtests were mostly internal, difficulty may not be tuned to a general audience

### Key concepts I learnt

> Marked on your own learning. Replace these starting points with specifics from
> your own notes and say when each one clicked.

- **Data-driven design in Godot.** Custom Resources let a designer change behaviour in
  the Inspector without editing code. This was something that I hadn't thought of previously but found it extremely useful when tuning the game.
- **State machines and signals.** A signal-driven machine keeps enemies decoupled from
  typing, wall damage and wave tracking; stable signal contracts (`wall_contact`,
  `wall_hit`, `died`). State machines and signals were omething that I had learnt in a second year SWEN course, and learning to apply them here was a satisfying full circle moment.
- **Object lifecycles.** A pooled node must be fully reinitialised on reuse and must
  register and unregister with other systems exactly once, or bugs appear only on the
  second spawn. This was something I had never considered previously, but learning how it can affect performance especially in our style of game was interesting to figure out

- **Documentation as a system.** Docs only help if they are kept in sync; our GDD and
  Tech Spec drifted behind the build and needed explicit sync tickets (#16, #51).
### Using the in-action reviews

TODO: cite one or two moments from your notes where a review changed what you did.
Candidates: the wave-gating bug found in testing; the multi-Walker typing break on
the #22 branch; the decision to add the ring after seeing zombies stack.

### AI use

Claude and the VSCode copilot extension were used throughout the assignment for debugging, using the autocomplete function, and writing merge and commit messages. While they were used, each part built by AI was tested and edited as necessary.

### What I will take forward

- Design for data first: enemies, waves and tuning as editable Resources.
- Write acceptance criteria and a test alongside each ticket; automate anything that
  only fails on the second run.
- - Keep docs in sync as part of done, not as a catch-up task.

### What I would do differently

- Plan 360° spawning and wall contact together instead of finding the stacking problem
  afterwards.
- Attach per-enemy behaviours as components or data, as the Tech Spec intended, rather
  than adding states to one script.
- Schedule balance and polish (death feedback, wave pacing) as tickets with playtest
  input, not leftover work.
- Convert the manual pool and wave tests into GUT tests earlier.