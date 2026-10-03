class_name ProfileData
extends RefCounted
## Todo o progresso permanente do jogador (salvo em user://save.json pelo autoload Save).
## Requisitos de desbloqueio e conquistas leem estes numeros.

var player_name: String = "Sobrevivente"
var gold: int = 0
var total_kills: int = 0
var total_runs: int = 0
var total_play_time: float = 0.0
var bosses_killed: int = 0
var max_level: int = 0
## map_id -> melhor tempo no modo normal (segundos).
var best_time_by_map: Dictionary = {}
## map_id -> melhor tempo / pontuacao no ranqueado.
var best_ranked_time: Dictionary = {}
var best_ranked_score: Dictionary = {}
## Mapas concluidos no modo normal (sobreviveu ate o fim).
var completed_maps: Array[String] = []
## Ids de conteudo ja desbloqueado e ja anunciado ao jogador.
var unlocked: Array[String] = []
var achievements: Array[String] = []
var tutorial_done: bool = false
var last_character_id: String = ""
var last_map_id: String = ""
## Melhorias permanentes compradas: id -> nivel.
var meta_levels: Dictionary = {}
var settings: GameSettings = GameSettings.new()


func to_dict() -> Dictionary:
	return {
		"player_name": player_name, "gold": gold, "total_kills": total_kills,
		"total_runs": total_runs, "total_play_time": total_play_time,
		"bosses_killed": bosses_killed, "max_level": max_level,
		"best_time_by_map": best_time_by_map, "best_ranked_time": best_ranked_time,
		"best_ranked_score": best_ranked_score, "completed_maps": completed_maps,
		"unlocked": unlocked, "achievements": achievements, "tutorial_done": tutorial_done,
		"last_character_id": last_character_id, "last_map_id": last_map_id, "meta_levels": meta_levels,
		"settings": settings.to_dict(),
	}


static func from_dict(d: Dictionary) -> ProfileData:
	var p := ProfileData.new()
	p.player_name = str(d.get("player_name", p.player_name))
	p.gold = int(d.get("gold", 0))
	p.total_kills = int(d.get("total_kills", 0))
	p.total_runs = int(d.get("total_runs", 0))
	p.total_play_time = float(d.get("total_play_time", 0.0))
	p.bosses_killed = int(d.get("bosses_killed", 0))
	p.max_level = int(d.get("max_level", 0))
	p.best_time_by_map = _dict(d, "best_time_by_map")
	p.best_ranked_time = _dict(d, "best_ranked_time")
	p.best_ranked_score = _dict(d, "best_ranked_score")
	p.completed_maps = _strings(d, "completed_maps")
	p.unlocked = _strings(d, "unlocked")
	p.achievements = _strings(d, "achievements")
	p.tutorial_done = bool(d.get("tutorial_done", false))
	p.last_character_id = str(d.get("last_character_id", ""))
	p.last_map_id = str(d.get("last_map_id", ""))
	p.meta_levels = _dict(d, "meta_levels")
	var s: Variant = d.get("settings", {})
	p.settings = GameSettings.from_dict(s if s is Dictionary else {})
	return p


static func _dict(d: Dictionary, key: String) -> Dictionary:
	var v: Variant = d.get(key, {})
	return (v as Dictionary).duplicate() if v is Dictionary else {}


static func _strings(d: Dictionary, key: String) -> Array[String]:
	var out: Array[String] = []
	var v: Variant = d.get(key, [])
	if v is Array:
		for item: Variant in v:
			out.append(str(item))
	return out
