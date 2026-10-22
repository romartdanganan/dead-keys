# Milestone 3: Nicole Lai (lainico)

### Role: Tools and Systems Programmer
(Audio was originally part of my role but was reassigned to another teammate.)

## Weights

| Criterion | Weight |
|----|----|
| Quality of Game | 25 |
| Development process | 35 |
| Use of Engine features | 40 |
| **Total** | **100** |

I chose to weight Use of Engine features the most because, as the Tools and Systems Programmer, I focused on autoloads, signals, and connecting different systems across the game, such as the gold system, saving the player’s progression between restarts, and mission tracking, using ConfigFile and JSON files.

I also put weight on Development process because I used issues and commented on them, and wrote comments in the GDScript, a README, tests, and commit messages explaining my work and progress, so my teammates could follow along.

For Quality of Game, my backend work supports the game without breaking it. The word system works well across word lengths, and save progression and the gold system run smoothly through the game. I weighted it lower because this work is behind the scenes, so players experience it indirectly.

## Contribution claims
| Area | Claim | Evidence | Notes |
|---|---|---|---|
| ProgressionManager autoload | Most | #26, #32, `progression_manager.gd` (142 of 162 lines) | Gold, upgrades, abilities, mission unlocks, saving. Medal saving added by Romart (#65) |
| WordListLoader and JSON word list format | All | #43, `word_list_loader.gd`, commit 725c2dc | Theme and mission files, bucket filtering, random sampling |
| Per-wave word bucket restriction | All | #43, commit 4f3786a, `wave_entry.gd`, `zombie_manager.gd`, `typing_controller.gd` | Runners get short words, fallback so no zombie spawns without a word |
| Themed word lists for Missions 1-6 | All | #43, commit fcf27f0, `resources/word_lists/themes/`, `missions_words/` | 9 themes, 6 mission files, British/NZ spelling, dyslexia-aware word choices |
| Word list README | All | `README_words.md` | Team guide for adding missions without code |
| Mission unlock logic (backend) | All | #32, commit d19d7b0, `progression_manager.gd` (`is_mission_unlocked`, `unlock_next_mission`), `mission_1.gd`, `mission_card.gd` (`set_locked`), `home_base.gd`, `test_progression_manager.gd`, `test_progression_persistence.gd` | Lock state, unlock on win, card selection, launch linking. Card visuals and MissionCatalog are Romart's |
| Mission gold reward | Some | #26, commit d1676f7 | Base reward on a win and save. Romart later added the medal and accuracy bonuses (#65) |
| Upgrade Shop wiring to ProgressionManager | Touched | #26, `progression_manager.gd` (`purchase_upgrade`, gold functions) | Romart wrote `upgrade_shop.gd` and `upgrade_row.gd` on a placeholder `upgrade_state.gd`. I replaced the placeholder calls so they use ProgressionManager, so purchases spend real gold and save |
| Ability and Supply system migration | Touched | commit 7a78adf, issue comments on #24 and #29 | Romart wrote the ability and supply files. I found and fixed the leftover UpgradeState references in 5 of them so ownership, equipping, and gold spending route through ProgressionManager |
| Upgrade effects in missions | Touched | commit d1676f7, commit 7a78adf, `mission_1.gd` (originally `gameplay_prototype.gd`), `mistake_system.gd` | Swapped 7 upgrade reads from the placeholder to ProgressionManager so purchased upgrades work in missions |
| GUT tests for progression and word lists | Some | `test_progression_manager.gd`, `test_progression_persistence.gd`, `test_word_lists.gd`, commit 147ea36, #32 | Rewrote Romart's word list tests for the theme/mission structure and added 5 new tests, plus 4 mission unlock tests |

## What I built in Milestone 3

### ProgressionManager
ProgressionManager is a single autoload that saves the player's progress between sessions using ConfigFile (`user://progression.cfg`). It handles gold (add, spend and `can_afford`), upgrade and ability purchases, and mission unlocks. A `gold_changed` signal means any gold label in the game updates by itself.

Buying an upgrade or ability checks the cost and max level first, and spends nothing if the purchase fails. Progress saves straight after a purchase, so quitting doesn't lose it.

For testing, I added debug keys on Home Base: G (add gold), H (overspend check), S (manual save), R (reset progress and reload Home Base) and U (unlock the next mission and save). These only work in debug builds.

### Words Manager (WordListLoader)
I moved the word lists out of hard-coded arrays and into JSON files, which was my plan from Milestone 2. Theme files hold the words, and mission files say which themes to mix, how many words to use, and which word lengths are allowed.

WordListLoader merges the themes, removes duplicates, filters by bucket, shuffles, then keeps `word_count` words. The buckets reuse the ammo tiers from TypingController, so word length and ammo reward come from one source of truth. Each file is read once and cached, broken files or unknown themes give clear warnings, and Missions 1, 2 and 3 each point at their own list.

### Per-wave bucket restriction
I added `allowed_buckets` to WaveEntry and passed it through ZombieManager and Zombie into TypingController. Each zombie remembers its own buckets, so overlapping waves still get the right words. This means Runners now get short 3-4 letter words, matching the GDD.

If no word fits, the zombie gets any unused word instead of a blank. An empty list means no restriction, so existing waves didn't need changing.

### Word content
I wrote 9 themes with over 500 words: suburb, hospital, shopping, rescue, military, city, zombie, positive and challenge. The 6 mission files mix these, and word length rises across the missions, from a 10-letter maximum in Mission 1 to long words only in Mission 6.

Zombie and positive are shared themes reused across missions, while rare words are kept in their own challenge theme so they can't show up in the tutorial. I raised Mission 3's `word_count` to 40 so the Tank boss gets enough long words. British/NZ spelling is preferred over US spelling, matching the README word rules.

### Word list tests
I rewrote `test_word_lists.gd` for the theme and mission structure, keeping Romart's original checks. The new tests check that mission files are valid, every theme a mission names exists, every mission can fill its `word_count`, words respect allowed buckets, and Mission 1 has no word over 10 letters.

The Tank test now counts long words across Mission 3's themes, so it gives the same result every run. Once nothing used them, I removed the old placeholder word lists.

### Mission unlock system
I built the backend and wiring for mission unlocks, while Romart did the card visuals and MissionCatalog. `is_mission_unlocked()` reads `highest_unlocked`, which starts at 1 and is saved in `progression.cfg`. `unlock_next_mission()` runs when a mission is won, in `mission_1.gd` before the save, and since Missions 2 and 3 extend `mission_1.gd`, one line covers all of them.

Unlocks only move forward and stop at 6, so replaying Mission 1 never relocks Mission 2. Home Base sets each card with `MissionCard.set_locked()`, so only Mission 1 is open on a fresh save. Every unlocked card can be selected, and Launch loads the selected mission through MissionCatalog instead of the hard-coded Mission 1 scene, but stays disabled if the mission is locked or has no scene yet (Missions 4 to 6).

I added four unlock tests: a fresh save has only Mission 1, completing Mission 1 unlocks only Mission 2, replaying an earlier mission never relocks, and unlocks survive a save and reload. I also tested by hand by winning Mission 1, restarting the game, and checking that Mission 2 stayed open and Missions 4 to 6 couldn't be launched.

### Upgrade Shop wiring
Romart's Upgrade Shop used a placeholder `upgrade_state.gd`. I connected the rows to ProgressionManager, so purchases now spend real gold and save.

### Ability and Supply system migration
I found 5 files still calling the placeholder UpgradeState instead of ProgressionManager. The ability ownership check and equip check were reading from two different systems, so a bought ability could spend gold correctly but never visually unlock. Supply purchases and refunds were also running against a separate, disconnected gold value, so buying supplies didn't actually cost anything real.

I fixed all 5 files and confirmed the fix with a full playtest across both shops.

### Upgrade effects in missions
`gameplay_prototype.gd` (now `mission_1.gd`) and `mistake_system.gd` still read upgrade values from the placeholder, so purchased upgrades had no effect in missions. I swapped 7 reads to ProgressionManager and tested every upgrade track in a real mission.

### Mission gold reward
On a win, the mission adds its gold reward and saves immediately (#26, commit d1676f7). Romart later added the medal and accuracy bonuses to the amount (#65). Following GDD §2.8, a failed mission gives no gold, since only completed missions bank coins.

## Commentary
Most of my work is the systems underneath the game, so players feel it rather than see it. Because of this, I tried to make these systems easy for the rest of the team to use without reading my code. Designers can add a mission's words with JSON files and one Inspector setting, and the README explains the word rules, including thinking about dyslexic players and NZ/UK spelling.

I worked on feature branches named after their issues (for example `26-implement-gold-and-save-progression-system`), and linked my commits to issues such as #26, #32 and #43. I left issue comments on #24 and #29 explaining the migration fixes, and wrote code comments that explain why, such as the save-on-purchase comment in `purchase_upgrade()`.

I also coordinated with Romart on shared work. He removed the early unlock wiring from his Mission 2 work (#31, commit d5bfdc7) so I could build the full unlock flow in #32. When I noticed that the tasks and acceptance criteria in #26 conflicted, because purchases happen between missions, I made purchases save immediately as well as on mission completion.

## Challenges and learning

### Silent failures hide bugs
Several of my bugs didn't cause any error, they just quietly fell back to a default. A save/load key name mismatch made progress reset on restart with no error. The game kept using the fallback words even though the JSON loaded, because of "theme" vs "themes", an inverted if, theme file names not matching, and a stray space in a .tscn path. JSON numbers also load as floats, so bucket checks needed `int()` conversion, and a folder typo (`missons_words`) taught me that Godot doesn't update file paths stored as plain strings.

I learned that silent fallbacks hide bugs, so warnings and tests matter as much as the feature itself. With ConfigFile, I now always test save, restart, then load.

### Two sources of truth
Replacing Romart's placeholder without breaking his screens showed me how easily two systems can drift apart. In `ability_row.gd`, the ownership check read from ProgressionManager but the display logic read from UpgradeState, so buying an ability worked but the card never showed it as owned. Supply purchases had the same problem with a separate gold value.

I learned that two checks can each look correct, pass review, and still produce broken behaviour if they read different sources.

### Saving vs refreshing in Godot
The mission cards set their lock state in their own `_ready()`, which runs before Home Base's, so they showed the wrong state until `set_locked()` redrew them. The U debug key unlocked missions only in memory, so they were gone after a restart, and the R key reset the save but the cards stayed unlocked until Home Base reloaded. Looping over `mission_grid` instead of `mission_grid.get_children()` also gave a confusing "_iter_next" error.

I learned that in Godot children are ready before their parent, so the parent has to push state to them after loading. Any change that should survive a restart needs a save, and anything on screen needs a refresh after the data changes.

### Working in a shared codebase
After merging dev, a teammate's edge spawning change used the same `_spawn_zombie` parameter slot I was adding `allowed_buckets` to. I learned to re-read shared functions after merging, and to add parameters rather than replace them. Godot also re-saved `mission_card.tscn` with new `unique_ids`, so I checked the scene diff before committing.

## Reflection
I'm most proud of the theme system. One new JSON file adds a mission's words, and the tests catch mistakes before they reach the game.

The biggest thing I would do differently is saving. At first `purchase_upgrade()` saved but `purchase_ability()` didn't, and `owned_abilities` was missing from save/load and reset. `unlock_next_mission()` still relies on the caller to save, which is how the U key lost its unlock. A single rule, "every state change saves", would have caught all of these.

I would also write the tests at the start instead of the end, since they would have caught the fallback words bug much sooner. During one of our group meetings, Simon mentioned that some developers write their tests before the code, known as test-driven development, and that is an approach I would like to try next time.

I also left some technical debt. The mission count 6 is hard-coded in `unlock_next_mission()`, while MissionCatalog only lists 3 scenes, so a shared mission count constant would keep them in sync. `reset_progression()` also doesn't clear SupplyState, which I've left open as a design decision.

Building systems other people use taught me that a README and clear warnings matter, because teammates shouldn't need to read my code to add a mission. As a future accessibility improvement, a few words such as armoured, jewellery and theatre are spelt differently in US English, so a US spelling option would help players outside NZ and the UK.

## AI use
I used Claude throughout the project for debugging, improving my writing, double-checking my work, and improving my smart git commit messages. For this report, Claude helped me check my contribution claims against the git history and turn my notes into prose.