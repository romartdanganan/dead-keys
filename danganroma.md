# Milestone 3: Romart Danganan (danganroma)

## Weights

| Criterion | Weight | Default | Range |
|---|---|---|---|
| Quality of Game | 25 | 34 | 20 to 50 |
| Development process | 45 | 33 | 20 to 50 |
| Use of Engine features | 30 | 33 | 20 to 50 |
| **Total** | **100** | | |

**Development process (45, up from 33).** I ran the team's process for the whole project: every GitLab issue, the branching and Merge Request rules, sprint planning, keeping the team updated on Discord, reviewing and merging branches, the `dev` into `main` syncs, the GUT test suite, every manual test record and the playtests. It is the area with the most evidence behind it, so I want my mark to depend on it the most.

**Use of Engine features (30, down from 33).** Close to the default. Many of the engine-heavy systems are mine (signals and autoloads, resources, physics, pooling, input handling, tweens and the camera, GUT), so I am happy to be marked on it.

**Quality of Game (25, down from 34).** I built a large part of the playable game and I am proud of it, but the final game is a team result, so I would rather put the extra weight on the process work I led from start to finish.

## Role

Lead Programmer, Project Manager, and Integration and Testing Lead. I also wrote the Milestone 1 GDD that Dead Keys is built from.

**Project management.** I set up the GitLab project and created every issue, label and milestone. I wrote the team's branching, commit and Merge Request rules and posted workflow announcements and status updates on Discord. I ran sprint planning, rebalanced work when it piled up, reviewed and merged branches, and kept `main` in sync with `dev` (#53).

**Lead programming.** I built the core systems everything else plugs into: the scene flow and HUD, the ammo and weapon systems, the shared typing controller, all eight abilities, the missions, the Tank boss, Endless mode, medals and the Settings menu. I also wired the zombie art into the game: every walk and death animation, and the death effect with its particle burst.

**Integration and testing.** I set up GUT and wrote 289 of the project's 299 automated tests, wrote all 22 manual test records and ran the playtests. I also fixed the problems that only appeared once separately built systems were joined together.

**Art.** I drew the HUD icons, supply crates, coin and medals in Piskel. The Main Menu and Home Base backgrounds and logos were drawn by my partner, who was happy to help. Our team was four CGRA 359 programming students with no GAME 390 design students, so we had no dedicated artist or designer, and outside help with the backgrounds filled part of that gap.

## Contribution claims

Claims use the course scale. Line counts come from `git blame` on the current `dev` branch and show who wrote the code that is there now, not the total effort.

| Area | Claim | What I did | Evidence |
|---|---|---|---|
| Project setup, repository and workflow | All | Godot project and folder structure (#5), Godot 4.7 migration, Git LFS before the first binary (#17), `dev` integration branch set up and documented (William's idea), commit and MR rules | setup commits 29 to 31 Jul |
| Main Menu, Home Base and hub screens | Most | Main Menu and Home Base (#6), Upgrade Shop (#25), Ability Select and ability purchasing (#24, #36), Mission Supplies screens and loadout (#29), best medal display (#65), Endless button (#68) | `home_base.gd` 108 of 174 lines, `upgrade_shop.gd`, `ability_row.gd`, `mission_supplies.gd`, `supply_slot_row.gd` |
| HUD and combat feedback | All | HUD layout and readability passes (#7, #35), wave announcement (#42), wave counter, hit flash, ammo popups, out of ammo prompt, low wall warning and ability glow (#62), boss health bar with phase marks (#63, #67) | `combat_feedback.gd`, `hud_warnings.gd`, `wave_counter.gd`, `boss_health_bar.gd` |
| AmmoSystem | All | Current and maximum ammo, rewards, consumption, capacity upgrades, HUD signals (#9) | `ammo_system.gd` 81 of 82 lines |
| Weapon, projectiles and all 8 abilities | All | Aiming, firing and projectiles with the shared `take_damage()` interface (#10); `AbilityState`, the ability catalog and all eight abilities (#24, #36, #37, #38, #54); the separate ability input (#64); impact ring effects | `weapon_controller.gd` 218 of 231, `projectile.gd` 238 of 242, `ability_catalog.gd` 72 of 72 |
| Typing system | Most | Rewrote the single target controller into one shared controller for every word on screen (#22), freed target fixes (#18), ammo by word length (#50), supply crate words (#29) | `typing_controller.gd` 296 of 362 |
| Missions and mission flow | Most | `mission_1.gd` base mission, Mission 1 waves (#42), Mission 2 (#31), Mission 3 (#63), mission catalog and Next Mission | `mission_1.gd` 557 of 785, `mission_2.gd`, `mission_3.gd` |
| Tank boss fight | All | Tank, boss bar, phases, roar, summons and the slow motion finale (#63, #67) | `boss_fight.gd` 273 of 273 |
| Endless mode | All | Round ramp, saved high scores, the game over screen and WPM from active typing time (#68) | `endless_mission.gd`, `endless_waves.gd`, `endless_scores.gd` (247 lines), `endless_game_over.gd` and `.tscn` |
| Mission rating and medals | All | Grading, bonus gold, perfect accuracy bonus, saved best medal, medal sprites (#65) | `mission_rating.gd` 124 of 124 |
| Settings, rebinding and accessibility options | All | `SettingsState` and the tabbed Settings menu (#46), rebinding with a duplicate guard, display options, reduce flashing, the Accessibility tab (#66), reduce screen shake (#67) | `settings_state.gd` 381 of 381, `settings_menu.gd` 274 of 275 |
| Pause menu | Most | Pause overlay, timers that stop while paused, return to hub crash fix (#44, #45) | `pause_menu.gd` 31 of 46 |
| Tutorial callouts | All | One-time Mission 1 and new enemy callouts saved per player (#60) | `tutorial_callouts.gd`, `tutorial_state.gd` |
| HUD and item art | Most | HUD icons, supply crates, coin and medals drawn by me; theme and fonts (#35) | `assets/ui/`, `assets/sprites/` |
| Zombie animations and death effect | All | Wired Nicole's cat and dog sprite sheets into the zombie scene with an `AnimationPlayer`: walk and death animations for every zombie type, each animation keying its own sheet so pooled zombies can change type, and zombies facing the way they walk (#35). The death effect: the death animation plays, then a `CPUParticles2D` burst when it finishes (#61) | `zombie.tscn` AnimationPlayer, `_play_art_animation()` and `_update_facing()` in `zombie.gd`, `combat_feedback.gd` |
| Automated testing (GUT) | Most | Set up GUT (#34), the runner scene and the save backup helper | 289 of 299 test functions |
| Manual testing and playtesting | All | All 22 manual test records, playtest records | `tests/manual/`, `playtesting/` |
| Documentation | Most | GDD (Milestone 1 to v1.4), Tech Spec (v0.1 to v0.6), README, `milestone2.md`, `milestone3.md` | doc commits |
| Enemies and wave spawning | Some | Edge spawning and side only spawns (#63), equal ring arrival time (#71), freeze state (#37), knockback slide (#54), Medic heal delay (#63), wave overlap (`wait_for_clear`, #31), AttackTimer fix, Tank data | `zombie.gd` 145 of 404, `zombie_manager.gd` 89 of 173 |
| Mistake system and combo | Some | Jam fix (#20), combo bar fix (#35), mistake toggle (#46), combo charging from typed words (#64) | `mistake_system.gd` 88 of 157 |
| Audio system | Some | Music and SFX buses and the volume functions for the Settings sliders, music continuity fixes, the music loop fix | `audio_bus.gd` 67 of 173 |
| Progression and save | Some | The original `UpgradeState` placeholder that let the shop be built first, its removal after the switch (#26), best medal storage (#65) | `progression_manager.gd` 19 of 162 |
| Word lists | Touched | Original Mission 2 and 3 lists, restored the Tank's long words after the merge (#43, #63) | `mission_3.gd` buckets |
| Success and failed screens, How to Play | Touched | Medal icon on the success screen (#65), How to Play text for the ability key and accessibility (#64, #66) | small edits |

## Commentary

### Coordinating the group

- **Regular updates on Discord.** I posted what had been merged, what was being worked on, what was coming next and any workflow changes, so everyone knew where the project was without having to ask.
- **Working at their own pace.** I was always happy for teammates to work at their own pace around their other courses. If someone wanted help, I told them exactly what they needed to do next, which files to look at and how their piece connected to the rest of the game.
- **Everyone had their own issues.** When I wrote the issues for each sprint, I planned them so every member had at least one issue that related to them and the areas they were already working on (for example Josiah's audio work, and Nicole's word lists and progression).
- **Open to their ideas.** I always told the team that if they had an issue to add or something they wanted to work on that was not on the board, they could let me know and I would create the issue for them, so their work was still tracked and planned like everything else.
- **Reviews and merges.** I reviewed teammates' branches, ran the tests before approving, and kept `main` in sync with `dev` so the playable build was always up to date.
- **Organising the assets.** With no design students, we focused on code and playability, so I organised where our art and audio came from. I drew the HUD icons, crates, coin and medals myself, arranged the backgrounds and logos with my partner, and brought Nicole's sprite sheets and Josiah's sounds into the game so everything had one consistent pixel art look and font.

### Research

- **Comparable games.** For the GDD I looked at typing games such as ZType and Glyphica and lane defence games such as Plants vs. Zombies, which shaped the idea of typing to load ammo and then aiming to spend it.
- **Readable fonts.** I compared pixel fonts for the words above zombies and picked Jersey10 over VT323 because it stayed easier to read at small sizes on moving targets.
- **Words per minute.** I used the usual typing test rule that five keystrokes count as one word, so the WPM shown on the Endless game over screen means the same thing as on a typing test website.
- **Godot input order.** To get mouse rebinding working I worked out the order Godot passes input in (`_input()`, then the GUI, then `_unhandled_input()`) with a probe scene that sends real events through `Viewport.push_input()`.
- **Godot physics rules.** For the bullet bugs in #69 I found that Godot does not allow physics changes during a physics callback, which is why `set_deferred()` was the fix.
- **Playtesting slower typists.** The Accessibility tab came from playtest #2, where a tester at 40 to 50 WPM found the game too hard, so the options were built around what that tester struggled with.

### The harder problems I solved

**Every zombie reaches the ring at the same time (#71).** The screen is 1280 by 720, so a zombie coming from the top or bottom has about 360 pixels less to walk than one from the side, and the corners are further again. After the barrier ring went in, this made top and bottom zombies arrive far too fast. I gave each zombie a speed scale when it spawns: its walk to the ring divided by a reference walk (how far a side zombie walked to the base before the ring, half the width plus the 100 pixel spawn margin, about 732 pixels). Side zombies get 0.87, top and bottom about 0.48 and corners about 1.0. In a test with five Walkers spawned together from the right, bottom, left, top and a corner, they reached the ring at 24.0, 24.4, 24.4, 24.4 and 24.8 seconds. The scale multiplies with the accessibility speed setting and the Commander buff, and resets on pooled zombies.

**Zombies appear straight away instead of after a long empty gap (#63).** Zombies used to spawn on a circle sized by the screen diagonal, so one from the top walked about 474 pixels (around 16 seconds) before anyone could see it. Now each zombie spawns just past the screen edge along its direction (the distance to the edge is the smaller of half width over the x direction and half height over the y direction, plus a margin). The Tank can be limited to the sides so it has the long way across.

**Bullets stopping on dying zombies and unhittable boss helpers (#69).** Both came from one Godot rule: physics state cannot change during a physics callback, and bullets hit zombies inside one. Disabling a corpse's hitbox silently failed, and helpers created inside the callback never got a hitbox. My earlier tests passed because they called `take_damage()` directly, so I built a test that fires real projectiles. The fix uses `set_deferred()`, deferred summons and a dead check in the projectile.

**Death animations on pooled zombies.** The pool hands out the most recently released zombie first, so releasing a zombie the moment it died would let the next spawn grab a corpse mid animation and teleport it. Zombies now go back to the pool only when the death animation finishes, while kills, typing and wave progress still react on the killing hit. Each animation also keys its own sprite sheet, so a zombie that was a dog can come back as a cat without showing the wrong art for a frame.

**WPM that measures real typing.** The first version divided keystrokes by the whole run time, which counted round breaks. I time only the gaps between keys inside a word and count one character per gap, because a word of n letters has n minus 1 gaps (counting all n would make short words read about 50% too fast). Gaps over 1.5 seconds are skipped and real time is used, so the boss slow motion does not change it.

**Rebinding fire to a mouse button (#46).** Godot's GUI takes mouse clicks before `_unhandled_input()` sees them, so the capture had to move into `_input()`. I found this with a probe scene that sends real input through `Viewport.push_input()` after my first two guesses failed.

**Smaller fixes that mattered.** A combo that jumped by 3 or 4 per kill because recycled zombies collected an extra signal connection every life (#41). A crash when returning to the hub mid wave, from a coroutine waking up after its scene was freed (#45). Freeze Round missing its targets because it measured from a dead zombie the pool had already moved off screen (#54). Homing Shot chasing zombies off screen (#54). The focus loss auto pause freezing the game when changing speed in the editor (#61). Medics healing faster than a player can shoot, solved with a 2 second heal delay (#63).

### Design decisions from playtesting

The Accessibility tab came from a playtester at 40 to 50 WPM finding the game too hard. I changed the ability to charge from 5 typed words and fire on right click because typing is the skill the game is about. Screen shake stays out of normal play because it made words hard to read. When the Tank breaks a phase it roars and pushes itself and nearby zombies away from the base before calling helpers, so they never spawn on top of the base.

### Endless mode game over screen

I designed the Endless game over screen as its own scene: the card fades and pops in, the score counts up from zero, and the best score sits beside it. Accuracy and WPM show a dash if the player never typed, so the screen never shows a fake 100%.

![Endless game over screen](images/milestone3/25_endless_game_over.png)

### Testing and reviews

I set up GUT in sprint 3 and wrote 289 of the 299 tests. After hard-coded ability ids broke a test file three times, I rewrote it to check the catalog's shape instead. Tests that use the save file back it up and restore it, so running them never wipes a real save. I reviewed teammates' branches in a separate worktree and ran the full suite before approving them.

### Looking after teammates' work

When rebuilding Josiah's out of date audio branch dropped his commits from his MR, I restored them and redid the integration as a real merge so every commit stayed his. When my Mission 2 branch ended up building most of Nicole's mission unlock issue (#32), I took it out so she could build it herself. I record every edit I make to a teammate's file so these claims stay accurate.

### AI assistance

I used Claude (Anthropic) as a pair programmer during Milestone 3, following the CGRA 359 AI assistance policy. It debugged and double checked code on my machine under my direction and drafted issues, MR descriptions, tests and documents. I made the code design decisions, reviewed every change before committing, ran all git commands and did the playtesting.
