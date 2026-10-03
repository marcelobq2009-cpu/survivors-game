class_name SurviveRequirement
extends UnlockRequirement
## "Sobreviver X segundos no mapa Y" (modo normal ou ranqueado).

@export var map_id: StringName = &""
## 0 = a duracao inteira do modo normal (Config.game.match_duration()).
@export var seconds: float = 0.0


func needed_seconds() -> float:
	return seconds if seconds > 0.0 else Config.game.match_duration()


func best_time(profile: ProfileData) -> float:
	return maxf(profile.best_time_by_map.get(String(map_id), 0.0),
			profile.best_ranked_time.get(String(map_id), 0.0))


func is_met(profile: ProfileData) -> bool:
	return best_time(profile) >= needed_seconds() - 0.01


func progress(profile: ProfileData) -> float:
	return clampf(best_time(profile) / needed_seconds(), 0.0, 1.0)


func describe() -> String:
	var map_name := String(map_id)
	var map: MapData = Content.find_map(map_id)
	if map:
		map_name = map.display_name
	return "Sobreviva %d min em %s" % [roundi(needed_seconds() / 60.0), map_name]
