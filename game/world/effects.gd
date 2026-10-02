class_name Effects
extends Node2D
## Efeitos visuais da partida: numeros de dano e particulas de morte.
## Escuta os Events e usa o Pool. Tem limites para nao pesar no celular.

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://game/world/damage_number.tscn")
const DEATH_BURST_SCENE: PackedScene = preload("res://game/world/death_burst.tscn")
const MAX_DAMAGE_NUMBERS := 40
const MAX_BURSTS := 30

@export var show_damage_numbers: bool = true


func _ready() -> void:
	Events.damage_dealt.connect(_on_damage_dealt)
	Events.enemy_killed.connect(_on_enemy_killed)


func _on_damage_dealt(pos: Vector2, amount: float) -> void:
	if not show_damage_numbers or Pool.active_count(DAMAGE_NUMBER_SCENE) >= MAX_DAMAGE_NUMBERS:
		return
	var n := Pool.acquire(DAMAGE_NUMBER_SCENE, self) as DamageNumber
	n.show_amount(pos, amount)


func _on_enemy_killed(pos: Vector2, _xp: int, color: Color) -> void:
	if Pool.active_count(DEATH_BURST_SCENE) >= MAX_BURSTS:
		return
	var b := Pool.acquire(DEATH_BURST_SCENE, self) as DeathBurst
	b.burst(pos, color)
