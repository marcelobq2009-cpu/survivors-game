class_name Progression
extends RefCounted
## Logica pura de XP e nivel (sem nos, facil de testar).

var curve: XpCurve
var level: int = 1
var xp: int = 0


func _init(p_curve: XpCurve) -> void:
	curve = p_curve


func xp_needed() -> int:
	return curve.xp_to_next(level)


## Soma XP e retorna quantos niveis foram ganhos (pode ser mais de 1).
func add_xp(amount: int) -> int:
	xp += maxi(0, amount)
	var gained := 0
	var needed := xp_needed()
	while xp >= needed:
		xp -= needed
		level += 1
		gained += 1
		needed = xp_needed()
	return gained
