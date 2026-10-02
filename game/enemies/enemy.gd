class_name Enemy
extends Node2D
## Um inimigo. Nao tem _process proprio: o EnemyManager move todos num loop
## so (mais rapido com centenas de inimigos). Vem do Pool.

const FLASH_TIME := 0.08
const FLASH_COLOR := Color(2.5, 2.5, 2.5)
const KNOCKBACK_DECAY := 8.0

var data: EnemyData
var health: float = 1.0
var alive: bool = false
var knockback: Vector2 = Vector2.ZERO
# Copias de data.speed/data.radius: lidas centenas de vezes por frame.
var speed: float = 0.0
var radius: float = 0.0
## Posicao no array do EnemyManager (para remover rapido).
var manager_index: int = -1

var _manager: EnemyManager
var _flash_left: float = 0.0

@onready var sprite: Sprite2D = $Sprite


func setup(p_data: EnemyData, pos: Vector2, health_mult: float, manager: EnemyManager) -> void:
	data = p_data
	_manager = manager
	global_position = pos
	health = data.max_health * health_mult
	speed = data.speed
	radius = data.radius
	alive = true
	knockback = Vector2.ZERO
	_flash_left = 0.0
	sprite.texture = data.texture
	sprite.modulate = data.color
	var tex_size := data.texture.get_size().x if data.texture else 64.0
	sprite.scale = Vector2.ONE * (data.radius * 2.0 / tex_size)


## Chamado pelo EnemyManager a cada frame (efeitos visuais).
func tick(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			sprite.modulate = data.color
	knockback = knockback.lerp(Vector2.ZERO, minf(1.0, KNOCKBACK_DECAY * delta))


func take_damage(amount: float, push: Vector2 = Vector2.ZERO) -> void:
	if not alive:
		return
	health -= amount
	knockback += push * (1.0 - data.knockback_resistance)
	_flash_left = FLASH_TIME
	sprite.modulate = FLASH_COLOR
	Events.damage_dealt.emit(global_position, amount)
	if health <= 0.0:
		die()


func die() -> void:
	if not alive:
		return
	alive = false
	Events.enemy_killed.emit(global_position, data.xp_value, data.color)
	Audio.play(&"enemy_die", -6.0)
	_manager.remove(self)
