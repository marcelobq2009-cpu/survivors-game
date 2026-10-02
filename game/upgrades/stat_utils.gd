class_name StatUtils
extends RefCounted
## Ajuda a aplicar upgrades em qualquer objeto pelo nome do stat.


## Soma (ou multiplica) `value` na propriedade `stat` de `target`.
## Funciona com float e int. Retorna false se a propriedade nao existe.
static func apply(target: Object, stat: StringName, value: float, is_multiplier: bool) -> bool:
	if stat == &"" or not (stat in target):
		push_warning("Stat desconhecido: %s" % stat)
		return false
	var current: Variant = target.get(stat)
	var result: float = float(current) * value if is_multiplier else float(current) + value
	if current is int:
		target.set(stat, roundi(result))
	else:
		target.set(stat, result)
	return true
