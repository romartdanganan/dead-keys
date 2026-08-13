# Milestone 2 - Dead Keys

## Role - Tools, Audio & Systems Programmer

I own the foundation of the typing input system, `typing_controller.gd`.

I own the raw keystroke capture, letter filtering, and character-by-character matching, as well as the word display state, which visualises which letters have been typed and which remain.

The GDD flagged keystroke capture as one of the project's main technical risks. My work proves Godot reads letters reliably across different keyboard layouts.

## What I contributed to the MVP

I created the word target that displays above the placeholder enemy, capturing letters through `_unhandled_input` and `InputEventKey`.

I used `event.unicode` rather than `keycode`, so input fits any keyboard layout instead of assuming US QWERTY.

I filtered out mouse clicks, Escape, arrow keys, and held-key repeats so they cannot advance the word. Number keys 1-3 are deliberately left unclaimed for the supply system.

Correct letters advance an index through the word; incorrect letters do not.

Typed and remaining characters are shown in separate colours, chosen to avoid clashing with colours already used elsewhere in the game.

Typing is case-insensitive, so it doesn't matter whether the player types upper or lower case. In a game where a word must be typed in a timely manner, a stray Shift key shouldn't cost the player a bullet. Speed and accuracy of the sequence matter more than capitalisation.

I built the core `word_completed` signal, which carries the completed word and the ammunition reward. Romart later connected this to the AmmoSystem.

## Intended by Milestone 3

I intend to move the word list out of a hard-coded array and into an external resource file.

I also plan to work on save and progression tracking, and audio integration.