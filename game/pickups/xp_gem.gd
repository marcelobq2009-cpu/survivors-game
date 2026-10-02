class_name XpGem
extends Node2D
## Gema de XP (vem do Pool). Fica parada ate o jogador chegar perto
## (pickup_radius); entao e atraida cada vez mais rapido e e coletada.

const COLLECT_DISTANCE := 20.0
const START_SPEED := 150.0
const ACCELERATION := 1400.0

var value: int = 1
var _attracted: bool = false
var _speed: float = 0.0

@onready var sprite: Sprite2D = $Sprite


func setup(pos: Vector2, xp_value: int) -> void:
	global_position = pos
	value = xp_value
	_attracted = false
	_speed = 0.0
	# Gemas mais valiosas ficam maiores e com outra cor.
	var big := xp_value >= 3
	sprite.scale = Vector2.ONE * (0.42 if big else 0.28)
	sprite.modulate = Color(1.0, 0.85, 0.2) if big else Color(0.35, 1.0, 0.55)


func _physics_process(delta: float) -> void:
	var to_player := GameState.player_position - global_position
	var dist := to_player.length()
	if not _attracted:
		if dist > GameState.pickup_radius:
			return
		_attracted = true
		_speed = START_SPEED
	_speed += ACCELERATION * delta
	if dist <= COLLECT_DISTANCE or dist <= _speed * delta:
		Events.xp_collected.emit(value)
		Audio.play(&"pickup", -12.0)
		Pool.release(self)
		return
	global_position += to_player / dist * _speed * delta
