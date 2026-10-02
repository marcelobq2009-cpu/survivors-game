class_name Weapon
extends Node2D
## Classe base de arma automatica. Fica como filha do jogador.
## Copia os stats do WeaponData (que nao deve ser alterado) para variaveis
## proprias, que os upgrades modificam. Subclasses implementam attack().

var data: WeaponData
var player_stats: PlayerStats
var enemies: EnemyManager

# Stats atuais (comecam iguais ao WeaponData).
var damage: float
var cooldown: float
var area: float
var projectile_speed: float
var projectile_count: int
var pierce: int
var lifetime: float
var target_range: float

var _cooldown_left: float = 0.0


func setup(p_data: WeaponData, p_stats: PlayerStats) -> void:
	data = p_data
	player_stats = p_stats
	damage = data.damage
	cooldown = data.cooldown
	area = data.area
	projectile_speed = data.projectile_speed
	projectile_count = data.projectile_count
	pierce = data.pierce
	lifetime = data.lifetime
	target_range = data.target_range
	_cooldown_left = 0.2


func _ready() -> void:
	enemies = EnemyManager.find(get_tree())


func _physics_process(delta: float) -> void:
	_cooldown_left -= delta
	if _cooldown_left <= 0.0:
		_cooldown_left = maxf(0.05, cooldown * player_stats.cooldown_mult)
		attack()


## Implementado por cada tipo de arma.
func attack() -> void:
	pass


func apply_upgrade(stat: StringName, value: float, is_multiplier: bool) -> bool:
	return StatUtils.apply(self, stat, value, is_multiplier)


func final_damage() -> float:
	return damage * player_stats.damage_mult


func final_area() -> float:
	return area * player_stats.area_mult
