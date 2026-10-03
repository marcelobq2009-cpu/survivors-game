class_name LocalRankingProvider
extends RankingProvider
## Ranking "de mentira" (mock) enquanto nao existe backend: gera jogadores
## ficticios (sempre os mesmos para cada mapa) e mistura com os seus recordes,
## que vem do perfil salvo.

const FAKE_PLAYERS := 60
const NAMES: PackedStringArray = [
	"CariocaDaGema", "ZumbiNaLapa", "SobreviventeRJ", "MengaoSurvivor", "Copa_Rat",
	"TijucaTeam", "BiscoitoGlobo", "MateGelado", "Arpoador99", "Niteroiense",
	"LeblonLost", "SamboZumbi", "PaoDeAcucar", "TremDoSuburbio", "Favelinha_Fe",
	"CristoGuarda", "BondinhoBR", "MaracaNa", "AcaiComBanana", "GaleaoGamer",
]
const CHARACTERS: PackedStringArray = ["survivor", "soldier", "medic"]

var _player_entries: Dictionary = {}  # map_id -> RankingEntry (melhor do jogador)


func set_player_best(entry: RankingEntry) -> void:
	_player_entries[entry.map_id] = entry


func submit(entry: RankingEntry) -> void:
	var current: RankingEntry = _player_entries.get(entry.map_id)
	if current == null or entry.score > current.score:
		_player_entries[entry.map_id] = entry
	score_submitted.emit.call_deferred(entry)


func request_leaderboard(map_id: String, limit: int) -> void:
	var all := _fake_entries(map_id)
	var mine: RankingEntry = _player_entries.get(map_id)
	if mine:
		all.append(mine)
	all.sort_custom(func(a: RankingEntry, b: RankingEntry) -> bool: return a.score > b.score)
	for i: int in all.size():
		all[i].rank = i + 1
	var top: Array[RankingEntry] = []
	for i: int in mini(limit, all.size()):
		top.append(all[i])
	leaderboard_ready.emit.call_deferred(map_id, top, mine)


## Em que posicao uma pontuacao ficaria (1 = primeiro).
func position_for_score(map_id: String, score: int) -> int:
	var pos := 1
	for e: RankingEntry in _fake_entries(map_id):
		if e.score > score:
			pos += 1
	return pos


func _fake_entries(map_id: String) -> Array[RankingEntry]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(map_id)
	var out: Array[RankingEntry] = []
	for i: int in FAKE_PLAYERS:
		# Distribuicao: poucos jogadores muito bons, muitos medianos.
		var minutes := 3.0 + pow(rng.randf(), 2.2) * 85.0
		var time := minutes * 60.0
		var kills := roundi(minutes * rng.randf_range(60.0, 110.0))
		var score := roundi(time * 10.0 + kills + minutes * 25.0)
		var nick := "%s%d" % [NAMES[rng.randi_range(0, NAMES.size() - 1)], rng.randi_range(1, 99)]
		out.append(RankingEntry.make(nick, CHARACTERS[rng.randi_range(0, 2)], map_id, time, score))
	return out
