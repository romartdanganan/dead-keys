extends RefCounted

# top five endless survival scores, saved in their own file so the main save is never touched

const MAX_ENTRIES: int = 5
const POINTS_PER_KILL: int = 10
const POINTS_PER_ROUND: int = 100

# a var so GUT can point it at a throwaway file
static var save_path: String = "user://endless_scores.cfg"


static func compute_score(kills: int, rounds_cleared: int) -> int:
	return kills * POINTS_PER_KILL + rounds_cleared * POINTS_PER_ROUND


# newest first is never needed, entries are always kept highest score first
static func load_scores() -> Array:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return []
	return config.get_value("endless", "top", [])


static func best_score() -> int:
	var scores := load_scores()
	return scores[0]["score"] if not scores.is_empty() else 0


# returns the new score's place from 1 to 5, or 0 if it did not make the table
static func submit(score: int, round_reached: int) -> int:
	var scores := load_scores()
	var entry := {"score": score, "round": round_reached, "id": Time.get_ticks_usec()}
	scores.append(entry)
	scores.sort_custom(func(a, b): return a["score"] > b["score"])
	if scores.size() > MAX_ENTRIES:
		scores.resize(MAX_ENTRIES)
	var config := ConfigFile.new()
	config.set_value("endless", "top", scores)
	config.save(save_path)
	for i in scores.size():
		if scores[i]["id"] == entry["id"]:
			return i + 1
	return 0
