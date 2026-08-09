# Milestone 2 Internal Playtest — 9 August 2026

**Tester:** Romart Danganan  
**Playtester:** External playtester  
**Engine:** Godot 4.7  
**Milestone:** Milestone 2 — Prototype

## Purpose

Test whether the current Dead Keys prototype clearly communicates the core
gameplay loop without explaining the controls unless the playtester becomes
stuck.

## Overall result

The playtester understood the typing mechanic immediately and was able to play
the prototype successfully. Typing feedback was clear and no crashes or
game-breaking bugs occurred.

The main usability problems were communicating that ammunition had been earned,
making manual firing obvious, showing the effect of typing mistakes, and
keeping Walker words readable when multiple Walkers converge on the same wall
position.

## Findings

| Finding | Observation | Classification |
|---|---|---|
| Target-word readability | Words were readable during normal movement, but became difficult to read when multiple Walkers converged or overlapped at the same point on the wall | Accepted |
| Typing feedback | The playtester understood that the word above a Walker should be typed and found the typing feedback clear | Accepted |
| Ammunition gain | The playtester did not immediately notice that completing a word added ammunition because their attention remained on the Walker and word area | Accepted |
| Manual firing | The playtester did not initially realise that they needed to aim and shoot the Walker after earning ammunition | Accepted |
| Mistake feedback | The playtester did not initially notice that each typing mistake increased the mistake counter and removed ammunition because their attention remained on typing | Accepted |
| Weapon jam behaviour | The mistake/jam mechanic became understandable after the playtester noticed the mistake feedback | Accepted |
| Stability | No crashes or gameplay-breaking bugs were found during the playtest | Accepted |

## Accepted follow-up improvements

### Walker convergence and word readability

Walkers currently approach the same wall position and can converge or overlap,
which makes their word labels difficult to read.

Follow-up:

- prevent Walkers from stacking on exactly the same wall position;
- spread their wall targets or stopping positions so active words remain
  readable;
- preserve the existing word-label draw priority.

### Manual firing visibility

The playtester understood typing immediately but did not initially realise that
they needed to shoot the Walker afterward.

Follow-up:

- make the crosshair larger and more visually obvious;
- make the aiming/firing interaction easier to notice without requiring an
  explanation.

### Ammunition gain feedback

The ammunition HUD was easy to miss because the player's attention was focused
on the Walker and its word.

Follow-up:

- add a visible `+1` ammunition animation or popup when a word is completed;
- use a bright, noticeable presentation such as yellow;
- keep the normal ammunition counter and bar visible.

### Mistake and ammunition-loss feedback

The playtester did not initially notice that incorrect typing both increased
the consecutive-mistake counter and removed ammunition.

Follow-up:

- add stronger visual feedback when a typing mistake occurs;
- make ammunition loss more noticeable;
- keep the mistake counter readable without pulling too much attention away
  from the active words.

## Deferred work

The accepted usability improvements should be converted into GitLab issues and
scheduled with the remaining prototype-polish work.

They are not recorded as crashes or failures of the core typing system. The
prototype remained playable throughout the session, so only improvements judged
to be milestone-blocking should be prioritised before submission.

## Rejected findings

No playtest findings were rejected.

## Bugs and crashes

No crashes or gameplay-breaking bugs were found during this playtest.

## Conclusion

The core Dead Keys loop was playable and understandable once the player noticed
the shooting, ammunition and mistake-feedback systems.

The strongest part of the prototype was the typing interaction itself. The main
remaining work is presentation and feedback: keeping words readable when
Walkers overlap, making shooting more obvious, and giving clearer visual
feedback for ammunition gains and typing mistakes.
