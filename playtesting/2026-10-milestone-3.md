# Milestone 3 Playtest (Playtest #3) - 16 October 2026

**Facilitator:** Romart Danganan
**Engine:** Godot 4.7
**Build:** `dev` at the 14 October feature freeze (`bfe02e2`), the same build merged into `main`
**Issue:** #33

## Purpose

Check the feature freeze build from start to finish before submission: every menu, all three missions, the Tank boss, Endless mode and both failure screens. Look for crashes, engine errors, unreadable words, pacing problems and anything that would confuse a first-time player.

## Session 1: scripted full playthrough

### Method

The first session was a full playthrough driven by a demo script. The script plays through the game's own input and gameplay functions: it types each word one key at a time (about 70 WPM), aims and fires at the nearest zombie, calls a supply crate with the 1 key, fires the charged ability with the ability input, and makes three deliberate typing mistakes in Mission 1 to trigger a jam. Every 0.25 seconds it checked whether any two visible word labels overlapped.

Three moments were shortcuts so the whole game fits in one session: the wall was forced down in Mission 2 and in Endless mode to reach the two failure screens, and Mission 3 started directly at the Tank with extra bullet damage. The local save file, settings and high scores were backed up first and restored afterwards.

An early version of the gameplay video was recorded from this session. The final video (https://www.youtube.com/watch?v=Dwt_8BhijVM) was recorded later on 16 October with the same script, extended to show every ability, crate and upgrade.

### Results

| Segment | Time | Words typed | Mistakes | Kills | Wall | Word label overlap | Result |
|---|---|---|---|---|---|---|---|
| Mission 1: Defend the Suburbs | 70 s | 13 | 3 (all deliberate) | 11 | 100 / 100 | 0 of 62 samples | Gold medal, 150 gold, 96% accuracy, 71 WPM |
| Mission 2: Hold the Hospital | 56 s (stopped early) | 14 | 0 | 11 | 100 / 100 | 9 of 73 samples (12%) | Wall forced down, Mission Failed screen shown |
| Mission 3: Tank boss | 25 s | 6 | 0 | 6 | 100 / 100 | 0 of 19 samples | Gold medal, 210 gold (100 base, 100 medal, 10 perfect accuracy) |
| Endless mode | 43 s (rounds 1 to 2) | 18 | 0 | 7 | 100 / 100 | 0 of 58 samples | Wall forced down at round 3, game over screen shown, score 270 |

![Playtest #3 Mission 1 jam](../images/milestone3/13_weapon_jammed.png)

### Checked and working

| Check | Result | Pass? |
|---|---|---|
| Main Menu, How to Play and every Settings tab open and close | All opened and closed cleanly | Pass |
| Home Base, Upgrade Shop, Ability Select and Mission Supplies load | All loaded with gold showing | Pass, but see finding 1 |
| Mission 1 tutorial callouts appear once each | Typing, firing and supply callouts shown | Pass |
| Typing highlights every word that matches the typed prefix | Shown in the typing screenshot | Pass |
| Longer words give more ammo | "empowered" gave 3, "hide" gave 1 | Pass |
| Three mistakes in a row jam the gun for 2 seconds | Jammed, then unjammed after 2 seconds | Pass |
| Supply crate lands after 3 seconds and is claimed by typing its word | Ammo Crate claimed | Pass |
| Ability charges after 5 typed words and fires on its own input | Explosive Round fired 2 times in Mission 1 | Pass |
| Mission Complete shows the medal and gold breakdown, Next Mission loads Mission 2 | Gold medal and Next Mission worked | Pass, but see finding 2 |
| Mission Failed screen appears when the last life is lost | Shown in Mission 2 | Pass |
| Tank phases at 66% and 33%, roar, cat and dog helpers, finale and Mission Complete | All three phases and the finale played | Pass |
| Endless rounds advance, the game over card pops in and the score counts up | Score counted up beside the best score | Pass |
| No crash and no gameplay script errors in any segment | None | Pass |

### Findings

| # | Finding | Classification |
|---|---|---|
| 1 | Opening Mission Supplies logs "Signal 'pressed' is already connected" four times. `supply_card_row.gd` connects the Buy button in `_ready()` while `supply_card_row.tscn` already connects it in the editor. Buying still works once, but it is an engine error in the output. | Accepted, remove one of the two connections |
| 2 | The Mission Complete screen shows "Health Remaining: 100.00" with two decimal places (`%.2f` in `mission_1.gd`). | Accepted, show a whole number |
| 3 | Word labels on zombies near the left or right screen edge are cut off, because the 220 pixel label is centred on the zombie and can extend past the edge. | Accepted, keep labels inside the screen |
| 4 | Words overlapped in 12% of samples in Mission 2, where Medics and Walkers arrive together, against 0% in the other segments. | Accepted, look at Mission 2 spawn spacing |
| 5 | The Mission Complete panel is see-through enough that the barrier ring shows behind the stats text. | Accepted, minor, darken the panel |
| 6 | The ability charged twice in 13 words in Mission 1 and three times in 18 words in Endless. One charge about every 6 words may be too frequent. | Needs human testers before changing |
| 7 | At about 70 WPM, Mission 1 took 70 seconds and the wall was never hit. This says nothing about slower typists, which is the question from playtest #2. | Needs human testers |
| 8 | Zombies near the top edge and the corners walk underneath the HUD panels (mission name, wall health, wave counter), so their sprite and word can be hidden for a moment. | Accepted, keep spawns or labels clear of the HUD |
| 9 | The eight ability cards on Ability Select and the empty supply slots still use the default Godot icon as a placeholder. | Accepted, needs ability icons drawn |

## Session 2: human testers

To be added after the session with people outside the team, using the GDD §11 method (observation notes, think aloud and the 5 question survey). Questions carried over from playtest #2:

- Can a 40 to 50 WPM typist finish Mission 1 on default settings, and with each zombie speed option?
- Are the tutorial callouts noticed and understood without help?
- Is the ability charge (5 words) too frequent or too rare, and do players remember to fire it with right click?
- Does the Tank in Mission 3 feel fair?
- Is it clear what each accessibility option does?

## Follow-up

- Fix findings 1 to 3, 5 and 8 as bug fixes before the final `dev` into `main` merge, and draw the ability icons for finding 9 if there is time.
- Findings 4, 6 and 7 wait for the human tester session.
