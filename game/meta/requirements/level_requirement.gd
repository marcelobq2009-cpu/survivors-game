class_name LevelRequirement
extends UnlockRequirement
## "Alcancar o nivel X numa partida".

@export var level: int = 10


func is_met(profile: ProfileData) -> bool:
	return profile.max_level >= level


func progress(profile: ProfileData) -> float:
	return clampf(float(profile.max_level) / maxf(1.0, level), 0.0, 1.0)


func describe() -> String:
	return "Alcance o nivel %d numa partida" % level
