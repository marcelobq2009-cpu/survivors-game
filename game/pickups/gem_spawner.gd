class_name GemSpawner
extends Node2D
## Cria uma gema de XP onde cada inimigo morre (escuta Events.enemy_killed).

const GEM_SCENE: PackedScene = preload("res://game/pickups/xp_gem.tscn")


func _ready() -> void:
	Events.enemy_killed.connect(_on_enemy_killed)


func _on_enemy_killed(pos: Vector2, xp_value: int, _color: Color) -> void:
	# Adiado para nao mexer na arvore no meio do loop de fisica.
	_spawn.call_deferred(pos, xp_value)


func _spawn(pos: Vector2, xp_value: int) -> void:
	var gem := Pool.acquire(GEM_SCENE, self) as XpGem
	gem.setup(pos, xp_value)
