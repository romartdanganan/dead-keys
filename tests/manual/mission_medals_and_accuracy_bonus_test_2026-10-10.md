# Mission Medals and Accuracy Bonus Manual Test - 10 October 2026

**Tester:** Romart Danganan
**Branch:** `romart/medals-accessibility-and-art`
**Engine:** Godot 4.7
**Scene:** scenes/missions/mission_1.tscn, Mission Success screen, scenes/ui/home_base.tscn

## Purpose

Verifies the mission rating from #65 (GDD 2.6): every mission win gives a
bronze, silver or gold medal from typing accuracy, wall health left and lives
lost, pays the matching bonus gold (+25, +50, +100), adds a perfect accuracy
bonus (+10% of the base reward) for a mission with no typing mistakes, and
saves each mission's best medal so it shows on the Home Base mission details
panel. Also checks the new 32x32 gold, silver and bronze medal sprites on the
success screen and Home Base.

## Test setup

- Played Mission 1 from the editor through the normal Home Base flow
- Medal thresholds used: gold needs 95%+ accuracy, 60%+ wall health and no
  lives lost; silver needs 85%+ accuracy and 30%+ wall health; any other win
  is bronze
- Best medal persistence checked by quitting and relaunching the game
- Not covered: Missions 2 and 3 cards on Home Base (card unlocking is
  Nicole's #32), and the fail screen, which gives no medal by design

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Careful Mission 1 win | Success screen shows a medal, total gold, the reward and medal bonus breakdown, and typing accuracy | All lines shown with the right medal | Pass |
| Perfect typing | A win with no typing mistakes shows the perfect accuracy bonus line | Bonus line shown | Pass |
| Gold paid | Gold at Home Base goes up by the total shown on the success screen | Matched the success screen total | Pass |
| Best medal on Home Base | Mission 1 details panel shows the medal instead of NONE | Medal shown | Pass |
| Worse run afterwards | Success screen shows the worse medal, Home Base keeps the better one | Better medal kept | Pass |
| Best medal persistence | Medal still shown after quitting and relaunching | Still shown | Pass |
| Win after losing a life | A run with a lost life cannot get GOLD | No gold medal given | Pass |
| Medal sprite on the success screen | The medal sprite shows above the stats, sharp and matching the medal won | Sprite shown and sharp | Pass |
| Medal sprite on Home Base | The best medal sprite shows under BEST MEDAL instead of the medal name | Sprite shown, name hidden | Pass |
| Mission with no medal | Home Base shows NONE and no sprite | NONE shown, no sprite | Pass |

## Issues found

- Home Base showed the medal sprite and the medal name together, which looked
  cluttered.

## Fixes applied

- The medal name label now hides when a sprite is shown, and only "NONE"
  stays as text.

## Follow-up

- Tune the medal thresholds with playtest #3 data
- Mission cards for Missions 2 and 3 should show their medal once Nicole's
  #32 card unlocking is merged
- Record the medal thresholds and the always on perfect accuracy bonus in
  GDD v1.4 and the Tech Spec
