extends Node
## Estado da partida atual (autoload "GameState").
## Guarda numeros que varios sistemas precisam ler (tempo, abates, nivel, XP,
## ouro, posicao do jogador) sem precisarem de referencia uns aos outros.

const XP_CURVE: XpCurve = preload("res://data/player/xp_curve.tres")

## Escolhas feitas no menu (modo, personagem, mapa). Preenchido antes da partida.
var setup: RunSetup = RunSetup.new()

var is_running: bool = false
var elapsed: float = 0.0
var kills: int = 0
var gold: int = 0
var xp_total: int = 0
var bosses_killed: int = 0
var progression: Progression = Progression.new(XP_CURVE)
## weapon_id -> dano causado nesta partida.
var damage_by_weapon: Dictionary = {}
var damage_total: float = 0.0

## Atualizados pelo jogador a cada frame; lidos por zumbis, gemas e spawner.
var player_position: Vector2 = Vector2.ZERO
var player_radius: float = 0.4
var pickup_radius: float = 2.5
var xp_mult: float = 1.0
var gold_mult: float = 1.0

## Quantas vezes cada upgrade foi escolhido (id -> vezes).
var upgrade_counts: Dictionary[StringName, int] = {}
## Ids das armas que o jogador tem e o nivel de cada uma.
var owned_weapons: Array[StringName] = []
var weapon_levels: Dictionary[StringName, int] = {}


func _ready() -> void:
	Events.xp_collected.connect(add_xp)
	Events.enemy_killed.connect(_on_enemy_killed)
	Events.gold_collected.connect(_on_gold)
	Events.boss_killed.connect(func(_d: EnemyData) -> void: bosses_killed += 1)


func reset() -> void:
	is_running = false
	elapsed = 0.0
	kills = 0
	gold = 0
	xp_total = 0
	bosses_killed = 0
	progression = Progression.new(XP_CURVE)
	damage_by_weapon.clear()
	damage_total = 0.0
	player_position = Vector2.ZERO
	xp_mult = 1.0
	gold_mult = 1.0
	upgrade_counts.clear()
	owned_weapons.clear()
	weapon_levels.clear()
	_pause_owners.clear()


var level: int:
	get:
		return progression.level


func add_xp(amount: int) -> void:
	if not is_running:
		return
	var final_amount := maxi(1, roundi(amount * xp_mult * Config.game.xp_multiplier))
	xp_total += final_amount
	var gained := progression.add_xp(final_amount)
	Events.xp_changed.emit(progression.xp, progression.xp_needed(), progression.level)
	for i: int in gained:
		Events.level_up.emit(progression.level - gained + i + 1)


## --- Pausa compartilhada ---
## Varias telas podem pausar ao mesmo tempo (level-up, tutorial, pausa,
## debug). O jogo so volta quando TODAS liberarem.
var _pause_owners: Array[Object] = []


func request_pause(owner: Object) -> void:
	if not _pause_owners.has(owner):
		_pause_owners.append(owner)
	get_tree().paused = true


func release_pause(owner: Object) -> void:
	_pause_owners.erase(owner)
	if _pause_owners.is_empty() and is_running:
		get_tree().paused = false


func clear_pauses() -> void:
	_pause_owners.clear()


func register_pick(upgrade: UpgradeData) -> void:
	upgrade_counts[upgrade.id] = upgrade_counts.get(upgrade.id, 0) + 1


func add_damage(weapon_id: StringName, amount: float) -> void:
	damage_total += amount
	damage_by_weapon[String(weapon_id)] = float(damage_by_weapon.get(String(weapon_id), 0.0)) + amount


func weapon_level(id: StringName) -> int:
	return weapon_levels.get(id, 0)


## Monta o resumo da partida (tela de resultado / save / ranking).
func build_result(victory: bool) -> RunResult:
	var r := RunResult.new()
	r.mode = setup.mode
	r.map_id = String(setup.map.id) if setup.map else ""
	r.character_id = String(setup.character.id) if setup.character else ""
	r.victory = victory
	r.time = elapsed
	r.kills = kills
	r.level = level
	r.xp_total = xp_total
	r.gold_collected = gold
	r.damage_total = damage_total
	r.damage_by_weapon = damage_by_weapon.duplicate()
	r.bosses_killed = bosses_killed
	return r


func _on_enemy_killed(_agent: EnemyAgent) -> void:
	if is_running:
		kills += 1


func _on_gold(amount: int) -> void:
	if is_running:
		gold += amount
