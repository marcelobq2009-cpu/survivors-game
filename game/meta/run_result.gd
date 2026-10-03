class_name RunResult
extends RefCounted
## Resumo de uma partida terminada (tela de resultado + save + ranking).

var mode: RunSetup.Mode = RunSetup.Mode.NORMAL
var map_id: String = ""
var character_id: String = ""
var victory: bool = false
var time: float = 0.0
var kills: int = 0
var level: int = 1
var xp_total: int = 0
var gold_collected: int = 0
var damage_total: float = 0.0
## weapon_id -> dano causado
var damage_by_weapon: Dictionary = {}
var bosses_killed: int = 0
## Quem causou a morte ("" se venceu ou desistiu).
var death_cause: String = ""

# Preenchidos pelo ProgressService ao fechar a partida:
var score: int = 0
var gold_reward: int = 0
var new_record: bool = false
var rank_position: int = 0
var new_unlocks: Array[ContentData] = []
var new_achievements: Array[AchievementData] = []


func is_ranked() -> bool:
	return mode == RunSetup.Mode.RANKED


## Id da arma que mais causou dano ("" se nenhuma).
func best_weapon_id() -> String:
	var best := ""
	var best_damage := -1.0
	for id: Variant in damage_by_weapon:
		var d := float(damage_by_weapon[id])
		if d > best_damage:
			best_damage = d
			best = str(id)
	return best
