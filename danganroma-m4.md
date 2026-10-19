# Milestone 4: Romart Danganan (danganroma)

## Weights

| Criterion | Weight | Default | Range |
|---|---|---|---|
| Code video | 15 | 15 | 10 to 20 |
| Good code | 20 | 20 | 10 to 30 |
| Bad code | 20 | 20 | 10 to 30 |
| Development process | 25 | 20 | 10 to 30 |
| Reflection | 20 | 25 | 10 to 40 |
| **Total** | **100** | | |

**Development process (25, up from 20).** I ran the team's process from the first issue to the final merge: issues, sprints, branching rules, reviews, the `dev` into `main` syncs, automated and manual testing, and a dated log of every working session. It is the best evidenced part of my work.

**Reflection (20, down from 25).** I still put real effort into the reflection, but I would rather the process work I can show in the repository carry more of the mark.

## Team summary (Milestone 3)

- Romart Danganan (CGRA 359, lead programmer, project manager, integration and testing lead, GDD author)
- William Johnston (CGRA 359, gameplay and mechanics programming: enemies, wave spawning, object pooling, barrier ring)
- Nicole Lai (CGRA 359, tools and systems programming: typing controller foundation, progression and save, mission unlocks, word lists, zombie sprite sheets)
- Josiah Natanielu (CGRA 359, FX and audio programming: mistake and combo systems, audio and sound effects, mission end screens, How to Play)

All four of us are CGRA 359 programming students; no GAME 390 design students joined. I drew the HUD icons, supply crates, coin and medals; my partner drew the Main Menu and Home Base backgrounds and logos.

**Repositories.** Everything is in one repository: https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys.

**Gameplay video.** https://www.youtube.com/watch?v=Dwt_8BhijVM (also linked in [milestone3.md](milestone3.md)).

**The game.** Dead Keys is a 2D top-down zombie defence game in Godot 4.7 where typing the word above a zombie loads ammo and the player aims and fires by hand. It shipped with three campaign missions, Endless mode, six zombie types including a three phase Tank boss, eight abilities, seven upgrade tracks, four supply crates, medals, a Settings menu with an Accessibility tab, tutorial callouts and a How to Play page.

**Development process.** Two-week sprints; one GitLab issue per feature with goals, tasks and acceptance criteria; feature branches merged into a `dev` integration branch through reviewed Merge Requests, and `dev` into `main` at milestones; Git LFS from the first day; 299 automated tests and 22 manual test records; three playtests that changed the design. Strengths: the integration branch, reviews in a separate worktree that caught bugs before merge, and playtest-driven design. Weaknesses: three of the six planned missions, most features landing in the final sprint, no design students, and retrospectives and playtest #2 not written down at the time. The full group discussion is in [milestone3.md](milestone3.md).

![Tank boss phase 2](images/milestone3/19_boss_phase_2_roar.png)

## Code video

**Link:** https://youtu.be/3SKTj20CsfE

The video shows code that only makes sense when you see the engine running it:

1. **Equal arrival at the ring** ([zombie_manager.gd](scripts/systems/zombie_manager.gd), `spawn_position()` and `travel_scale_for()`). Spawn five Walkers at once from the right, bottom, left, top and a corner with the barrier ring visible, and show them reaching the ring together, then walk through the speed scale maths.
2. **Input order and rebinding** ([settings_menu.gd](scripts/ui/settings_menu.gd), `_input()`). Rebind fire to Space, then back to left click with the mouse over the Back button, while explaining why the capture runs in `_input()`: Godot sends events to `_input()`, then the GUI, then `_unhandled_input()`, and any Control under the mouse takes the click first.
3. **Physics callbacks and deferred changes** ([projectile.gd](scripts/entities/projectile.gd), the zombie death code in [zombie.gd](scripts/entities/zombie.gd), [boss_fight.gd](scripts/missions/boss_fight.gd)). Fire into a dying zombie and at the Tank's helpers with collision shapes visible, and show why collision changes inside `area_entered` need `set_deferred()`.
4. **Pooled zombies, signals and animation** ([zombie_manager.gd](scripts/systems/zombie_manager.gd), [mission_1.gd](scripts/missions/mission_1.gd) `_on_zombie_spawned()`). Show one zombie node recycled as a cat, then a dog, the `AnimationPlayer` keying the sprite sheet per animation, release on `death_finished`, and why every connection to a pooled node is named and guarded.
5. **Boss finale and the Endless game over screen** ([boss_fight.gd](scripts/missions/boss_fight.gd), [screen_shake.gd](scripts/missions/screen_shake.gd), [endless_game_over.gd](scripts/ui/endless_game_over.gd)). Kill the Tank and show the zoom and slow motion running on real time while `Engine.time_scale` is lowered, then the game over card popping in and the score counting up.

## Good code

### 1. Equal arrival time from every side

[scripts/systems/zombie_manager.gd](scripts/systems/zombie_manager.gd): `spawn_position()`, `travel_scale_for()`, `pick_spawn_angle()`.

The screen is 1280 by 720, so zombies from the top or bottom used to arrive far sooner than zombies from the sides. `spawn_position()` places each zombie just past the screen edge along its direction (the distance to the edge is the smaller of half width over the x direction and half height over the y direction, plus a margin), so nothing walks for 16 seconds off screen first. `travel_scale_for()` then gives each zombie a speed multiplier of its walk to the ring divided by a fixed reference walk (732 pixels, the side walk from before the ring existed). Five Walkers spawned together from five directions reached the ring at 24.0 to 24.8 seconds. Both functions are static and take plain values, so [test_zombie_manager.gd](tests/unit/test_zombie_manager.gd) checks every direction, that changing the ring size does not change arrival time, and that it stacks with the accessibility speed setting. One constant, `ZOMBIE_PACE`, can slow the whole game without breaking the equal arrival.

### 2. Shared weapon checks and one place for abilities

[scripts/systems/weapon_controller.gd](scripts/systems/weapon_controller.gd): `try_fire()`, `try_fire_ability()`, `_take_shot()`.

Every shot has to pass the same checks: the scene is set up, the gun is not jammed, the cooldown is over and there is ammo. `_take_shot()` holds those checks once and gives the right feedback for each failure (the jammed sound, the empty sound, and the signal behind the "TYPE A WORD TO RELOAD" prompt). `try_fire()` is a normal shot and `try_fire_ability()` is the charged shot on its own input. Before #64 this was one function with an `elif` per ability, each repeating parts of the checks. Now adding an ability is one `match` arm and one `_fire_*` function, and the rules about when a shot can happen cannot drift apart. The weapon gets its dependencies through `configure()` and `set_zombie_manager()`, so [test_weapon_ability.gd](tests/unit/test_weapon_ability.gd) tests it without a mission scene.

### 3. One typing controller for every word on screen

[scripts/typing/typing_controller.gd](scripts/typing/typing_controller.gd): `register_target()`, `check_letter()`, `_complete_target()`, `get_ammo_reward_for_word()`.

The first design gave each zombie its own controller, so only the newest zombie could be typed once several were on screen. I rewrote it as one controller holding every live word. Each key extends a shared prefix, every word that still matches stays highlighted, and the player can type any zombie in any order. Words on screen are always unique, so a prefix always narrows to one target. A finished word gives the same living zombie a new word instead of removing it, so the player can always earn ammo while a zombie is alive. `unregister_target()` only emits when something was really removed, which is what fixed the combo overcount on pooled zombies (#41). The ammo table is a static function, so [test_ammo_reward.gd](tests/unit/test_ammo_reward.gd) checks every tier boundary without a scene.

### 4. Rebinding that works with the engine's input order

[scripts/ui/settings_menu.gd](scripts/ui/settings_menu.gd) (`_input()`, `_try_apply_binding()`) and [scripts/autoload/settings_state.gd](scripts/autoload/settings_state.gd) (`_bind_key()`, `_bind_mouse()`, `is_key_taken()`).

While a button is listening for a new key, the menu captures input in `_input()` and marks every event handled, because the GUI would otherwise swallow mouse clicks first. Every bind button is disabled with focus off while listening, so Space or Enter cannot press the button again. Letters are refused because they are the typing keys, and one duplicate guard covers fire, ability and the three supply keys. Bindings go into `InputMap` at runtime and are saved with `ConfigFile`; on load the old bindings are cleared first so swapped keys never clash with the defaults. I found the real cause of the original bug with a probe scene that sends real events through `Viewport.push_input()`, and [test_settings_bindings.gd](tests/unit/test_settings_bindings.gd) keeps it fixed.

### 5. Typing statistics that measure the right thing

[scripts/missions/mission_rating.gd](scripts/missions/mission_rating.gd): `record_correct_stroke()`, `get_words_per_minute()`, `grade()`.

The first WPM divided keystrokes by the whole run, so round breaks made every player look slow. Now only the gaps between keys inside a word are timed, with one character counted per gap, because a word of n letters has n minus 1 gaps (counting all n would make short words read about 50% too fast, exactly in Endless round 1 where the words are shortest). A gap over 1.5 seconds is skipped, and real time is used so the boss slow motion does not change it. `record_correct_stroke()` takes the timestamp as an argument, so [test_mission_rating.gd](tests/unit/test_mission_rating.gd) feeds exact times with answers worked out by hand (5 keys 0.2 seconds apart is 60 WPM). Medal grading is a pure static function with named thresholds, and accessibility options never lower the medal.

## Bad code

### 1. `mission_1.gd` is a god script, and other missions inherit from it

[scripts/missions/mission_1.gd](scripts/missions/mission_1.gd), [mission_2.gd](scripts/missions/mission_2.gd), [mission_3.gd](scripts/missions/mission_3.gd).

`mission_1.gd` is 785 lines and handles setup, input, waves, supplies, lives, HUD updates, pause and settings, win and lose, medals and hold to fire. Missions 2 and 3 and Endless extend it with `extends "res://scripts/missions/mission_1.gd"`, so every mission depends on a file named after one mission, and both mission scripts carry an identical copy of `_make_wave()`. It grew this way because Mission 1 was built first and each feature went where it was easiest. **Better:** a `mission_base.gd` with only the shared flow, each mission described as data (a `MissionConfigDef` with its waves in a `.tres` file), the remaining jobs split into feature nodes like `combat_feedback.gd`, and `_make_wave()` written once.

### 2. One boolean flag per ability on the projectile

[scripts/entities/projectile.gd](scripts/entities/projectile.gd) (`is_piercing`, `is_freeze_round`, `is_explosive`, `is_homing`, `is_shockwave` and their settings) and the string ids in [weapon_controller.gd](scripts/systems/weapon_controller.gd).

Each ability added another flag and another branch to the projectile's hit code, so the projectile knows about every ability in the game. The ids are plain strings repeated across the catalog, the weapon and the UI, and a typo falls through silently to a normal shot. **Better:** an `AbilityDef` resource per ability with `on_fire()` and `on_hit()` methods that the projectile calls without knowing which ability it is, so a new ability is one file and ids are checked in one place.

### 3. Reaching into other nodes by path and private fields

[scripts/ui/home_base.gd](scripts/ui/home_base.gd) `_on_gold_changed()`, [scripts/ui/wave_counter.gd](scripts/ui/wave_counter.gd), [scripts/missions/tutorial_callouts.gd](scripts/missions/tutorial_callouts.gd), [weapon_controller.gd](scripts/systems/weapon_controller.gd).

Home Base sets the gold text through a seven level node path instead of a `%` unique name, so moving one panel in the editor breaks it at runtime. The wave counter reads `ZombieManager._max_display_wave_number`, a private field. The tutorial callouts check the weapon's jam flag every frame because the mistake system has no jam signal, and that flag is still called `set_jammed`, which reads like a function, even though renaming it to `is_jammed` was written into issue #20 at Milestone 2. **Better:** `%` unique names for scene nodes, a public getter or signal for the wave total, a `jam_started` signal, and fixing a known bad name when it is first noticed.

### 4. Signal connections that pile up on pooled nodes

[scripts/missions/mission_1.gd](scripts/missions/mission_1.gd) before #41, `zombie.tscn` and `zombie.gd` before the AttackTimer fix, and [supply_card_row.gd](scripts/ui/supply_card_row.gd) today.

I connected a new anonymous lambda to each zombie's `died` signal every time it spawned. That was fine while zombies were freed on death, but pooling reuses the node, and Godot cannot tell two lambdas apart, so a recycled zombie collected one more connection each life and the combo jumped by 3 or 4 for one kill. The same kind of bug sat for weeks as the "AttackTimer timeout is already connected" error because the timer was connected in the scene and again in `_ready()`, and playtest #3 found the same pattern still in my `supply_card_row.gd`, which connects its Buy button in code while the scene already connects it. **Better:** connect in one place only (scene or code, never both), named handlers with `is_connected()` guards on anything reused, and treating engine errors in the output as failures.

### 5. Changing physics state inside a physics callback

The death code in [scripts/entities/zombie.gd](scripts/entities/zombie.gd) and the summons in [scripts/missions/boss_fight.gd](scripts/missions/boss_fight.gd), before #69.

When a bullet killed a zombie, my death animation code disabled its collision shape straight away. Bullets hit zombies inside `area_entered`, where Godot refuses physics changes, so the call failed with only an error in the output and the corpse kept blocking bullets. The boss summoned helpers from the same callback, so their hitboxes never set up and they could not be shot. My unit tests passed because they called `take_damage()` directly, outside the physics step. **Better:** `set_deferred()` and `call_deferred()` for anything that changes physics from a hit, which is what the fix does, and tests that fire real projectiles so they take the same path as the game.

## My part in the development process

- **Planning.** Wrote every GitLab issue with goals, tasks, acceptance criteria, labels and weights; ran the 2 Sep sprint planning that moved work off me; ran the 3 Oct check-in where each teammate picked named issues; wrote the 3 Oct roadmap with the scope cut and the decision date for Mission 4.
- **Branching and merging.** Set the branch, commit and MR conventions and the `dev` branch, reviewed teammate MRs in a separate worktree with the full GUT suite, rehearsed risky rebases in a throwaway clone, and synced `dev` into `main` at milestones (#53).
- **Testing.** Set up GUT and wrote 289 of the 299 tests, wrote all 22 manual test records, and ran the three playtests.
- **Record keeping.** Kept a dated log for every working session with what changed, why, root causes and what was pending. It is the raw material for this reflection.

| Sprint | What went well | What went badly | What changed afterwards |
|---|---|---|---|
| 1 (1 to 7 Aug) | LFS set up before any binary; a backbone for teammates to build on | Ownership of each system was not written down yet | Named roles in `milestone2.md` |
| 2 (7 to 14 Aug) | Hit the MVP date with days to spare | Nothing major; MRs merged straight into `main` | Added a `dev` integration branch (William's suggestion) as an extra safety layer before `main` |
| 3 (14 to 28 Aug) | GUT introduced early; a placeholder save system let UI work start before the real one | The placeholder became a dead autoload that broke tests later | Remove placeholders as soon as the real system lands |
| 4 (28 Aug to 11 Sep) | Art and a readable font made it look like a game; reviews caught real bugs | Nearly lost the HUD and crate art to a stash; dropped Josiah's history; playtest #2 not recorded | Copy art, never move it; never rebuild a teammate's history |
| 5 (11 to 25 Sep) | Settings became one of the most polished parts | A ten day gap; guessed fixes only checked by boot; wrong issue numbers | Verify behaviour, not just parsing; test fixes go under #34 |
| 6 (25 Sep to 14 Oct) | Every teammate on named issues; playtesting changed the design | Overreached into Nicole's #32; the plan was too big and most features landed in one sprint | Check the board before widening scope |
| 7 (14 to 23 Oct) | Feature freeze held; GDD and Tech Spec synced to the shipped game | Playtest #3 found bugs I had shipped (duplicate signal, two decimal places, labels cut off at the edge) | Run a full playthrough before the freeze, not after |

## Reflection

I have organised this reflection around the learning cycle in the course guide: how I prepared to learn, how I collected data while working, what I found when I analysed it, and how I am changing what I do. It ends with a post-mortem in the "5 things that went right, 5 things that went wrong" format.

### Preparing to learn

**What I knew and did not know.** Going in, I could program and had used Git, but I had never set up automated tests in Godot, never reviewed other people's branches, and did not know how Godot orders input or what it allows inside a physics callback. The GDD's risk list (§10) was my first pre-test: it named keystroke capture across keyboard layouts as the thing to prove first, so the typing controller was built and checked before anything else.

**Learning the language.** A lot of the early work was learning to speak Godot: signals, autoloads, `Resource` types, `CanvasLayer`, `process_mode`, object pooling and deferred calls. Once I knew the right word, the official documentation usually answered my question quickly. Before that I was searching for the wrong thing.

**Judging resources.** Many Godot tutorials online are written for Godot 3, where names such as `KinematicBody2D` and `yield` changed in Godot 4, so I checked the version first and treated the official Godot 4 documentation as the source of truth, with forum posts only as hints.

**AI tools.** I used Claude as a pair programmer. Its strength was speed: scaffolding code, drafting tests and documents, and explaining engine behaviour. Its limits showed when it guessed, for example fixes that only passed a boot check. The rules I set for it are under the key concepts below.

### Collecting data while working

**A project log.** I kept a dated log of every working session: what I set out to do, what changed, the root cause of every bug and what was still pending. Each manual test record under `tests/manual/` did the same for one feature, with a results table.

**Features as small experiments.** Where I could, I treated a feature as an experiment: think of more than one way to build it, decide what success looks like, build one, then check it.

| Feature | Options considered | What success meant | What I built | Result |
|---|---|---|---|---|
| Equal arrival (#71) | Move spawn points closer, or scale each zombie's speed | Every side reaches the ring within about a second of the others | A speed scale from each zombie's walk length | 24.0 to 24.8 seconds from five directions, so it stayed |
| Medic healing (#63) | A lower heal rate, or a delay after being hit | A 3 shot burst always lands before any heal | Half the heal rate plus a 2 second delay | Worked out by hand first, then held up in play |
| Ability charge (#64) | Charge from kills, or from typed words | Rewards typing, and the player chooses when to fire | 5 typed words, fired with right click | A charge about every 6 words in playtest #3, so 5 may need raising |
| WPM (#68) | Keys over the whole run, or only keys inside words | Matches what a typing test website would show | Only the gaps between keys inside a word are timed | Tests with hand-worked answers pass |

### Analysing the experience: key concepts I learnt

**A script that parses is not a feature that works.** Early on I treated "the project boots with no errors" as proof that a fix worked. During the rebinding bug (#46) my first two fixes passed that check and changed nothing. A small probe scene that sent real input through the same path as a player's click found the real cause. The same lesson came back with bullets stopping on corpses (#69): my tests passed because they called `take_damage()` directly, and the bug only existed when a real bullet hit a real zombie inside a physics callback. I now think of a test as only as good as the path it takes through the engine.

**The hardest bugs came from engine rules I did not know.** The GUI takes mouse events before `_unhandled_input()`, physics state cannot change during a physics callback, duplicate lambdas are not detected as duplicate connections, a coroutine can wake up after its node has left the tree, and an inline comment in a `.tscn` file silently resets the next property. None of these show up when reading the script. I learnt to read how the engine processes something before deciding why my code is wrong.

**Object lifetime matters as much as logic.** Pooling taught me that code which is correct for an object that lives once can be wrong for one that is reused. The combo overcount, the AttackTimer double connection, a freeze leaking into a recycled zombie, a corpse being handed out to the next spawn, and a dog showing for one frame on a zombie that came back as a cat were all the same kind of bug. Now, whenever I write `setup()` for a reused node, I ask what the last life left behind.

**Fairness is maths, not a feeling.** The equal arrival time came from writing down the walk from each direction and seeing that top and bottom zombies had about 360 pixels less to cover. The Medic heal delay came from working out that 10 HP per second undid a hit between every shot at 2 shots per second. The WPM fix came from noticing that a word of n letters has only n minus 1 gaps. In each case the fix was obvious once I measured it, and none of it would have come from tweaking numbers by feel.

**Tests should check rules, not data.** A test listing locked ability ids broke three times as abilities were built. Checking the shape of the catalog instead fixed it for good. The same idea led me to back up the player's save in tests, and to pass timestamps into the WPM code so results can be worked out by hand.

**Git is a safety net only if you understand it.** I nearly lost the art because `git stash` without `-u` leaves new files behind, and I dropped a teammate's commits by rebuilding his branch instead of merging it. Both were recovered because git keeps more than it shows, but only because I went looking. In a graded team project, commit history is also evidence of who did what, so protecting a teammate's history is part of being fair to them.

**Leading means sharing context, not just tasks.** I set up the project backbone before the team formed, which gave everyone something to build on, but early on a lot of how the systems fitted together only lived in my head. Writing clear issues with goals and acceptance criteria, posting updates on Discord, and telling teammates which files to look at made it much easier for everyone to work at their own pace. The 2 Sep rebalance and the 3 Oct check-in, where everyone picked named issues, worked well, and next time I would start them earlier. I also learnt that building something faster myself can take ownership away from someone else, which is what happened when my Mission 2 branch built most of Nicole's issue. Handing it back was the right call.

**A team needs more than programmers.** With four programming students and no design students, the art and design work fell to us. The backgrounds and logos only exist because my partner offered to help, Missions 2 and 3 still have flat colour backgrounds, and many sounds are placeholders. Next time I would look for a designer at the team-forming stage instead of hoping one would join.

**Scope has to match the team's real pace.** The Milestone 2 plan assumed six missions, eight enemies and two bosses. We shipped three missions, six enemy types and one boss. Writing the cut down early with a fixed decision date was much better than letting content quietly fail to appear, and it let us spend the last days on Endless mode, accessibility and the boss fight instead of half a fourth mission.

**Playtesting changes the design, not just the numbers.** The changes I am happiest with came from watching people play: the Accessibility tab, charging abilities from typed words, no screen shake during normal play, the Medic heal delay, edge spawning and the Tank's roar. I also learnt to record playtests on the day; playtest #2 was written up two weeks later and most of its detail is gone.

**Working with an AI pair programmer needs rules.** I used Claude for implementation, drafting and keeping the project log. It made me much faster, but it also produced guessed fixes that only passed a boot check, wrong issue numbers in commits, and UI built in code instead of scenes. Each time I added a rule: behaviour must be verified, issue numbers are checked before the first commit, UI is built as `.tscn` scenes, and teammate files are flagged before editing. The design decisions, reviews, git commands and playtests stayed mine, and that is where I learnt the most.

### Exploit versus explore

For most of the project I exploited what Godot already gives you: signals between systems, a few autoloads, `ConfigFile` saves and inherited scenes. They were simple, quick to explain to teammates, and let us ship. I chose to explore where I thought the time would pay back: setting up GUT in sprint 3, reviewing branches in a separate `git worktree`, writing probe scenes to learn how the engine really behaves, and working with an AI pair programmer. GUT took time to set up but caught regressions for the rest of the project. The place I explored too little was content tooling: missions are still built in code because writing data files felt slower at the time.

### Technical debt

Some debt was a conscious choice. The `UpgradeState` placeholder let the shop be built before the real save system existed. I paid it back when `ProgressionManager` arrived, but the leftover autoload broke tests until I removed it, so the lesson was to repay placeholder debt straight away. Keeping upgrade, ability and supply data in static catalog scripts instead of `.tres` files was also deliberate, and has stayed cheap. Other debt was not chosen: `mission_1.gd` became the base of every mission, and each ability added another flag to the projectile (bad code 1 and 2). That debt came from not knowing yet how big the game would get. Next time I would ask the question from the course guide earlier, "should I use the quick way I know, or take the time to learn the better way?", and write the answer down.

### In-action reviews

We did not hold daily stand-ups. With four people working around other courses and jobs at their own pace, a daily meeting would not have worked. Discord updates did the job of an asynchronous stand-up instead: what was merged, what was in progress and what was blocked. The 2 Sep sprint planning and the 3 Oct check-in were our in-action reviews, and both changed the plan. Retrospectives were the weak point: the sprint table above was put together on 9 Oct from the commit history and my log instead of at the end of each sprint. Next time I would post a three line retrospective (what went well, what could improve, what to try next) on Discord at the end of every sprint.

### Post-mortem

**5 things that went right**

1. **One strong core idea.** Typing earns ammo and aiming spends it. Every system had to fit that pillar, which kept the abilities and supplies coherent.
2. **The `dev` branch and reviewed Merge Requests.** `main` never broke, and reviews in a separate worktree caught real bugs before they were merged.
3. **Tests from sprint 3.** 299 automated tests and 22 manual records meant big late changes (pooling, the boss, Endless mode) did not quietly break older features.
4. **Playtesting changed the design.** The Accessibility tab, charging abilities from typed words and the Medic heal delay all came from watching people play.
5. **Cutting scope with a decision date.** Deciding on 3 Oct that Mission 4 depended on Brute and Mission 3 merging by 9 Oct made the cut a plan, not a surprise, and the time went into Endless mode and the boss fight.

**5 things that went wrong**

1. **The plan was too big.** The Milestone 2 plan assumed about twice our real pace, so three of the six missions and one of the two bosses were cut.
2. **Assets came late.** With no design students, art and audio were sorted out late and from several places, and placeholders are still in the game.
3. **Notes written after the fact.** Retrospectives and playtest #2 were written up later, so detail was lost.
4. **Engine rules found the hard way.** Physics callbacks (#69), pooled signal connections (#41) and the GUI input order (#46) each took several sessions to track down because I had not read how the engine processes them.
5. **Too much in the last sprint.** Most of the content landed in sprint 6, which squeezed polish and balance before the feature freeze.

### Comparing with professional post-mortems

Two of the post-mortems in the course guide matched our project closely. The Katamari Damacy post-mortem argues for removing things so that one novel mechanic can carry the whole game. Our first pillar did the same, and when we had to cut, we cut missions and enemies, never the core loop. The Dance Central post-mortem is about badly estimating the unknown part of a project. For us the unknown part was not the code but our real pace and the art pipeline, and the Milestone 2 plan underestimated both. Let's! Revolution used a hard deadline to make prioritising easier, which is what our 9 October decision date did for Mission 4.

### What I will take forward

- A test harness from the first week, a manual test record for every merge, and engine errors treated as failures.
- Small feature nodes with injected dependencies instead of one growing main script.
- An integration branch with reviewed MRs, reviewed in a separate worktree with the tests running.
- Measuring a problem before changing numbers.
- A dated project log with root causes and decisions, written at the time.
- Scope cuts written down early with a fixed decision date.

### What I would do differently

- Write a short retrospective at the end of every sprint and a playtest record on the day of every playtest.
- Share core systems from the start by pairing with a teammate on the typing and weapon systems, so more than one person can own and review them.
- Look for a design student when forming the team, and get real art and backgrounds in much earlier.
- Start with a mission base class and data-driven abilities instead of refactoring towards them late.
- Set up one git identity and a `.mailmap` on day one, and check the issue number before the first commit on every branch.
- Run a full playthrough before the feature freeze, and get a working export build early.
- Plan content to the team's real pace from the first sprint, then add stretch goals.
