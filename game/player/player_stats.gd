class_name PlayerStats
extends RefCounted
## Stats atuais do jogador (base do PlayerData + upgrades).
## As armas leem os multiplicadores daqui.

var max_health: float = 100.0
var move_speed: float = 200.0
var pickup_radius: float = 100.0
var damage_mult: float = 1.0
var area_mult: float = 1.0
var cooldown_mult: float = 1.0


static func from_data(data: PlayerData) -> PlayerStats:
	var s := PlayerStats.new()
	s.max_health = data.max_health
	s.move_speed = data.move_speed
	s.pickup_radius = data.pickup_radius
	return s


## Soma (ou multiplica) `value` no stat chamado `stat`. Retorna false se nao existe.
func apply(stat: StringName, value: float, is_multiplier: bool) -> bool:
	return StatUtils.apply(self, stat, value, is_multiplier)
