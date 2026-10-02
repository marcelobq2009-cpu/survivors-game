class_name Health
extends RefCounted
## Logica pura de vida: dano, cura, morte e invencibilidade temporaria.

var max_value: float
var current: float
## Segundos invulneravel depois de levar dano (0 = nunca).
var invincibility_time: float
var _invincible_left: float = 0.0


func _init(p_max: float, p_invincibility_time: float = 0.0) -> void:
	max_value = p_max
	current = p_max
	invincibility_time = p_invincibility_time


## Aplica dano e retorna quanto foi realmente aplicado (0 se invulneravel/morto).
func take_damage(amount: float) -> float:
	if amount <= 0.0 or is_dead() or is_invincible():
		return 0.0
	var applied := minf(amount, current)
	current -= applied
	_invincible_left = invincibility_time
	return applied


func heal(amount: float) -> void:
	if is_dead():
		return
	current = minf(max_value, current + maxf(0.0, amount))


## Muda a vida maxima; ganha (ou perde) a mesma diferenca na vida atual.
func set_max(value: float) -> void:
	var diff := value - max_value
	max_value = maxf(1.0, value)
	current = clampf(current + maxf(0.0, diff), 0.0, max_value)


func update(delta: float) -> void:
	_invincible_left = maxf(0.0, _invincible_left - delta)


func is_invincible() -> bool:
	return _invincible_left > 0.0


func is_dead() -> bool:
	return current <= 0.0


func ratio() -> float:
	return current / max_value
