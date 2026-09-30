# Dead Keys

**Dead Keys** is a top-down typing and shooting game built in **Godot 4.7**.

The player types words above Walkers to generate ammunition, aims with the mouse,
and fires projectiles to stop the Walkers before they overwhelm the defensive
wall.

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

Expected flow:

```text
Main Menu
→ Operations Hub
→ Mission 1
→ Gameplay Prototype
```

## Controls

| Input | Action |
|---|---|
| Keyboard letters | Type the words above Walkers |
| Mouse movement | Aim the crosshair |
| Left mouse button | Fire toward the cursor |
| F4 | Reset ammunition for temporary debugging |
| F5 | Increase maximum ammunition for temporary debugging |
| F6 | Add ammunition for temporary debugging |
| F7 | Consume ammunition for temporary debugging |

The F4–F7 controls are temporary prototype/debug controls.


# Important Prototype Behaviour

## Multi-Walker typing

One shared `TypingController` manages all active Walker words.

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
→ gain ammunition
→ the same living Walker receives a new unique word
→ the Walker remains alive until shot
```

## Mistakes and weapon jams

- Each typing mistake removes one ammunition.
- Three consecutive mistakes trigger a two-second weapon jam.
- While jammed, firing is disabled.
- Mistakes made during the jam still remove ammunition.
- Mistakes made during the jam do not build toward another jam.

## Current MVP limitations

- Some art and audio are placeholders.
- Temporary debug controls are still present.
- The word list is limited.
- Final progression, abilities, permanent upgrades, supplies and saving are not
  part of the Milestone 2 MVP.
- A polished mission-complete/results screen is not required for the MVP.

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

Tests all current systems that have unit test coverage, this grows over time
as new systems are added, check the folder itself for what's currently
covered rather than relying on this list.

### One-time setup

1. Open the project in Godot.
2. Go to the top of the editor and look for a tab called **AssetLib** or
   **Asset Store** (the exact name varies by Godot version).
3. Search for `GUT`. The listing's title may vary, look for the one whose
   description mentions unit testing for GDScript.
4. Install it.
5. Go to **Project → Project Settings → Plugins** and ensure GUT (may be
   listed as "Gut" or similar) is checked/enabled.

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

The Milestone 2 internal playtest is recorded in:

```text
playtesting/2026-08-milestone-2.md
```

# Development Workflow

Development uses:

```text
feature branch
→ Merge Request into dev
→ integration testing on dev
→ dev merged into main
```

Branch purposes:

- `main` — stable milestone/release branch
- `dev` — shared integration branch
- feature branches — one issue or feature per branch

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

# Repository

```text
https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys
```
