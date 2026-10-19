# Milestone 3: Dead Keys

**Course:** CGRA 359, Trimester 2 2026
**Due:** Friday, 23 October 2026, 23:59

Dead Keys is a 2D top-down zombie defence game for PC, built in Godot 4.7. Every zombie carries a word above its head. Typing the word loads ammunition into the gun, but typing never damages anything: the player still has to aim with the mouse and fire. Typing skill decides how much ammo exists, aiming skill decides whether it is spent well.

![Mission 1 with the weapon jammed](images/milestone3/13_weapon_jammed.png)

## Team summary

- Romart Danganan (CGRA 359, lead programmer, project manager, integration and testing lead, GDD author)
- William Johnston (CGRA 359, gameplay and mechanics programming: zombie state machine, enemy types, wave spawning, object pooling, 360 degree spawning, barrier ring)
- Nicole Lai (CGRA 359, tools and systems programming: original typing controller, progression, gold and save system, mission unlocks, word list system, zombie sprite sheets)
- Josiah Natanielu (CGRA 359, FX and audio programming: mistake and jam system, combo counter, audio system and sound effects, mission success and failed screens, How to Play page)

Each student's contribution claims and commentary are in their own file: [danganroma.md](danganroma.md), [johnstwill1-m3.md](johnstwill1-m3.md), [lainico.md](lainico.md) and [natanijosi.md](natanijosi.md).

All four of us are CGRA 359 programming students. No GAME 390 design students joined the team, so nobody on the team was a dedicated artist or game designer. Romart drew the HUD icons, supply crates, coin and medals; the Main Menu and Home Base backgrounds and logos were drawn by Romart's partner, who offered to help; and Nicole provided the zombie cat and dog sprite sheets.

## Repositories

- Game repository (code, scenes, assets through Git LFS, GDD, Tech Spec, tests and playtest records): https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys
- There are no other repositories. The branch to assess is `main`, which is synced from our `dev` integration branch at each milestone.

Third party material in the repository:

- [GUT](https://github.com/bitwes/Gut) (Godot Unit Test) addon under `addons/gut/`, used for automated testing.
- Jersey 10 and VT323 pixel fonts (Google Fonts, SIL Open Font License) under `assets/fonts/`.
- Placeholder sound effects and music under `assets/audio/temp_sounds/`, gathered by Josiah.

## Gameplay video

A 6 minute 53 second run through the whole game, split into eight titled parts:

1. **Menus:** Main Menu, How to Play and every Settings tab.
2. **Home Base:** buying five upgrades in the Upgrade Shop, buying all seven locked abilities in Ability Select, and filling the three supply slots.
3. **Mission 1:** the upgrades showing in the HUD, the pause menu, the tutorial callouts, the type, aim and shoot loop, a weapon jam, the first ability charge, a supply crate and the medal screen.
4. **All eight abilities:** each one fired on a group of zombies placed for it, with its name and effect on screen.
5. **Supply crates:** all four crates called in, claimed by typing their word, and their effects shown (ammo refilled, wall repaired, a Walker dying in two shots instead of three, and the Emergency Crate's refill).
6. **Mission 2:** Medics and the Brute, then the Mission Failed screen.
7. **Mission 3:** Heavy Round equipped, the Commander waves, all three Tank boss phases, the slow motion finale and the saved medal on Home Base.
8. **Endless mode:** two rounds with two accessibility options turned on, then the game over screen with the score counting up.

Once the core loop has been shown at normal speed, the long typing and shooting stretches play at 2x to 4x speed, with a "FAST FORWARD" badge in the corner. The boss phases, the finale and every menu play at normal speed.

**YouTube:** https://www.youtube.com/watch?v=Dwt_8BhijVM

The video was recorded with a demo script that plays the game through its real input and gameplay functions. The captions and part titles were added by the script and are not part of the game. Two things are set up by the script, and both are labelled on screen: the ability and crate showcase places zombies by hand (some already hurt) and gives each ability its charge, and the wall is forced down to show the Mission Failed and Endless game over screens.

## Running the game

1. Install Godot 4.7, Git and Git LFS.
2. Clone the repository, then run `git lfs install` and `git lfs pull` so the images and audio download.
3. Open `project.godot` in Godot 4.7 and press F5. The game starts at the Main Menu.

Full instructions, controls, the accessibility options and how to run the tests are in [README.md](README.md).

## What the game contains at Milestone 3

The full screen flow from the GDD is playable: Main Menu → Home Base → Upgrades, Mission Supplies or Ability Loadout → mission → Mission Complete or Mission Failed → Home Base, with Pause, Settings and How to Play along the way.

| | |
|---|---|
| ![Main Menu](images/milestone3/01_main_menu.png) | ![Home Base](images/milestone3/04_home_base.png) |
| Main Menu | Home Base with the mission table |
| ![Ability Select](images/milestone3/06_ability_select.png) | ![Mission Supplies](images/milestone3/07_mission_supplies.png) |
| Ability Select | Mission Supplies |

**Core loop**
- One shared typing controller handles every word on screen at once and highlights every word that matches what has been typed so far.
- Longer words give more ammo (3 to 4 letters = 1 bullet, up to 11+ letters = 4 bullets).
- Manual mouse aim and fire with travelling projectiles, no lock on.
- Every wrong key costs a bullet; three wrong keys in a row jam the gun for two seconds.
- Typing 5 words in a row charges the equipped ability, which the player fires when they choose with right click.

| | |
|---|---|
| ![Shared prefix highlighting](images/milestone3/10_typing_prefix.png) | ![Ammo popup](images/milestone3/11_ammo_popup.png) |
| Typing highlights every matching word | "+N AMMO" pops up over the zombie |
| ![Supply crate](images/milestone3/12_supply_crate.png) | ![Explosive Round](images/milestone3/14_explosive_round.png) |
| A supply crate waiting for its word | An Explosive Round going off |

**Content**
- Three campaign missions, unlocked in order: Defend the Suburbs, Hold the Hospital and Secure the Shopping Centre.
- Six zombie types: Walker, Runner (fast, zigzags, short words), Medic (heals nearby zombies), Brute (150 health, long words), Commander (speeds up nearby zombies) and the Tank boss.
- A three phase Tank boss fight at the end of Mission 3: the Tank roars and calls cats then dogs as helpers, cracks its armour at a third of its health, and dies in a slow motion camera finale.
- Endless mode: rounds that slowly ramp up, a Tank every fifth round, a score, a saved top 5, and a game over screen where the card pops in, the score counts up and the best score sits beside it.
- Eight abilities, each with a different job: Spread Shot, Ricochet, Piercing Shot, Freeze Round, Explosive Round, Heavy Round, Homing Shot and Shockwave Round.
- Seven permanent upgrade tracks bought with gold, four Mission Supply crates called in with keys 1 to 3, and bronze, silver and gold medals that pay bonus gold and are saved per mission.
- Zombies stop and attack a barrier ring around the base, and reach it in the same time from every side of the screen.

| | |
|---|---|
| ![Boss phase 2](images/milestone3/19_boss_phase_2_roar.png) | ![Boss finale](images/milestone3/21_boss_finale_zoom.png) |
| The Tank roars at phase 2 | Slow motion finale |
| ![Mission complete](images/milestone3/15_mission_complete_medal.png) | ![Endless game over](images/milestone3/25_endless_game_over.png) |
| Mission Complete with a medal | Endless game over screen |

**Player support and accessibility**
- Mission 1 teaches the game through short one-time callouts, and each new enemy gets a callout the first time it appears.
- How to Play page from the Main Menu and the Pause menu.
- Settings with Audio, Gameplay, Display, Controls and Accessibility tabs: volume sliders, fullscreen and resolution, a mistake penalty toggle, rebinding for fire, ability and supply keys, and options for slower typists (zombie speed, longer crate timer, large word text, hold to fire, reduce flashing, reduce screen shake).
- Combat feedback: hit flash, death animation then particle burst, ammo popups, an out of ammo prompt, low wall warning, ability ready glow, wave counter and a boss health bar.

![Accessibility tab](images/milestone3/03_settings_accessibility.png)

## Scope: what we planned and what we shipped

The Milestone 2 plan aimed at the full GDD: 6 missions, 8 enemy types, 2 bosses, 8 abilities and the full upgrade economy.

| GDD feature | Priority | Result |
|---|---|---|
| Typing, ammo, manual aim and fire, mistake system | Must | Done |
| Home Base, upgrade shop, progression and save | Should | Done |
| Ability loadout, first 4 abilities | Should | Done |
| Remaining 4 abilities | Could | Done |
| Mission Supplies | Should | Done |
| Missions 1 to 3 and the first boss | Should | Done |
| First 4 enemy types (Walker, Runner, Brute, Medic) | Should | Done |
| Mistake system toggle | Could | Done |
| Mission rating and medals | Could | Done |
| Remaining 4 enemy types (Spitter, Exploder, Commander, Armoured) | Could | Commander done, the other three cut |
| Missions 4 to 6 and the second boss | Could | Cut |

**The cut and why.** `milestone2.md` set a cut order in advance: "the second boss and half the ability roster go first, the core loop never gets cut." By early October all eight abilities were built, so the cut had to land on content instead. A planning pass on 3 October listed what was left against the 14 October feature freeze. We kept every Should-tier item (Brute, Mission 3 and the Tank boss) and made Mission 4 with the Spitter and Exploder a stretch goal, to go ahead only if Brute and Mission 3 were both merged by 9 October. Brute merged on 8 October and Mission 3 on 9 October, which left too little time for a fourth mission, so Missions 4 to 6, the second boss, and the Spitter, Exploder and Armoured enemies are cut for this trimester.

**What we added instead.** With three missions, we spent the last days before the freeze on replay value and fairness: Endless mode (reuses every enemy and system), the Accessibility tab (a response to playtest #2), a full boss fight and medals. Some GDD rules also changed after playtesting; these are listed under "Design changes driven by playtesting".

## Development process

### Schedule: plan against reality

We kept the two-week sprints from `milestone2.md`.

| Sprint | Dates | Planned | What happened |
|---|---|---|---|
| 1 | 1 to 7 Aug | Project backbone | Delivered, plus the weapon and projectile system a sprint early |
| 2 | 7 to 14 Aug | Finish the MVP | Delivered on 10 Aug; Milestone 2 submitted |
| 3 | 14 to 28 Aug | Ability system and combo, shop UI, save manager | Upgrade Shop (#25), Ability System and Spread Shot (#24), Mission Supplies (#29), combo (#23), Runner (#27), GUT set up (#34). The save manager (#26) merged early in sprint 4 |
| 4 | 28 Aug to 11 Sep | Supplies, three more enemies, Missions 1 and 2, playtest #2 | Work was rebalanced on 2 Sep. Delivered Ricochet, Piercing Shot, pause menu, Mission 1 waves, zombie pooling (#28), audio system (#40), ProgressionManager (#26) and the art and UI redesign (#35). Mission 2 and the Brute slipped; playtest #2 moved to about 25 Sep |
| 5 | 11 to 25 Sep | Mission 3, first boss, remaining upgrades | No commits on `dev` from 11 to 21 Sep while other course deadlines were on. Then Freeze Round, the Settings menu and the Medic. Mission 3 slipped to sprint 6 |
| 6 | 25 Sep to 14 Oct | Remaining enemies, Missions 4 to 6, second boss, feature freeze | The biggest sprint: ammo by word length, the last four abilities, Missions 2 and 3, Tank boss, Brute and Commander, 360 degree spawning, barrier ring, success and failed screens, How to Play, sound effects, tutorial callouts, combat feedback, medals, accessibility, word lists, mission unlocks, boss overhaul and Endless mode. Missions 4 to 6 and the second boss were cut. Feature freeze held on 14 Oct |
| 7 | 14 to 23 Oct | Polish, playtest #3, submission | Playtest #3, documentation, the GDD and Tech Spec final sync, and the final `dev` into `main` merge |

Our real pace was about half of what the Milestone 2 plan assumed, so the plan was too big for a team where everyone also had other courses and jobs.

### How we controlled the process and communicated

- **Discord** was our main channel: announcements for every workflow change (branching rules, LFS setup, the `dev` branch, merge order), status updates, and MRs waiting for review.
- **GitLab issues for everything.** Each issue has a Goal, Tasks and Acceptance criteria with checkboxes, plus labels, a weight and a milestone. Work longer than an hour or two got its own issue; tiny fixes rode along with the related one. Ongoing work had long-lived issues: #34 for GUT tests, #35 for art and UI, #53 for keeping `main` in sync with `dev`. The board passed #70 by the feature freeze.
- **Ownership.** Each system has an owner (see the Team summary). Nobody edits someone else's file without telling them first, and edits to a teammate's file are recorded so contribution claims stay accurate.
- **Load balancing and check-ins.** At the 2 Sep sprint planning, work was rebalanced across the team: the Medic (#39) went to William and the audio system (#40) to Josiah. On 3 Oct a check-in asked everyone what they wanted to own for the rest of the trimester, and each of us picked named issues (William: Brute, Commander and the barrier ring; Nicole: mission unlocks and word lists; Josiah: failed screen, sound effects and How to Play).
- **A running project log.** Romart kept a dated log of every working session: what changed, why, root causes of bugs and what was still pending. It is the source for our sprint retrospectives and these documents.

### Version control, branching and ticket tracking

- **Branching.** One branch per issue, named `name/feature-description`. Feature branches merge into `dev` through a Merge Request; `dev` merges into `main` at milestones (#53). Direct pushes to `main` and `dev` are blocked and every MR needs an approval from someone other than its author.
- **Commits and MRs.** Commit messages follow `What I did (#issue)`, and commits that add or change tests also reference #34. MR descriptions share one template: summary, changes per component, manual testing, defects fixed, follow-up, and `Closes #N` so issues close on merge. The repository has 229 commits on `dev`.
- **Git LFS** was set up on 31 July, before the first binary asset was committed.
- **Reviews in a separate worktree.** Teammate branches were reviewed in a second working folder (`git worktree`) with the full GUT suite run on the branch before approving. Reviews caught bugs before they reached `dev`, for example a duplicate variable that broke the zombie script (#28), music that never looped because its loop setting lived in git-ignored `.import` files (#40), a failed screen titled "MISSION COMPLETE!!!" (#56), and the Tank losing its long words after the word list merge (#43).
- **Recovering from git mistakes.** On 7 Sep a `git stash` without `-u` nearly lost all of the HUD and crate art; it was recovered with `git stash show -u` and `git stash apply`, and since then original art is copied, never moved. On 10 Sep, rebuilding Josiah's out of date audio branch dropped his commits from his MR; they were restored by pushing his original commit back and redoing the integration as a real merge. The rule since then: never rebuild a teammate's history. Risky rebases are rehearsed in a throwaway clone first and pushed with `--force-with-lease`.
- **Ticket hygiene.** A few commits referenced the wrong issue number (#47 for #48, #53 for #54, #45 for #34). Each was found and corrected, including rewriting already pushed messages for #54.

### Testing, reviews and playtesting

- **Definition of done** in practice: the feature works in the editor, the full GUT suite passes, a manual test record is committed under `tests/manual/`, the MR is approved by someone else, and the issue closes on merge.
- **Automated tests.** GUT was set up in sprint 3 (#34). The suite grew from 61 tests in September to 299 tests across 33 test scripts. Tests that use the save file back it up and restore it, so running the suite never wipes a player's progress.
- **Manual test records.** 22 records under `tests/manual/`, each with a results table, issues found and fixes applied. Some branches were merged without one (Mission 2, ammo scaling and several teammate branches), which is a gap in how we applied our definition of done.
- **Playtests.**
  - Playtest #1 (Milestone 2, `playtesting/2026-08-milestone-2.md`): new players understood the typing but not the manual firing, and words overlapped where Walkers met.
  - Playtest #2 (about 25 Sep, `playtesting/2026-09-sprint-4.md`): an external tester at 40 to 50 WPM found the game too hard. It was not written up on the day, so the record is written from memory and says so.
  - Playtest #3 (16 Oct, `playtesting/2026-10-milestone-3.md`): a scripted full playthrough of every menu, all three missions, the boss and Endless mode on the feature freeze build, driven by the same demo script as the gameplay video. A second session with human testers outside the team is planned before submission. The scripted session found no crashes, but it did find a duplicated signal connection on the Mission Supplies screen, two decimal places in the wall health stat, word labels cut off at the screen edge, and words overlapping in 12% of samples in Mission 2 (0% in the other missions).

### Design changes driven by playtesting

- Walkers converged on one point and their words overlapped (playtest #1) → 360 degree spawning (#48), a barrier ring so zombies stop around the base (#55), then equal arrival time from every side (#71).
- The game was too hard at 40 to 50 WPM (playtest #2) → the Accessibility tab (#66).
- Waves felt slow because zombies took up to 16 seconds to walk onto the screen → zombies now spawn just off the screen edge (#63).
- Medics healed faster than a player could finish a zombie → healing waits 2 seconds after a hit and runs at half speed (#63).
- Abilities charged from kills and fired automatically → they now charge from 5 typed words and fire when the player chooses (#64), because typing is the skill the game is about.
- Screen shake made words hard to read → no shake during normal play; shake only for wall hits and boss moments, with an accessibility toggle (#67).
- Explosive Round rarely hit more than one zombie once zombies spread out → its radius went from 120 to 200 pixels; Shockwave knockback became a smooth slide instead of a teleport (#54).
- Endless round 1 was too hard → round 1 is three short-word Walkers and no round grows by more than three zombies (#68).
- "BEST" on the Endless game over screen read like a best WPM → it moved beside the score (#68).

### Strengths of the game

- The core loop is distinctive. Splitting typing (earns ammo) from aiming (spends it) means both skills matter.
- The eight abilities each have a different job (spread, bounce, pierce, freeze, explode, heavy hit, home in, push back) and each has visible feedback.
- The game teaches itself through callouts and the How to Play page, and the HUD shows what matters.
- Accessibility is treated as a feature: a readable pixel font, key rebinding, a mistake penalty toggle, slower zombies, longer crate timers, large word text, hold to fire, and reduce flashing and screen shake. Medals are never reduced for using them.
- The boss fight is the most polished moment in the game, and the Endless game over screen gives the mode a proper ending.
- It is well tested for a student project: 299 automated tests plus manual records for most features.

### Weaknesses of the game

- Three missions instead of six, five regular enemy types instead of eight, and one boss instead of two.
- We had no design students on the team, so art and design work fell to programmers. Missions 2 and 3 use flat background colours instead of drawn backgrounds, the ability cards still use the default Godot icon as a placeholder, the zombie animations come from provided sprite sheets, and many sounds are placeholders.
- Balance numbers (ability radii, costs, rewards, medal thresholds) are first-pass values. Ricochet is stronger than Spread Shot against groups.
- Words can still overlap when zombies bunch up at the ring, labels near the screen edge get cut off, and zombies near the top edge can pass under the HUD panels.
- There is no tested export build; the game is run from the Godot editor.

### What worked well in our process

- The `dev` integration branch (William's suggestion at Milestone 2) meant `main` never broke.
- Reviewing branches in a separate worktree with the full GUT suite caught bugs before merge.
- Playtesting changed the design, not just the numbers, and each change is traceable to an issue.
- A manual test record for each MR made reviews faster and gave us a history of what was checked.

### What did not work well

- **Getting assets into the game.** With no design students, we put our time into the code and playability first, and the art and audio were sorted out later and came from several places: Romart's HUD icons, crates, coin and medals, Romart's partner's backgrounds and logos, Nicole's cat and dog sprite sheets, and Josiah's placeholder sounds. We had no shared asset list or style guide, so assets arrived at different times and sizes and had to be scaled and wired into the scenes one by one, and some placeholders (the ability icons and the flat backgrounds in Missions 2 and 3) are still in the game.
- **Too much landed in the last sprint.** Sprint 6 delivered most of the game's content, from the last four abilities to Missions 2 and 3, the boss and Endless mode. That left little time for polish and balance before the feature freeze, and several small bugs were only found in the final playthrough.
- **Retrospectives and playtest notes** were not written at the time. Playtest #2 was recorded two weeks later from memory, and our sprint retrospective notes were put together on 9 Oct from the commit history and the project log.
- **A ten day gap** with no commits on `dev` in sprint 5 pushed Mission 3 into sprint 6.
- **Inconsistent practice.** Commit message conventions and manual test records were followed on most branches but not all.
- **No CI pipeline.** Tests were run locally before each merge instead of automatically on every push.

### Best parts of the game and process

For the game, the boss fight and the feel of typing a word, seeing "+2 AMMO" pop up, then landing a charged Explosive Round into a crowd. For the process, finding root causes instead of patching symptoms: the multi-Walker typing bug at Milestone 2, the pooled zombie signal bug (#41) and bullets stopping on dying zombies (#69) were each traced to a cause and fixed with a test.

### Use of Godot engine features

| Feature | Where |
|---|---|
| Inherited scenes | `mission_2.tscn`, `mission_3.tscn` and `endless.tscn` inherit `mission_1.tscn`; `brute.tscn`, `commander.tscn` and `tank.tscn` inherit `zombie.tscn` |
| Custom `Resource` types for data-driven content | `EnemyTypeDef`, `WaveEntry`, `MissionConfigDef` and the `.tres` enemy files in `resources/enemies/` |
| Autoload singletons | `ProgressionManager`, `Audio`, `SettingsState`, `SupplyState`, `AbilityState`, `TutorialState` |
| Signals between systems | typing, ammo, ability charge, zombie spawn, damage and death, wave and mission events |
| State machine and object pooling | `zombie.gd` (SPAWN, APPROACH, ATTACK, SUPPORT, FROZEN, DEAD), `zombie_pool.gd` |
| Physics areas and deferred physics changes | projectile hits through `Area2D` signals, collision changes made with `set_deferred` because physics state cannot change inside a physics callback |
| Input system | `InputEventKey.unicode` for keyboard layout independence, runtime `InputMap` rebinding, rebind capture in `_input()` because the GUI takes clicks before `_unhandled_input()` |
| `ConfigFile` saves | progression, settings, supply loadout, tutorial callouts and Endless high scores |
| Audio buses | Music and SFX buses created through `AudioServer` for the volume sliders |
| `CanvasLayer` overlays and pause | pause, settings, How to Play, success and failed screens on separate layers, with `process_mode` set so menus work while the game is paused |
| `AnimationPlayer` sprite sheets | cat and dog zombies share one pooled scene; each animation keys its own sprite sheet |
| `Camera2D`, `Tween` and time scale | trauma based screen shake, the boss finale zoom and slow motion using real time tweens, the Endless score count-up |
| Visual effects | `Tween` hit flash on `self_modulate`, `CPUParticles2D` death bursts, custom `_draw()` impact rings and barrier ring, `RichTextLabel` letter highlighting |
| `Theme` resource | project-wide pixel font, nearest filtering for pixel art |
| `DisplayServer` and engine queries | window mode and resolution, `OS.is_debug_build()` to disable debug keys in exports, focus loss auto pause |
| GUT | 299 unit tests in `tests/unit/` |

### AI assistance

Each team member declares their own use of AI tools in their individual file.

### Known issues at submission

- Ricochet against Spread Shot balance and the other first-pass numbers listed under Weaknesses.
- Several Commanders stack their speed buff on the same zombie.
- The Mission Supplies screen logs a duplicated signal connection error (found in playtest #3).
- Around 25 scenes are missing Godot `unique_id` values; the editor fills them in on the next save and they cause no errors.
