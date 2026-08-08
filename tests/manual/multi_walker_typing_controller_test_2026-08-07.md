# Multi-Walker TypingController Manual Test — 7 August 2026

**Tester:** Romart Danganan  
**Branch:** `romart/support-multiple-walker-words`  
**Engine:** Godot 4.7  
**Scene:** William's Walker wave test scene under `tests/zombies/`

## Purpose

Verify that one shared `TypingController` can track multiple active Walker words,
filter them using a shared typed prefix, safely replace completed words, remove
dead targets and keep every word label visible above the Walker sprites.

## Test setup

- William's wave test spawns multiple Walkers.
- Each spawned Walker registers its `WordLabel` with one shared
  `TypingController`.
- Active Walkers receive unique words from the temporary test word list.
- The test scene does not include `AmmoSystem`, so ammunition gain was not
  verified in this test.
- `word_completed(word, ammunition_reward)` remains available for later gameplay
  integration.

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Multiple target registration | Every spawned Walker is registered with one shared controller | All active Walkers were registered and displayed typeable words | Pass |
| Newest-target bug | Player is not restricted to the newest spawned Walker | Words belonging to earlier and later Walkers could all be typed | Pass |
| Shared first-letter prefix | Typing a shared first letter highlights every matching word | All matching Walker words highlighted correctly | Pass |
| Shared multi-letter prefix | Matching words remain highlighted while they share the typed prefix | Matching words continued highlighting the shared prefix correctly | Pass |
| Prefix filtering | A non-matching word loses its highlight when the prefix narrows | Non-matching words returned to normal display while the valid match remained highlighted | Pass |
| Correct-stroke handling | A key is accepted when at least one active word matches | Valid shared-prefix input advanced correctly | Pass |
| Mistake handling | A key matching no active word emits one typing mistake | Invalid input was rejected without advancing any word | Pass |
| Word completion | Completing a full word emits the completion behaviour once | The selected Walker word completed correctly | Pass |
| Word replacement | A completed word is replaced with a new random word | The same living Walker immediately received a new word | Pass |
| Walker remains alive | Completing a word does not remove or kill the Walker | Walker remained active after its word changed | Pass |
| Replacement remains typeable | The new word can be typed normally | Replacement words accepted input correctly | Pass |
| Active duplicate prevention | Two active Walkers do not receive the same word | No duplicate active words were observed | Pass |
| Dead-target removal | A dead Walker is removed from the controller | Removing a Walker did not affect the remaining active words | Pass |
| Freed-label safety | Deleted Walker labels do not leave invalid references | No invalid object or freed-label errors occurred | Pass |
| Remaining-target safety | Removing one Walker does not disable typing for others | Remaining Walker words continued working normally | Pass |
| Word reuse after removal | A word may become available again after its Walker is removed | Removed target words were no longer reserved by the controller | Pass |
| Label draw priority | Word labels render above Walker sprites | Walker bodies no longer covered the displayed words | Pass |
| Parser/runtime stability | Test runs without parser or runtime errors | No parser errors or invalid node-reference errors occurred | Pass |

## Issues found

- The original wave test created one `TypingController` per Walker, which meant
  the effective typing behaviour only worked reliably with the newest spawned
  Walker.
- Completed words originally disappeared permanently, which could leave a living
  Walker without a way to generate further ammunition after gameplay
  integration.
- Walker sprites could render over their own or nearby word labels.

## Fixes applied

- Replaced the per-Walker controller setup with one shared
  `TypingController`.
- Added registration and unregistration for individual Walker word targets.
- Added shared-prefix matching across all active words.
- Added prefix highlighting and clearing for matching and non-matching words.
- Replaced completed words with new random unique words while keeping the Walker
  alive.
- Removed dead or freed targets safely from the controller.
- Prevented duplicate words across active Walkers.
- Raised the word-label draw priority so labels remain visible above Walker
  sprites.

## Follow-up

- Connect `word_completed(word, ammunition_reward)` to the gameplay prototype's
  `AmmoSystem`.
- Integrate the shared multi-Walker controller into
  `gameplay_prototype.tscn`.
- Verify that every completed replacement word awards exactly one ammunition.
- Verify projectile damage, Walker death and word unregistration together in
  the integrated gameplay prototype.
- Add automated tests for target registration, prefix filtering, duplicate-word
  prevention and target removal when practical.
