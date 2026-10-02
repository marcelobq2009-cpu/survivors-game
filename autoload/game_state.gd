extends Node
## Estado da partida atual (autoload "GameState").
## Guarda numeros que varios sistemas precisam ler (tempo, abates, nivel, XP,
## posicao do jogador) sem precisarem de referencia uns aos outros.

const XP_CURVE: XpCurve = preload("res://data/player/xp_curve.tres")

var is_running: bool = false
var elapsed: float = 0.0
var kills: int = 0
var progression: Progression = Progression.new(XP_CURVE)

## Atualizados pelo jogador a cada frame; lidos por inimigos, gemas e spawner.
var player_position: Vector2 = Vector2.ZERO
var player_radius: float = 18.0
var pickup_radius: float = 100.0

## Quantas vezes cada upgrade foi escolhido (id -> vezes).
var upgrade_counts: Dictionary[StringName, int] = {}
## Ids das armas que o jogador tem.
var owned_weapons: Array[StringName] = []


func _ready() -> void:
	Events.xp_collected.connect(add_xp)
	Events.enemy_killed.connect(_on_enemy_killed)


func reset() -> void:
	is_running = false
	elapsed = 0.0
	kills = 0
	progression = Progression.new(XP_CURVE)
	player_position = Vector2.ZERO
	upgrade_counts.clear()
	owned_weapons.clear()


var level: int:
	get:
		return progression.level


func add_xp(amount: int) -> void:
	if not is_running:
		return
	var gained := progression.add_xp(amount)
	Events.xp_changed.emit(progression.xp, progression.xp_needed(), progression.level)
	for i: int in gained:
		Events.level_up.emit(progression.level - gained + i + 1)


func register_pick(upgrade: UpgradeData) -> void:
	upgrade_counts[upgrade.id] = upgrade_counts.get(upgrade.id, 0) + 1


func _on_enemy_killed(_pos: Vector2, _xp: int, _color: Color) -> void:
	if is_running:
		kills += 1
