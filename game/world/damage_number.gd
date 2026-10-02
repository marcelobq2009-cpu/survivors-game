class_name DamageNumber
extends Label
## Numero de dano que sobe e some (vem do Pool).

const LIFETIME := 0.55
const RISE := 50.0

var _tween: Tween


func show_amount(pos: Vector2, amount: float) -> void:
	text = str(roundi(amount))
	position = pos - size * 0.5 + Vector2(randf_range(-10, 10), -20)
	modulate = Color.WHITE
	scale = Vector2.ONE
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "position:y", position.y - RISE, LIFETIME)
	_tween.tween_property(self, "modulate:a", 0.0, LIFETIME).set_delay(LIFETIME * 0.4)
	_tween.chain().tween_callback(Pool.release.bind(self))
