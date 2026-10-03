class_name GameConfig
extends Resource
## Parametros centrais do jogo (data/config/game_config.tres).
## Nada de "1800" ou multiplicadores espalhados pelos scripts: tudo vem daqui.
## Acesso em qualquer script: Config.game.<campo>

@export_group("Debug")
## Liga as ferramentas de debug (painel DBG na partida, desbloquear tudo etc.).
@export var debug_mode: bool = true
## Se true, o debug tambem aparece na build web/release (util enquanto o jogo esta em teste).
@export var debug_tools_in_release: bool = true
## Se true, a partida normal dura `debug_match_duration` (para testar o fim rapido).
@export var use_debug_match_duration: bool = false
@export var debug_match_duration: float = 60.0

@export_group("Partida")
## Duracao do modo normal em segundos (30 min).
@export var normal_match_duration: float = 1800.0
## Limite de zumbis vivos ao mesmo tempo (performance no celular).
@export var max_active_enemies: int = 350
@export var enemy_spawn_multiplier: float = 1.0
@export var enemy_health_multiplier: float = 1.0
@export var enemy_damage_multiplier: float = 1.0
@export var player_damage_multiplier: float = 1.0
@export var xp_multiplier: float = 1.0

@export_group("Recompensas (ouro)")
@export var gold_per_minute: int = 10
@export var gold_per_100_kills: int = 5
@export var victory_gold_bonus: int = 150

@export_group("Ranqueado (pontuacao)")
@export var score_per_second: int = 10
@export var score_per_kill: int = 1
@export var score_per_level: int = 50
@export var score_per_boss: int = 500


## Duracao efetiva do modo normal (respeita o modo de teste rapido).
func match_duration() -> float:
	return debug_match_duration if use_debug_match_duration else normal_match_duration


func debug_tools_enabled() -> bool:
	return debug_mode and (OS.is_debug_build() or debug_tools_in_release)
