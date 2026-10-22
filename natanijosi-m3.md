# Milestone 3: Josiah Natanielu (natanijosi)

### Role: FX and Audio System developer

## Weights

| Criterion | Weight |
|----|----|
| Quality of Game | 45 |
| Development process | 35 |
| Use of Engine features | 20 |
| **Total** | **100** |

I have weighted toward *Quality of Game* because most of my work focused on the game's 
atmosphere and presentation: composing two original music tracks for the Main Menu and 
gameplay, finding suitable sound effects, and developing the How to Play, Mission Success 
and Mission Failed menus. I kept *Development Process* relatively close to the default 
because I integrated my work into the existing game, while lowering *Use of Engine Features*
because the technical complexity was less significant than the creative effort involved.

## Contribution claims

The following claims describe my contributions to Milestone 3. The evidence column can be 
updated with the relevant scripts, scenes, commits and merge requests from the repository.

| Area | Claim | Notes | 
|---|---|---|
| Mistake system and combos | Most | Created mistake system file and foundation and developed the initial structure of it as well as the later-added combo system implemented into the mistake system script, implementation of the jamming system into mistake system | 
| Music and Sound Effects | All | Personally developed and composed "play_music" and "main_music" tracks for the game, selected and mixed the rest of the sound effects for preloading in audio system 
| Audio system | Most| Developed the main functionality of the audio_bus.gd autoload, preloads audios, playing audio methods and clearing audio methods| 
| Success and failed screens, How to Play | Most | Proposed success and failed screens and developed main functionality and visual, was polished by others | 

## What I built in Milestone 3

### Audio system

I developed the audio system for Dead Keys, providing the structure needed to integrate 
music and sound effects into the game. This involved making the audio work with the 
existing game systems and ensuring that the music and sound effects could be managed 
appropriately. The audio system helped bring the game's different features together and 
made the experience feel more complete.

The audios system is ran from the audio_bus.gd autoload script which preloads the desired 
sound effects and music into a dictionary. The play() method then adjusts the audio file's
volume appropriately and plays the desired audio file (indicated by entering the dictionary
name of the audio file into the play() parameters). The audio system also carries clear_music()
and clear_sounds() methods to stop any currently playing audio or looping sounds to make space
for any new audios to play.

### Music composition

I personally developed the music for the game using a web audio editor, BeepBox. The music 
contributes to the atmosphere of Dead Keys and helps give the game its own identity. I wanted 
the audio to complement the gameplay rather than simply act as background noise, helping 
create a more engaging experience for the player as seen with the "play_music".

### Sound effects

I ported and integrated the sound effects into the game. This involved bringing the audio 
assets into the project and incorporating them into the appropriate parts of the game as 
well as often mixing and/or editing the sound effects im Capcut so that they fit the game 
approrpriately . Sound effects help communicate what is happening during gameplay and 
provide additional feedback for player actions and game events.

### Mission Success and Mission Failed menus

I developed the Mission Success and Mission Failed menus to handle the outcomes of 
missions. These screens give players clear feedback on whether they have completed or 
failed a mission and form an important part of the transition out of gameplay. Developing 
these menus helped make the mission flow feel more complete and gave the player a clearer
understanding of the game's progression. The menus are also accompanied with the 
appropriate sound effects aiding in either evoking a sense of reward in the player or 
prompting them to take on the challenge again

### How to Play menu

I developed the How to Play menu to help players learn the game's controls and 
mechanics. Since Dead Keys uses a typing-based combat system, it is important that 
players understand how to interact with the game before or during their first attempts 
at playing. The menu provides an accessible place for players to learn the basics without 
having to work everything out through trial and error.

## Commentary

My contribution to the overall game

My main contribution to Dead Keys was improving the game's audio and player
facing menus. While the gameplay systems provide the main mechanics, I focused 
on making the game feel more finished by developing its music, integrating sound 
effects and creating menus for learning the controls and handling mission outcomes.

I also had to ensure that my work fitted into the existing project rather than 
functioning independently. The audio needed to work alongside the team's gameplay 
systems, while the menus needed to connect properly with the mission flow. This meant
considering how my features interacted with other parts of the game and making sure 
they worked as part of the overall experience.

Most of my work was more enhancing player experience through background details and 
helping to complement the significant and main structures developed by the talents 
of my other team members.

## Challenges and learning

One of the important parts of my work was integrating audio and menus into an 
existing game project. These features need to work correctly with the game's state 
and scene transitions, rather than just appearing or playing independently. 
Developing these systems helped me gain more experience with Godot and understand 
how individual features need to connect with the rest of a project.

Creating the music also allowed me to contribute creatively to the game beyond 
programming alone. By composing the music myself and integrating the sound 
effects, I could help shape the atmosphere and presentation of Dead Keys while still 
contributing to its technical development.

## Reflection

Through Milestone 3, I contributed to both the technical and creative sides of 
Dead Keys. Developing the audio system, composing the music, integrating sound 
effects and building the three menus gave me experience working on features that 
directly affect the player's experience. I learned more about integrating systems 
into an existing Godot project and the importance of making individual features work 
together consistently. I unfortunately was not able to contribute to much due to a 
bit of a late start but am glad that I was able to contribute in some sort of way to 
my teammates. Overall, I am proud that my contributions helped make the game feel 
more complete and improved how players interact with it.