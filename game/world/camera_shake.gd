class_name CameraShake
extends Camera2D
## Camera que treme ao receber Events.camera_shake_requested.

const DECAY := 30.0  # Pixels de tremor perdidos por segundo.
const MAX_SHAKE := 16.0

var _shake: float = 0.0


func _ready() -> void:
	Events.camera_shake_requested.connect(_on_shake)


func _process(delta: float) -> void:
	if _shake <= 0.0:
		offset = Vector2.ZERO
		return
	_shake = maxf(0.0, _shake - DECAY * delta)
	offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))


func _on_shake(strength: float) -> void:
	_shake = minf(MAX_SHAKE, _shake + strength)
