class_name AchievementRequirement
extends UnlockRequirement
## "Ter a conquista X".

@export var achievement_id: StringName = &""


func is_met(profile: ProfileData) -> bool:
	return profile.achievements.has(String(achievement_id))


func describe() -> String:
	var a: AchievementData = Content.find_achievement(achievement_id)
	return "Conquista: %s" % (a.display_name if a else String(achievement_id))
