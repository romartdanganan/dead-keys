# Word Lists

How mission words work (#43). A new mission only needs **JSON files, no code changes**.

## How it works

1. **Theme files** hold words on one topic (suburb, hospital, zombie...).
2. A **mission file** picks which themes to mix, how many words to use, and which word lengths are allowed.
3. `WordListLoader` merges the themes, removes duplicates, filters by bucket, shuffles, and keeps `word_count` words.
4. `TypingController` gives each zombie a random word from that pool that isn't already on screen.

## Folder layout

```
word_lists/
  themes/           one file per theme, shared by any mission
  missions_words/   one file per mission
```

## Theme file: `themes/<name>.json`

```json
{
  "theme": "suburb",
  "words": ["gate", "home", "garden", "driveway"]
}
```

- The **file name is the theme's ID**: `suburb.json` is referred to as `"suburb"`.
- Aim for **15 to 25 words** per theme.
- A theme can be reused by any mission (e.g. `zombie` is in Missions 1 and 2).

## Mission file: `missions_words/missionN_words.json`

```json
{
  "themes": ["zombie", "positive", "suburb"],
  "word_count": 20,
  "allowed_buckets": [1, 2, 3]
}
```

| Field | Meaning |
|---|---|
| `themes` | Theme file names without `.json`, lowercase |
| `word_count` | How many words the mission picks from the merged themes |
| `allowed_buckets` | Which word lengths are allowed (see below). Empty or missing means all |

## Buckets

Buckets reuse the ammo tiers from GDD §2.2.1, so there is no separate difficulty label. They are **worked out from word length** by `TypingController.get_ammo_reward_for_word()`, not stored in the JSON.

| Bucket | Word length | Ammo reward |
|---|---|---|
| 1 | 3-4 letters | 1 |
| 2 | 5-7 letters | 2 |
| 3 | 8-10 letters | 3 |
| 4 | 11+ letters | 4 |

## Restricting buckets per wave

A wave can narrow the buckets further, e.g. Runners are fast, so they get short words:

```gdscript
wave_2b.allowed_buckets = [1]
```

- Empty (the default) means the wave uses the whole mission pool.
- If no unused word fits, the zombie gets **any** unused word instead, so it never spawns without a word.

## Word rules

- **Lowercase a-z only**: no capitals, spaces, hyphens or accents, since the player can't type them.
- **British/NZ spelling.** Skip words spelt differently in US and UK English (colour/color) so no one gets caught out.
- **Common words first.** Mission 1 is the tutorial, so nothing over 10 letters (GDD §5.1).
- **Accessibility:** think about players with dyslexia. Prefer regular spellings, and avoid silent letters and words that are easy to mix up.
- **No duplicates within a theme.** Duplicates across themes are fine, the loader removes them when merging.

## Adding a new mission

1. Add any new theme files to `themes/`.
2. Create `missions_words/missionN_words.json`.
3. On the mission scene, select the **TypingController** node and set **Word List Path** in the Inspector.
4. Run `tests/unit/test_word_lists.gd` in GUT.

## Tests

`tests/unit/test_word_lists.gd` checks that:

- every theme has at least 10 words, all lowercase a-z, with no duplicates
- every mission file parses, lists themes, and only uses buckets 1-4
- every theme a mission names actually has a file (a typo would otherwise be skipped silently)
- every mission can fill its `word_count` after bucket filtering
- Mission 1 has no word over 10 letters
