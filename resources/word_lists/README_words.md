# Word Lists

How mission words work (#43). A new mission only needs **JSON files and one Inspector setting, no code changes**.

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
- Each theme needs **at least 10 words** (the tests check this). Bigger themes give more variety between playthroughs.
- A theme can be reused by any mission (e.g. `zombie` is in every mission).


## Current themes and missions

| Mission | Themes | Words | Buckets |
|---|---|---|---|
| 1. Defend the Suburbs | zombie, positive, suburb | 20 | 1, 2, 3 |
| 2. Hold the Hospital | zombie, positive, hospital | 25 | 1, 2, 3 |
| 3. Secure the Shopping Centre | zombie, positive, shopping | 40 | all |
| 4. Rescue the Survivors | zombie, positive, rescue | 25 | all |
| 5. Protect the Military Base | zombie, military | 30 | 2, 3, 4 |
| 6. Final Stand: Downtown | zombie, city, suburb, hospital, shopping, rescue, military, challenge | 35 | 3, 4 |

- `challenge` holds rare words (e.g. ebullient, indomitable). Keep it out of early missions so new players don't get surprised.
- Missions 4-6 have word lists ready, but their scenes still need **Word List Path** set once they're built.

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
- **British/NZ spelling.** We use British/NZ spelling over US spelling (e.g. colour, not color).
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
- Missions 1-6 all have a mission file
- Mission 3's themes have at least 15 words of 9+ letters for the Tank boss