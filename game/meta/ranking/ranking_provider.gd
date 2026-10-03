class_name RankingProvider
extends RefCounted
## Interface de uma fonte de ranking. Hoje: LocalRankingProvider (dados falsos
## + seus recordes). Futuro: um provider HTTP falando com um backend real,
## sem mudar as telas (elas so falam com o autoload Ranking).
##
## Todas as respostas chegam pelo sinal `leaderboard_ready` (assincrono,
## como seria com internet).

signal leaderboard_ready(map_id: String, entries: Array[RankingEntry], player_entry: RankingEntry)
signal score_submitted(entry: RankingEntry)


## Envia o resultado de uma partida ranqueada.
func submit(_entry: RankingEntry) -> void:
	pass


## Pede o top `limit` do mapa. Responde em leaderboard_ready.
func request_leaderboard(_map_id: String, _limit: int) -> void:
	pass
