# Typing and Ammunition Integration Test — 4 August 2026

**Tester:** Romart Danganan  
**Branch:** `romart/weapon-projectiles`  
**Engine:** Godot 4.7  
**Scene:** `gameplay_prototype.tscn`  
**Overall result:** All current integration tests passed after fixing one target-lifecycle defect

## Purpose

Verify that the merged `TypingController` works inside the gameplay prototype,
awards ammunition through the existing `AmmoSystem`, and supports the temporary
typing-to-shooting loop against `ProjectileTestTarget`.

## Integration under test

```text
Player reads the word above the dummy target
→ player types the complete word
→ TypingController emits `word_completed`
→ GameplayPrototype calls `AmmoSystem.add_ammunition(1)`
→ AmmoSystem updates the ammunition HUD
→ player fires the earned ammunition
→ projectile damages the dummy target
```

For temporary debugging, completing a word immediately assigns another random
word above the dummy target.

## Results

| Test | Expected | Result | Pass? |
|---|---|---|---|
| Word display | A random word appears above the test target | A random word appeared above `ProjectileTestTarget` when the mission started | Pass |
| Correct letters | Correctly typed letters change colour | Correct letters changed colour and advanced typing progress correctly | Pass |
| Incorrect letters | Incorrect input does not advance progress | Incorrect letters did not advance progress and debugging output showed the expected and entered letters | Pass |
| Word completion | Completing a word emits `word_completed` | Completing the displayed word emitted the signal and selected another temporary debugging word | Pass |
| Ammo reward | Completing a word adds one ammunition | Ammunition increased by exactly one for every completed word | Pass |
| HUD update | Ammo label and bar update automatically | The existing AmmoSystem signal updated both the ammunition label and progress bar | Pass |
| Capacity limit | Typing cannot raise ammunition above capacity | Repeated word completion did not increase ammunition beyond the configured maximum | Pass |
| Weapon use | Earned ammunition can be fired | Ammunition earned by typing could be used by the WeaponController | Pass |
| Ammo consumption | One successful shot consumes one ammunition | Each successful shot consumed exactly one ammunition | Pass |
| Projectile behaviour | Projectile still travels and damages the target | Projectiles travelled toward the cursor and damaged the temporary target correctly | Pass |
| Target removal | Typing stops safely after the target is freed | After the target was destroyed, the TypingController detected the invalid label, cleared its target state and ignored further keyboard input | Pass |

## Defect found during testing

The first version crashed after the dummy target was destroyed.

`ProjectileTestTarget` owns the temporary `WordLabel`. When the target reached
zero health, the target and its child label were freed. However, the
`TypingController` still held a reference to that deleted label and continued
accepting keyboard input.

When the next correct character caused `update_label()` to run, Godot produced
an error similar to:

```text
Invalid assignment of property or key 'text' with value of type 'String'
```

## First fix and remaining problem

A validity check was first added so the controller would not write to a freed
label. This stopped the crash, but typing still continued internally.

The output still showed messages such as:

```text
mistake - expected c got s
correct - progress: 1/4
WORD COMPLETE: code
Completed word: code | Ammunition added: 1
```

This meant the player could continue completing an invisible word and earning
ammunition even though no target existed.

## Final fix

The `TypingController` now:

- checks that typing is enabled before processing keyboard input;
- checks that `word_label` is still a valid instance;
- calls `clear_target()` when the label has been freed;
- clears `current_word`;
- resets `typed_index`;
- removes the invalid label reference;
- disables further typing until a future target is assigned.

After this change, destroying the dummy target produced:

```text
Typing disabled: no active target
```

Further letter input produced no progress, mistake or word-completion output,
and no additional ammunition was awarded.

## Temporary implementation

- The word is displayed above `ProjectileTestTarget`.
- A new random word is assigned after each completed word for debugging.
- The dummy target is temporary and will later be replaced by Walkers.
- The current prototype supports one temporary word label.
- Final multi-Walker word registration, shared-prefix highlighting and
  completed-word removal will be implemented during later Walker integration.
- Final enemy death, word removal and target replacement are outside this
  integration test.

## Follow-up

- Replace the temporary single-label setup with multiple registered Walker word targets.
- Remove `assign_new_word()` from `complete_word()` when words are permanently attached to Walkers.
- Make completed words disappear and remain unavailable after being typed once.
- Unregister a Walker's word target when that Walker dies.
- Preserve `word_completed(word, ammunition_reward)` for AmmoSystem integration.
