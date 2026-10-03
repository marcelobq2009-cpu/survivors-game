class_name BossRequirement
extends UnlockRequirement
## "Derrotar X chefes (total)".

@export var bosses: int = 1


func is_met(profile: ProfileData) -> bool:
	return profile.bosses_killed >= bosses


func progress(profile: ProfileData) -> float:
	return clampf(float(profile.bosses_killed) / maxf(1.0, bosses), 0.0, 1.0)


func describe() -> String:
	return "Derrote %d chefe%s" % [bosses, "" if bosses == 1 else "s"]
