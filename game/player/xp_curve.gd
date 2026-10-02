class_name XpCurve
extends Resource
## Quanto XP e preciso para passar de cada nivel (data/player/xp_curve.tres).
## Formula: base + growth * (nivel - 1) ^ exponent

@export var base: float = 5.0
@export var growth: float = 6.0
@export var exponent: float = 1.3


## XP necessario para ir do nivel `level` para o proximo.
func xp_to_next(level: int) -> int:
	return maxi(1, roundi(base + growth * pow(maxf(0.0, level - 1), exponent)))
