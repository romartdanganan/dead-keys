# Milestone 2 — Romart Danganan

## Role

Lead Programmer / Project Manager. I coordinate the overall team workflow and day-to-day development process, including Discord announcements, task coordination, issue triage, GitLab issue/label/milestone
management, merge-review availability, branching and commit conventions, and
team workflow announcements.  

On the technical side, I own the core gameplay architecture, scene flow and
front-end integration that other systems connect into, including the Main Menu,
Home Base, gameplay transitions and shared system interfaces. I also handle
cross-branch integration, integration testing, and resolving issues that appear
when separately developed systems are combined.

## What I contributed to the MVP

- Set up the Godot project and repository structure (#5).
- Built the Main Menu and Home Base placeholder, including scene switching between them (#6).
- Built the gameplay prototype scene and HUD shell (#7).
- Designed and implemented the `AmmoSystem`, including current/maximum ammunition, capped rewards, consumption, capacity upgrades, reset behaviour, HUD integration, and the public interface used by other gameplay systems (#9).
- Implemented the prototype weapon and projectile systems, including mouse aiming, firing, ammunition consumption, projectile movement, lifetime, collision and the reusable `take_damage()` interface (#10).
- Integrated the merged `TypingController` with the `AmmoSystem` so completed words award ammunition, and fixed target-lifecycle bugs that could otherwise allow invalid or invisible typing after a target was freed (#18).
- Fixed the weapon-jam behaviour so mistakes made during an active jam still consume ammunition but do not build toward another jam. (#20)
- Configured Git LFS for binary game assets across the repository (#17).
- Reworked the `TypingController` from one controller per Walker to one shared controller supporting multiple simultaneous Walker words, shared-prefix filtering and highlighting, unique replacement words, and safe registration/unregistration as Walkers spawn and die (#22).
- Raised Walker word-label draw priority so words remain readable above Walker sprites during multi-enemy gameplay.
- Conducted the Milestone 2 internal playtest, documented the findings, and identified follow-up usability work for Walker readability, ammunition feedback, manual firing visibility and mistake feedback (#15).
- Set up the GitLab issues, labels and milestones used by the team, and established the team's Git workflow, branching rules, `dev` integration workflow (Williams Idea for 'dev' branch) and commit-message conventions.
- Continued cross-branch integration and merge-review work as Nicole, William and Josiah's systems were added to the shared prototype.

## Plan for Milestone 3

Continue owning core-systems integration as the remaining gameplay systems land
and the prototype develops beyond the Milestone 2 MVP.

I will continue developing the Main Menu and Home Base flow that I originally
implemented, expanding it to connect the player to the major progression and
pre-mission systems planned in the GDD. This includes integrating navigation to
future menus and scenes such as:

- Settings
- Ability selection
- Permanent Upgrades
- Mission Supplies
- Mission selection and mission-specific launch flow

I will also focus on implementing the Ability System (§2.2.3) and Permanent
Upgrade Tracks (§2.6.1), since both are architecturally central and connect
directly to the Home Base and pre-mission flow.

As additional missions are implemented, I will integrate them into the existing
Home Base mission-selection flow and ensure transitions between menus, missions
and return states remain consistent.

I will continue project-management and integration responsibilities throughout
Milestone 3, including issue triage, merge-request review, integration testing,
team coordination, and keeping the GDD and technical documentation consistent
with the implemented game.