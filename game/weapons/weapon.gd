class_name Weapon
extends Node3D
## Classe base de arma automatica (filha do jogador, entao acompanha ele).
## Copia os stats do WeaponData (que nao deve ser alterado) para variaveis
## proprias, que os upgrades modificam pelo nome. Subclasses implementam attack().

var data: WeaponData
var player_stats: PlayerStats
var enemies: EnemyManager
var projectiles: ProjectileManager

# Stats atuais (comecam iguais ao WeaponData; upgrades mudam pelo nome).
var damage: float
var cooldown: float
var area: float
var projectile_speed: float
var projectile_count: int
var spread_degrees: float
var pierce: int
var lifetime: float
var target_range: float
var knockback: float

var _cooldown_left: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(p_data: WeaponData, p_stats: PlayerStats) -> void:
	data = p_data
	player_stats = p_stats
	damage = data.damage
	cooldown = data.cooldown
	area = data.area
	projectile_speed = data.projectile_speed
	projectile_count = data.projectile_count
	spread_degrees = data.spread_degrees
	pierce = data.pierce
	lifetime = data.lifetime
	target_range = data.target_range
	knockback = data.knockback
	_cooldown_left = 0.3
	_rng.randomize()
	_on_setup()


func _ready() -> void:
	enemies = EnemyManager.find(get_tree())
	projectiles = ProjectileManager.find(get_tree())


func _physics_process(delta: float) -> void:
	if data == null:
		return
	_cooldown_left -= delta
	if _cooldown_left <= 0.0:
		_cooldown_left = maxf(0.05, cooldown * player_stats.cooldown_mult)
		attack()


## Hook para subclasses prepararem visuais depois do setup.
func _on_setup() -> void:
	pass


## Implementado por cada comportamento de arma.
func attack() -> void:
	pass


func apply_upgrade(stat: StringName, value: float, is_multiplier: bool) -> bool:
	return StatUtils.apply(self, stat, value, is_multiplier)


func origin() -> Vector2:
	return GameState.player_position


func final_area() -> float:
	return area * player_stats.area_mult


func final_count() -> int:
	return projectile_count + (player_stats.projectile_bonus if data.uses_projectile_bonus else 0)


## Dano de um golpe (multiplicadores + critico): Vector2(dano, 1 se critico).
func roll_damage() -> Vector2:
	return player_stats.roll_damage(damage, _rng)


## Causa dano num zumbi creditando esta arma.
func hit(agent: EnemyAgent, push_dir: Vector2) -> void:
	var r := roll_damage()
	enemies.damage_agent(agent, r.x, r.y > 0.5, push_dir * knockback, data.id)
