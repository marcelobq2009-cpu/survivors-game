class_name RankingEntry
extends RefCounted
## Uma linha do ranking.

var rank: int = 0
var player_name: String = ""
var character_id: String = ""
var map_id: String = ""
var time: float = 0.0
var score: int = 0
var is_player: bool = false


static func make(p_name: String, p_character: String, p_map: String, p_time: float,
		p_score: int, p_is_player: bool = false) -> RankingEntry:
	var e := RankingEntry.new()
	e.player_name = p_name
	e.character_id = p_character
	e.map_id = p_map
	e.time = p_time
	e.score = p_score
	e.is_player = p_is_player
	return e
