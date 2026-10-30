# Milestone 4 - Josiah Natanielu

- **Game Name:** Dead Keys
- **Name:** Josiah Natanielu (natanijosi)
- **Role:** FX and Audio Programming

## Weights

| Criterion | Weight | Default | Range |
|---|---|---|---|
| Code video | 15 | 15 | 10 to 20 |
| Good code | 15 | 20 | 10 to 30 |
| Bad code | 25 | 20 | 10 to 30 |
| Development process | 15 | 20 | 10 to 30 |
| Reflection | 30 | 25 | 10 to 40 |
| **Total** | **100** | | |

I weighted more heavily to Reflection and Bad Code because I felt that it was easier to discover what of my code was bad than it was good. As well as I believe I learned more from this project in terms of reflection.

## Team Summary (Milestone 3)

- Romart Danganan (CGRA 359, lead programmer, project manager, integration and testing lead, GDD author)
- William Johnston (CGRA 359, gameplay and mechanics programming: zombie state machine, enemy types, wave spawning, object pooling, 360 degree spawning, barrier ring)
- Nicole Lai (CGRA 359, tools and systems programming: original typing controller, progression, gold and save system, mission unlocks, word list system, zombie sprite sheets)
- Josiah Natanielu (CGRA 359, FX and audio programming: mistake and jam system, combo counter, audio system and sound effects, mission success and failed screens, How to Play page)

### Repositories and Links

- Game repo (all files in this main repo): https://gitlab.ecs.vuw.ac.nz/course-work/cgra359/2026/assignments/danganroma/dead-keys
- Gameplay: https://www.youtube.com/watch?v=Dwt_8BhijVM 

### Game

Dead Keys is a 2D top-down zombie defence game for PC, built in Godot 4.7. Every zombie carries a word above its head. Typing the word loads ammunition into the gun, but typing never damages anything: the player still has to aim with the mouse and fire. Typing skill decides how much ammo exists, aiming skill decides whether it is spent well.

### Development Process

In development we initially pushed straight to main during the building of the foundation of the game but later on, moved on to working with a dev branch. Gitlab issues were constructed for each feature with initial goal/s, followed by a checklist of tasks and finally a checklist for the acceptance criteria. We worked in two-week sprints planned out so that we could work effficiently. Unfortunately the pace of the sprints were about twice as much as we were able to work at the time. The absence of any design students in our team also weakened our pace. 

## Code Video

- Link: https://youtu.be/KxE6tZnAhgw
- This goes into depth about the code I was able to contribute to CGRA359 project.


## Good Code

### 1. Centralized audio manager

- [Audio Bus](scripts/autoload/audio_bus.gd), `var SFX`, `play()`

The audio system centralises sound resources in the SFX dictionary and provides a shared `Audio.play()` function that other scripts can call using descriptive sound names. This means other systems do not need to know audio file paths or manage playback themselves. For example, the mistake system can play a sound using `Audio.play("wrong_keystroke")`. This reduces duplicated code and makes sounds easier to replace or maintain, while checking that the requested sound exists helps prevent errors

### 2. Signal drive Mistake System

- [Mistake System](scripts/systems/mistake_system.gd), `ready()`, `_typing_mistake()`, `_correct_stroke()`

- [Typing Controller](scripts/typing/typing_controller.gd), `check_letter()`

The MistakeSystem uses Godot signals to respond to events from the TypingController and AbilityState, including incorrect keystrokes, correct keystrokes, completed words and ability charge changes. This separates mistake tracking and combo management from the code responsible for detecting typing input. For example, the typing controller emits a signal when a word is completed, allowing the mistake system to increment the combo without needing to handle the word-processing logic itself. This makes the system easier to understand and maintain because each component has a more clearly defined responsibility. It also allows the systems to be modified independently, reducing the need to change the mistake system whenever the underlying typing implementation changes, provided the relevant signals remain consistent.

### 3. Audio player cleanup

- [Audio Bus](scripts/autoload/audio_bus.gd), `clear_music()`, `clear_sounds()`
- [Mission 1](scripts/missions/mission_1.gd), `_display_mission_success_overlay()`, `_display_mission_fail_overlay()`

The audio system creates a separate `AudioStreamPlayer` for each sound effect, allowing multiple sounds to play independently. It stores these players in the _active array and provides `clear_sounds()` and `clear_music()` methods to stop and remove audio when needed. This allows other systems to control sound effects and music without managing individual audio players themselves. Keeping audio cleanup within the audio manager centralises this responsibility, makes playback easier to manage, and helps keep the system organised and maintainable.

## Bad Code

### 1. Hard-coded sound volumes in Audio

- [Audio Bus](scripts/autoload/audio_bus.gd), `play()`

The audio system currently uses multiple conditional statements inside `Audio.play()` to assign specific volume levels to individual sound effects. Although this allowed me to adjust sounds that were too loud or quiet during development, the approach can become messy and difficult to maintain as more sounds are added. Each new sound that requires a volume adjustment must be added to one of the conditions, while changing an existing sound's volume requires modifying the playback function itself. This also means the volume parameter passed into `Audio.play()` is overridden for sounds included in these conditions, which can make the function's behaviour less predictable. A better approach would be to store per-sound volume levels in a separate dictionary and retrieve the appropriate value during playback. This would keep audio configuration separate from playback logic and make individual volume adjustments easier to manage.

### 2. Input Handling for Audio

- [Main Menu](scripts/ui/main_menu.gd), `_input()`
- [Home Base](scripts/ui/home_base.gd), `_input()`

The `_input()` function plays audio directly when the player clicks the mouse. It checks whether the cursor is hovering over a Button and plays either a click or thud sound. While this works, it combines input detection with audio handling, making the function responsible for two different tasks. As more interactions are added, this could make input code more cluttered and harder to maintain. A better approach would be to separate input detection from the action being performed, allowing the relevant UI or gameplay system to trigger the appropriate sound.

### 3. Deeply hard-coded node paths

- - [Mistake System](scripts/systems/mistake_system.gd), variable declarations (top of page)

The MistakeSystem uses long, hardcoded node paths to access UI elements, such as the mistake counter and ability status label. For example, the mistake label is accessed through several levels of the HUD hierarchy using a path that depends on the current scene structure. Although this works with the existing scene, it makes the script more fragile because moving or renaming one of the parent nodes can break the reference. The long paths also make the declarations harder to read and mean the mistake system depends on the internal layout of the HUD rather than interacting with a more clearly defined interface. One possible improvement would be to expose the required node references through exported variables and assign them in the Godot Inspector, or to create dedicated HUD methods for updating the mistake counter and combo display. This would reduce dependence on the scene hierarchy and make future UI changes easier to manage, although exported references would still need to be assigned correctly.

## Development Process

- **Feature ownership**. I was responsible for the game's audio and supporting systems, including the mistake and jam system, combo counter, audio manager, sound effects, music and menus. I worked on these features individually and integrated them into the existing game.

- **Centralised implementation**. I developed the audio manager to provide a shared way for other systems to play sound effects and music. This meant individual scripts could request sounds without needing to manage audio players or load audio resources themselves.

- **Integration with existing systems**. Some of my tasks required connecting my work to systems developed by other team members. For example, audio needed to respond to gameplay events, while the mistake and combo systems needed to interact with the existing typing and ability systems.

- **Testing and adjustments**. I tested my features within the game to check that they worked as intended. This included adjusting sound volumes, checking audio playback and ensuring menus and gameplay systems functioned correctly together.

- **Time management challenges**. Balancing development with other commitments made it difficult to consistently keep up with the planned sprint schedule. Some tasks took longer than anticipated, particularly when implementing and integrating features. This highlighted the importance of setting more realistic timeframes, breaking larger tasks into smaller steps and allowing sufficient time for testing.

## Reflection

### Preparing To Learn

At the beginning of the project, I recognised that I was less experienced than some of the other members of the team, particularly when it came to implementing more complex game systems. I saw the project as an opportunity to improve my programming skills, become more familiar with Godot and learn from the experience of working alongside other developers. Rather than expecting to understand everything beforehand, I knew I would need to research, experiment and ask for help when encountering unfamiliar concepts.

### Learning Through Development

A lot of my learning came from working through unfamiliar tasks and figuring out how different systems could be implemented. Through the development of the mistake system i became more acquainted with the use of signals as well as their more orderly functionality which helps Developing the audio manager, working with sound effects and composing music gave me experience beyond just writing gameplay code. I also gained experience connecting systems together and making sure they functioned correctly within the existing game. I found that understanding a concept in theory was different from actually implementing it, as problems often only became apparent once I started testing my work. This taught me the importance of experimenting, evaluating the results and making adjustments throughout development.

### Key Concepts

One of the key concepts I developed a better understanding of was modular programming. Having a centralised audio manager meant other systems could request sounds without needing to manage the playback themselves. I also gained a better understanding of Godot's signals and how they allow different systems to communicate without being too tightly connected. Another important area was resource management, particularly creating and cleaning up audio players after playback. These concepts helped me understand how individual systems can be organised to make a larger project easier to maintain.

### What I will take forward

I will take the experience and technical knowledge gained from this project into future development work. I am now more comfortable working with Godot, implementing gameplay-related systems and integrating my work with other people's code. I also have a better appreciation for communication, task planning and maintaining a consistent development workflow. Most importantly, I have learned that I do not need to understand everything before starting a task, as a significant amount of learning can happen through implementation and problem-solving.

### What I would do differently

If I were to approach this project again, I would spend more time breaking down my tasks into smaller, manageable steps before beginning implementation. I would also aim to test features earlier and more frequently rather than relying on testing once a feature is mostly complete. This would make it easier to identify problems before they become more difficult to resolve. I would also try to become more involved in discussions and ask for feedback earlier when I am unsure about an implementation. This could help me work more efficiently and avoid spending too much time figuring out problems independently.

### Post-mortems

Overall, I believe the project was a valuable learning experience, even though our development process had some difficulties. One of our strengths was that each team member contributed different areas of expertise, allowing us to build a game with several interconnected systems. However, our sprint planning was often too ambitious, and we could have managed our workload and time more effectively. Personally, I believe I could have contributed more in certain areas, but I also recognise how much I learned from working alongside the other members. In future projects, I would aim to contribute more confidently, communicate more frequently and take greater initiative when approaching unfamiliar tasks.
