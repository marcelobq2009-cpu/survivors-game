class_name PlayerStats
extends RefCounted
## Stats atuais do jogador (base do CharacterData + upgrades da partida).
## As armas leem os multiplicadores daqui. Upgrades mudam qualquer campo pelo
## nome (UpgradeData.stat), entao novos stats so precisam existir aqui.

var max_health: float = 100.0
var move_speed: float = 4.5
var pickup_radius: float = 2.5
var damage_mult: float = 1.0
var area_mult: float = 1.0
var cooldown_mult: float = 1.0
var armor: float = 0.0
var regen: float = 0.0
var crit_chance: float = 0.05
var crit_damage: float = 1.5
var projectile_bonus: int = 0
var xp_mult: float = 1.0
var gold_mult: float = 1.0


static func from_character(data: CharacterData) -> PlayerStats:
	var s := PlayerStats.new()
	s.max_health = data.max_health
	s.move_speed = data.move_speed
	s.pickup_radius = data.pickup_radius
	s.damage_mult = data.damage_mult
	s.area_mult = data.area_mult
	s.cooldown_mult = data.cooldown_mult
	s.armor = data.armor
	s.regen = data.regen
	s.crit_chance = data.crit_chance
	s.crit_damage = data.crit_damage
	s.projectile_bonus = data.projectile_bonus
	s.xp_mult = data.xp_mult
	s.gold_mult = data.gold_mult
	return s


## Soma (ou multiplica) `value` no stat chamado `stat`. Retorna false se nao existe.
func apply(stat: StringName, value: float, is_multiplier: bool) -> bool:
	return StatUtils.apply(self, stat, value, is_multiplier)


## Dano final de um golpe: multiplicadores globais + sorteio de critico.
## Retorna Vector2(dano, 1 se critico senao 0).
func roll_damage(base: float, rng: RandomNumberGenerator) -> Vector2:
	var dmg := base * damage_mult * Config.game.player_damage_multiplier
	if rng.randf() < crit_chance:
		return Vector2(dmg * crit_damage, 1.0)
	return Vector2(dmg, 0.0)
