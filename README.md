# Dead Keys

**Dead Keys** is a top-down typing and shooting game built in **Godot 4.7** by
Romart Danganan, William Johnston, Nicole Lai and Josiah Natanielu for CGRA 359.

Zombies walk towards your base from every side of the screen. Type the word
above a zombie to load ammunition, then aim with the mouse and fire to stop
them before they break the wall.

## What is in the game

- **Three campaign missions:** Defend the Suburbs, Hold the Hospital and Secure
  the Shopping Centre, which ends with the Tank boss fight.
- **Endless mode:** rounds keep coming until the last life is lost, with a
  saved best score and a game over screen that counts the score up.
- **Six enemy types:** Walker, Runner, Brute, Medic, Commander and the Tank boss.
- **Eight abilities:** Spread Shot, Ricochet, Piercing Shot, Freeze Round,
  Explosive Round, Heavy Round, Homing Shot and Shockwave Round. Typing 5 words
  in a row charges the equipped ability.
- **Four supply crates:** Ammo, Medical, Combat and Emergency, bought before a
  mission and claimed by typing the word on the crate.
- **Seven permanent upgrades:** Fire Rate, Bullet Damage, Magazine Capacity,
  Fortified Wall, Extra Life, Jam Duration and Mistake Leniency.
- **Medals:** Bronze, Silver or Gold for each mission from typing accuracy,
  wall health left and lives lost. The best medal is saved.
- **Settings:** audio, gameplay, display, key rebinding and an Accessibility tab.

# Build and Run Instructions

## Requirements

Install:

- **Godot 4.7**
- **Git**
- **Git LFS**

Git LFS is required for binary assets such as images and audio.

## Clone the repository

```bash
git lfs install
git clone https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys.git
cd dead-keys
git lfs pull
```

If the repository is already cloned and you want the stable branch:

```bash
git checkout main
git pull origin main
git lfs pull
```

If you are working with the latest integrated development version:

```bash
git fetch origin
git checkout dev
git pull origin dev
git lfs pull
```

## Open the project

1. Launch **Godot 4.7**.
2. Select **Import**.
3. Browse to the cloned repository.
4. Select `project.godot`.
5. Click **Import & Edit**.
6. Wait for Godot to finish importing the project.

## Run the full game

Press **F5** or click **Run Project**.

If Godot asks for a main scene, select:

```text
res://scenes/ui/main_menu.tscn
```

Game flow:

```text
Main Menu
→ Start: Home Base (Upgrades, Abilities, Supplies, mission table)
→ Mission 1, 2 or 3
→ Mission Complete (medal and gold) or Mission Failed
→ back to Home Base or on to the Next Mission

Main Menu
→ Endless
→ Endless game over screen (score, best score, accuracy, WPM)
```

Progress, settings and Endless scores save automatically to the Godot `user://`
folder.

## Controls

| Input | Action |
|---|---|
| Keyboard letters | Type the words above zombies and supply crates |
| Mouse movement | Aim the crosshair |
| Left mouse button | Fire toward the cursor (rebindable in Settings) |
| Right mouse button | Fire your charged ability toward the cursor (rebindable in Settings) |
| 1, 2, 3 | Call in the supply in that slot (rebindable in Settings) |
| Escape | Pause |

### Accessibility

The **Accessibility** tab in Settings is aimed at slower or newer typists.
Every option saves between sessions and can be changed mid mission from the
Pause menu.

| Option | Effect |
|---|---|
| Zombie Speed | Normal, 85%, 70% or 55% movement speed for every zombie |
| Longer Crate Timer | Supply crates stay for 12 seconds instead of 8 |
| Large Word Text | Words above zombies and crates use bigger text |
| Hold To Fire | Holding the fire button keeps shooting at your fire rate |
| Reduce Flashing | Hit flashes are turned off and warnings use a steady colour |
| Reduce Screen Shake | Turns off the camera shake on wall hits, lost lives and boss moments |

### Developer debug keys (editor only)

These only work when the game is run from the Godot editor. They are disabled
in exported builds.

| Input | Where | Action |
|---|---|---|
| F1 | Mission | Charge the equipped ability |
| F4 | Mission | Reset ammunition |
| F5 | Mission | Increase maximum ammunition |
| F6 | Mission | Add ammunition |
| F7 | Mission | Consume ammunition |
| G | Home Base | Add 50 gold |
| H | Home Base | Try to spend 10000 gold |
| S | Home Base | Save progression |
| R | Home Base | Reset all progression and tutorial callouts |
| U | Home Base | Unlock the next mission |


# How the Main Systems Work

## Shared typing

One shared `TypingController` manages every word on screen, for zombies and
supply crates.

If multiple words share a prefix, all matching words stay highlighted until the
typed prefix narrows the target.

Example:

```text
Undead
Unbelievable
```

Typing `U` highlights both, typing `N` keeps both matched, and typing `D` leaves
only `Undead` matched.

When a word is completed:

```text
complete word
→ gain ammunition (1 to 4 bullets by word length)
→ the same living zombie receives a new unique word
→ the zombie remains alive until shot
```

## Mistakes and weapon jams

- Each typing mistake removes one ammunition.
- Three consecutive mistakes trigger a two-second weapon jam.
- While jammed, firing is disabled.
- Mistakes made during the jam still remove ammunition.
- Mistakes made during the jam do not build toward another jam.
- The mistake system can be turned off in the Gameplay tab of Settings.

## Known limitations

- The ability cards and some supply slots still use placeholder icons.
- Zombies can walk under the HUD panels near the screen edges.
- Debug controls are still in the code but only work when run from the editor.
- See `milestone3.md` for the full known issues list.

# Technical Tests and Playtesting

## General technical test scenes

General isolated test scenes are stored under:

```text
res://scenes/testing/
```

## Walker / zombie test scenes

William's Walker test scenes and scripts are stored under:

```text
res://tests/zombies/
```

To run an individual test scene:

1. Open the `.tscn` file in Godot.
2. Press **F6**.

Use:

```text
F5 = run the full project
F6 = run the currently open scene
```

## Manual test records

Manual test records are stored under:

```text
tests/manual/
```

## Automated unit tests (GUT)

Unit tests use [GUT](https://github.com/bitwes/Gut) (Godot Unit Test) and live
under:

```text
tests/unit/
```

There are 299 test functions across 33 test scripts, covering the typing,
ammo, weapon, abilities, projectiles, zombies, spawning, missions, boss fight,
Endless mode, medals, settings, saving and word lists. Tests that touch save
files back them up first and restore them afterwards.

### One-time setup

GUT is already included in the repository under `addons/gut/` and is enabled
in `project.godot`, so there is nothing to install. If the GUT panel does not
appear, go to **Project → Project Settings → Plugins** and tick **Gut**.

### Running the tests

**In-editor:**

1. A **GUT** panel appears at the bottom of the editor after installing
   the addon (alongside Output/Debugger/Audio). If it doesn't show up,
   **Project → Reload Current Project**.
2. The panel's in-editor settings are stored outside the project folder
   and start empty, they do NOT automatically read `.gutconfig.json`. On
   first use, click **Load** next to **Config** (top-right of the panel)
   and select `.gutconfig.json` from the project root. This populates the
   panel's test directory and settings from that file. `.gutconfig.json`
   starts with a dot, if your file picker hides dotfiles, enable "show
   hidden files".
3. Click **Run All**.

This Load step is only needed once per machine, GUT remembers it after
that.

**From the command line:**

```bash
godot --headless -s addons/gut/gut_cmdln.gd
```

This reads `.gutconfig.json` directly, no Load step needed for the CLI
runner.

## Playtest records

Human playtest findings are stored under:

```text
playtesting/
```

| Record | File |
|---|---|
| Playtest #1 (Milestone 2) | `playtesting/2026-08-milestone-2.md` |
| Playtest #2 (Sprint 4) | `playtesting/2026-09-sprint-4.md` |
| Playtest #3 (Milestone 3) | `playtesting/2026-10-milestone-3.md` |

Design documents: `GDD.md` (Game Design Document) and `Dead_Keys_TechSpec.md`
(Technical Specification).

# Development Workflow

Development uses:

```text
feature branch
→ Merge Request into dev
→ integration testing on dev
→ dev merged into main
```

Branch purposes:

- `main`: stable milestone and release branch
- `dev`: shared integration branch
- feature branches: one issue or feature per branch

Before starting new work:

```bash
git fetch origin
git checkout dev
git pull origin dev
git checkout -b yourname/feature-name
```

Feature Merge Requests should normally target:

```text
dev
```

Merge Requests require review by someone other than the author.

Commit messages should reference the related GitLab issue:

```text
Brief description of work (#issue_number)
```

# Troubleshooting

## Images or audio are missing

```bash
git lfs install
git lfs pull
```

Then reopen Godot.

## Godot reports missing imported files

Close Godot, delete the local `.godot/` folder, then reopen the project.

The `.godot/` folder is generated locally and is not committed.

## A test scene does not run with F5

Use **F6** for individual test scenes.

## Wrong Godot version

Open the project using **Godot 4.7**.

# Credits

- **Team:** Romart Danganan, William Johnston, Nicole Lai and Josiah Natanielu.
- **Art:** HUD icons, supply crates, coin and medals by Romart Danganan. Main
  Menu and Home Base backgrounds and logos by Romart's partner. Cat and dog
  zombie sprite sheets by Nicole Lai.
- **Audio:** audio system by Josiah Natanielu, with placeholder sound effects
  and music he gathered under `assets/audio/temp_sounds/`.
- **Fonts:** Jersey 10 and VT323 (SIL Open Font License).
- **Testing:** [GUT](https://github.com/bitwes/Gut) by bitwes.

# Repository

```text
https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys
```
