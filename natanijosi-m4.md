# Milestone 4 - Josiah Natanielu

## Weights

| Criterion | Weight | Default | Range |
|---|---|---|---|
| Code video | 10 | 15 | 10 to 20 |
| Good code | 20 | 20 | 10 to 30 |
| Bad code | 20 | 20 | 10 to 30 |
| Development process | 20 | 20 | 10 to 30 |
| Reflection | 30 | 25 | 10 to 40 |
| **Total** | **100** | | |

I weighted more heavily towards Reflection. I believe I didn't contribute as much as the others unfortunately but through this I was able to learn much more than I was able to offer. I do believe I was the least skilled but through this I was given the opportunity to upskill and learn from the other group members

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

- Link: 

## Good Code

### 1. Centralized audio manager

The audio system centralises sound resources in the SFX dictionary and provides a shared `Audio.play()` function that other scripts can call using descriptive sound names. This means other systems do not need to know audio file paths or manage playback themselves. For example, the mistake system can play a sound using `Audio.play("wrong_keystroke")`. This reduces duplicated code and makes sounds easier to replace or maintain, while checking that the requested sound exists helps prevent errors

### 2. Signal drive Mistake System

The MistakeSystem uses Godot signals to respond to events from the TypingController and AbilityState, including incorrect keystrokes, correct keystrokes, completed words and ability charge changes. This separates mistake tracking and combo management from the code responsible for detecting typing input. For example, the typing controller emits a signal when a word is completed, allowing the mistake system to increment the combo without needing to handle the word-processing logic itself. This makes the system easier to understand and maintain because each component has a more clearly defined responsibility. It also allows the systems to be modified independently, reducing the need to change the mistake system whenever the underlying typing implementation changes, provided the relevant signals remain consistent.

### 3. Audio player cleanup

The audio system creates a separate AudioStreamPlayer for each sound effect, allowing multiple sounds to play independently without interrupting one another. It stores these players in the _active array and connects each player's finished signal to a callback that removes the player from the array and queues it for deletion once playback ends. This provides automatic resource cleanup without requiring other game systems to keep track of individual sound players. The active-player list also allows `clear_sounds()` to stop and remove tracked sound effects when needed. Keeping this lifecycle management inside the audio manager makes sound playback easier for the rest of the game to use and helps prevent finished audio players from accumulating unnecessarily in the scene tree.

## Bad Code

### 1. Hard-coded sound volumes in Audio

The audio system currently uses multiple conditional statements inside `Audio.play()` to assign specific volume levels to individual sound effects. Although this allowed me to adjust sounds that were too loud or quiet during development, the approach can become messy and difficult to maintain as more sounds are added. Each new sound that requires a volume adjustment must be added to one of the conditions, while changing an existing sound's volume requires modifying the playback function itself. This also means the volume parameter passed into `Audio.play()` is overridden for sounds included in these conditions, which can make the function's behaviour less predictable. A better approach would be to store per-sound volume levels in a separate dictionary and retrieve the appropriate value during playback. This would keep audio configuration separate from playback logic and make individual volume adjustments easier to manage.

### 2. Input Handling for Audio

The `_input()` function plays audio directly when the player clicks the mouse. It checks whether the cursor is hovering over a Button and plays either a click or thud sound. While this works, it combines input detection with audio handling, making the function responsible for two different tasks. As more interactions are added, this could make input code more cluttered and harder to maintain. A better approach would be to separate input detection from the action being performed, allowing the relevant UI or gameplay system to trigger the appropriate sound.

### 3. Deeply hard-coded node paths

The MistakeSystem uses long, hardcoded node paths to access UI elements, such as the mistake counter and ability status label. For example, the mistake label is accessed through several levels of the HUD hierarchy using a path that depends on the current scene structure. Although this works with the existing scene, it makes the script more fragile because moving or renaming one of the parent nodes can break the reference. The long paths also make the declarations harder to read and mean the mistake system depends on the internal layout of the HUD rather than interacting with a more clearly defined interface. One possible improvement would be to expose the required node references through exported variables and assign them in the Godot Inspector, or to create dedicated HUD methods for updating the mistake counter and combo display. This would reduce dependence on the scene hierarchy and make future UI changes easier to manage, although exported references would still need to be assigned correctly.

## Development Process

- **Feature ownership**. I was responsible for the game's audio and supporting systems, including the mistake and jam system, combo counter, audio manager, sound effects, music and menus. I worked on these features individually and integrated them into the existing game.

- **Centralised implementation**. I developed the audio manager to provide a shared way for other systems to play sound effects and music. This meant individual scripts could request sounds without needing to manage audio players or load audio resources themselves.

- **Integration with existing systems**. Some of my tasks required connecting my work to systems developed by other team members. For example, audio needed to respond to gameplay events, while the mistake and combo systems needed to interact with the existing typing and ability systems.

- **Testing and adjustments**. I tested my features within the game to check that they worked as intended. This included adjusting sound volumes, checking audio playback and ensuring menus and gameplay systems functioned correctly together.

- **Time management challenges**. Balancing development with other commitments made it difficult to consistently keep up with the planned sprint schedule. Some tasks took longer than anticipated, particularly when implementing and integrating features. This highlighted the importance of setting more realistic timeframes, breaking larger tasks into smaller steps and allowing sufficient time for testing.

## Reflection

### Preparing To Learn

At the beginning of the project, I was less experienced with some of the programming and development concepts required to build a complete game. I was particularly interested in improving my understanding of Godot and gaining more practical experience working within a team project. I knew I would have to learn new concepts along the way, so I approached the project as an opportunity to develop my skills and become more confident with game development.

### Learning Through Development

Throughout development, I gained experience implementing systems that I had not worked with extensively before. Working on the audio manager taught me how to organise sound resources, manage audio playback and handle multiple sound effects independently. I also learned more about connecting audio to gameplay events and integrating menus into the existing game. Composing music and implementing sound effects also gave me an opportunity to contribute creatively alongside my programming work. A lot of my learning came from experimenting, identifying problems and making adjustments as the game developed.

### Key Concepts

One of the key concepts I developed a better understanding of was modular programming. Having a centralised audio manager meant other systems could request sounds without needing to manage the playback themselves. I also gained a better understanding of Godot's signals and how they allow different systems to communicate without being too tightly connected. Another important area was resource management, particularly creating and cleaning up audio players after playback. These concepts helped me understand how individual systems can be organised to make a larger project easier to maintain.

### What I will take forward

I will take the experience and technical knowledge gained from this project into future development work. I am now more comfortable working with Godot, implementing gameplay-related systems and integrating my work with other people's code. I also have a better appreciation for communication, task planning and maintaining a consistent development workflow. Most importantly, I have learned that I do not need to understand everything before starting a task, as a significant amount of learning can happen through implementation and problem-solving.

### What I would do differently

If I were to approach this project again, I would spend more time breaking down my tasks into smaller, manageable steps before beginning implementation. I would also aim to test features earlier and more frequently rather than relying on testing once a feature is mostly complete. This would make it easier to identify problems before they become more difficult to resolve. I would also try to become more involved in discussions and ask for feedback earlier when I am unsure about an implementation. This could help me work more efficiently and avoid spending too much time figuring out problems independently.

### Post-mortems

Overall, I believe the project was a valuable learning experience, even though our development process had some difficulties. One of our strengths was that each team member contributed different areas of expertise, allowing us to build a game with several interconnected systems. However, our sprint planning was often too ambitious, and we could have managed our workload and time more effectively. Personally, I believe I could have contributed more in certain areas, but I also recognise how much I learned from working alongside the other members. In future projects, I would aim to contribute more confidently, communicate more frequently and take greater initiative when approaching unfamiliar tasks.
