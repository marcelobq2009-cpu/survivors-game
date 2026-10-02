class_name AuraWeapon
extends Weapon
## Area ao redor do jogador que causa dano periodico em todos dentro dela.

var _targets: Array[Node2D] = []

@onready var sprite: Sprite2D = $Sprite


func setup(p_data: WeaponData, p_stats: PlayerStats) -> void:
	super(p_data, p_stats)
	sprite.texture = data.texture
	sprite.modulate = data.color


func _process(_delta: float) -> void:
	# Atualiza o tamanho visual (a area pode mudar com upgrades).
	var tex_size := sprite.texture.get_size().x if sprite.texture else 64.0
	sprite.scale = Vector2.ONE * (final_area() * 2.0 / tex_size)


func attack() -> void:
	if enemies == null:
		return
	var r := final_area()
	enemies.grid.query_radius(global_position, r + EnemyManager.MAX_ENEMY_RADIUS, _targets)
	var dmg := final_damage()
	for n: Node2D in _targets:
		var e := n as Enemy
		if e.alive and e.global_position.distance_to(global_position) <= r + e.data.radius:
			e.take_damage(dmg)
