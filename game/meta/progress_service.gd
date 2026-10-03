class_name ProgressService
extends RefCounted
## Regras de progressao permanente (logica pura, testavel):
## recompensas, pontuacao, estatisticas, desbloqueios e conquistas.


static func is_unlocked(content: ContentData, profile: ProfileData) -> bool:
	if content.coming_soon:
		return false
	if content.unlock_requirements.is_empty() or profile.unlocked.has(String(content.id)):
		return true
	return requirements_met(content, profile)


static func requirements_met(content: ContentData, profile: ProfileData) -> bool:
	for r: UnlockRequirement in content.unlock_requirements:
		if not r.is_met(profile):
			return false
	return true


## Ouro ganho ao fim da partida (alem do ouro coletado no mapa).
static func compute_gold_reward(result: RunResult, config: GameConfig) -> int:
	var gold := floori(result.time / 60.0) * config.gold_per_minute
	gold += floori(result.kills / 100.0) * config.gold_per_100_kills
	if result.victory:
		gold += config.victory_gold_bonus
	return gold + result.gold_collected


static func compute_score(result: RunResult, config: GameConfig) -> int:
	return (floori(result.time) * config.score_per_second
			+ result.kills * config.score_per_kill
			+ result.level * config.score_per_level
			+ result.bosses_killed * config.score_per_boss)


## Atualiza o perfil com a partida. Retorna true se bateu recorde no modo.
static func apply_run(profile: ProfileData, result: RunResult) -> bool:
	profile.total_runs += 1
	profile.total_kills += result.kills
	profile.total_play_time += result.time
	profile.bosses_killed += result.bosses_killed
	profile.max_level = maxi(profile.max_level, result.level)
	profile.gold += result.gold_reward
	var record := false
	if result.is_ranked():
		var best_score: int = int(profile.best_ranked_score.get(result.map_id, 0))
		if result.score > best_score:
			profile.best_ranked_score[result.map_id] = result.score
			record = true
		if result.time > float(profile.best_ranked_time.get(result.map_id, 0.0)):
			profile.best_ranked_time[result.map_id] = result.time
	else:
		if result.time > float(profile.best_time_by_map.get(result.map_id, 0.0)):
			profile.best_time_by_map[result.map_id] = result.time
			record = true
		if result.victory and not profile.completed_maps.has(result.map_id):
			profile.completed_maps.append(result.map_id)
	return record


## Conquistas novas (ja marca no perfil e da o ouro de recompensa).
static func check_achievements(profile: ProfileData,
		achievements: Array[AchievementData]) -> Array[AchievementData]:
	var new_ones: Array[AchievementData] = []
	for a: AchievementData in achievements:
		var key := String(a.id)
		if profile.achievements.has(key) or not requirements_met(a, profile):
			continue
		profile.achievements.append(key)
		profile.gold += a.reward_gold
		new_ones.append(a)
	return new_ones


## Conteudo que acabou de ser desbloqueado (ja marca no perfil).
static func check_unlocks(profile: ProfileData, contents: Array[ContentData]) -> Array[ContentData]:
	var new_ones: Array[ContentData] = []
	for c: ContentData in contents:
		var key := String(c.id)
		if c.coming_soon or c.unlock_requirements.is_empty() or profile.unlocked.has(key):
			continue
		if requirements_met(c, profile):
			profile.unlocked.append(key)
			new_ones.append(c)
	return new_ones


## Fecha a partida: recompensas, estatisticas, conquistas e desbloqueios.
static func finalize_run(profile: ProfileData, result: RunResult, config: GameConfig,
		achievements: Array[AchievementData], unlockables: Array[ContentData]) -> void:
	result.gold_reward = compute_gold_reward(result, config)
	result.score = compute_score(result, config)
	result.new_record = apply_run(profile, result)
	result.new_achievements = check_achievements(profile, achievements)
	result.new_unlocks = check_unlocks(profile, unlockables)
	# Uma conquista pode liberar conteudo e vice-versa: segunda passada.
	result.new_achievements.append_array(check_achievements(profile, achievements))
	result.new_unlocks.append_array(check_unlocks(profile, unlockables))
