class_name DifficultyDirector
extends RefCounted
## Calcula a dificuldade num instante da partida (logica pura, testavel).
## Combina varias alavancas (nao so vida): ritmo de spawn, dano, velocidade
## (com teto), chance de elite, tamanho das hordas. No ranqueado, depois que a
## timeline acaba, o tempo "conta mais" (overtime_growth_mult): fica mais
## dificil mais rapido, sem limite.

var profile: DifficultyProfile
var timeline_end: float


func _init(p_profile: DifficultyProfile, p_timeline_end: float) -> void:
	profile = p_profile if p_profile else DifficultyProfile.new()
	timeline_end = maxf(1.0, p_timeline_end)


## Minutos "efetivos" de dificuldade no tempo t (segundos).
func effective_minutes(t: float) -> float:
	if t <= timeline_end:
		return t / 60.0
	return timeline_end / 60.0 + (t - timeline_end) / 60.0 * profile.overtime_growth_mult


func health_mult(t: float) -> float:
	return 1.0 + profile.health_growth_per_min * effective_minutes(t)


func damage_mult(t: float) -> float:
	return 1.0 + profile.damage_growth_per_min * effective_minutes(t)


func speed_mult(t: float) -> float:
	return minf(profile.max_speed_mult, 1.0 + profile.speed_growth_per_min * effective_minutes(t))


## Quanto mais frequentes sao os spawns (1 = ritmo da onda).
func spawn_rate_mult(t: float) -> float:
	return minf(profile.max_spawn_rate_mult, 1.0 + profile.spawn_rate_growth_per_min * effective_minutes(t))


func elite_chance(t: float) -> float:
	return clampf(profile.elite_chance_start + profile.elite_chance_per_min * effective_minutes(t),
			0.0, profile.elite_chance_max)


func horde_size(t: float) -> int:
	return roundi(profile.horde_size + profile.horde_size_growth_per_min * effective_minutes(t))


## Indice do chefe que deve existir no tempo t (-1 = nenhum ainda).
func boss_index(t: float) -> int:
	if profile.boss_interval <= 0.0 or profile.bosses.is_empty():
		return -1
	return floori(t / profile.boss_interval) - 1


func boss_health_mult(index: int, t: float) -> float:
	return health_mult(t) * (1.0 + profile.boss_health_growth * index)
