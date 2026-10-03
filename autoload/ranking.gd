extends Node
## Servico de ranking (autoload "Ranking").
## As telas so falam com ele; quem responde e o `provider`. Hoje e o
## LocalRankingProvider (mock). Para usar um backend real no futuro, crie um
## provider HTTP que estende RankingProvider e troque em _ready().

signal leaderboard_ready(map_id: String, entries: Array[RankingEntry], player_entry: RankingEntry)

var provider: RankingProvider


func _ready() -> void:
	var local := LocalRankingProvider.new()
	provider = local
	provider.leaderboard_ready.connect(leaderboard_ready.emit)
	Save.profile_changed.connect(_sync_player_bests)
	_sync_player_bests()


func submit(entry: RankingEntry) -> void:
	provider.submit(entry)


func request_leaderboard(map_id: String, limit: int = 50) -> void:
	provider.request_leaderboard(map_id, limit)


## Posicao estimada de uma pontuacao (para a tela de resultado).
func position_for_score(map_id: String, score: int) -> int:
	if provider is LocalRankingProvider:
		return (provider as LocalRankingProvider).position_for_score(map_id, score)
	return 0


## Coloca os recordes salvos do jogador no ranking local.
func _sync_player_bests() -> void:
	if not provider is LocalRankingProvider:
		return
	var p := Save.profile
	for map_id: Variant in p.best_ranked_score:
		var key := str(map_id)
		var e := RankingEntry.make(p.player_name, p.last_character_id, key,
				float(p.best_ranked_time.get(key, 0.0)), int(p.best_ranked_score[key]), true)
		(provider as LocalRankingProvider).set_player_best(e)
