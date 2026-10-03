class_name KillsRequirement
extends UnlockRequirement
## "Derrotar X zumbis no total (somando todas as partidas)".

@export var total_kills: int = 1000


func is_met(profile: ProfileData) -> bool:
	return profile.total_kills >= total_kills


func progress(profile: ProfileData) -> float:
	return clampf(float(profile.total_kills) / maxf(1.0, total_kills), 0.0, 1.0)


func describe() -> String:
	return "Derrote %d zumbis (total)" % total_kills
