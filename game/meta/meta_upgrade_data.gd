class_name MetaUpgradeData
extends Resource
## Melhoria PERMANENTE comprada com ouro (data/meta_upgrades/*.tres).
## Cada nivel soma `value_per_level` no stat do jogador no inicio da partida.
## Preco do nivel N (comecando em 0) = base_cost * cost_growth^N.

@export var id: StringName = &"meta"
@export var title: String = "Melhoria"
@export_multiline var description: String = ""
## Nome do stat em PlayerStats (max_health, damage_mult, move_speed...).
@export var stat: StringName = &""
@export var value_per_level: float = 1.0
@export var max_level: int = 5
@export var base_cost: int = 50
@export var cost_growth: float = 1.6
@export var color: Color = Color.WHITE
@export var sort_order: int = 0


func cost_for_level(current_level: int) -> int:
	return roundi(base_cost * pow(cost_growth, current_level))


## Texto do efeito no nivel informado (ex.: "+20 de vida").
func effect_text(level: int) -> String:
	var text := description.replace("{v}", _fmt(value_per_level * level))
	return text.replace("{p}", str(roundi(value_per_level * level * 100.0)))


func _fmt(v: float) -> String:
	return str(roundi(v)) if is_equal_approx(v, roundf(v)) else "%.2f" % v
