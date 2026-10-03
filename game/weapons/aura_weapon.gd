class_name AuraWeapon
extends Weapon
## Area ao redor do jogador que causa dano periodico em todos dentro dela.

var _targets: Array[EnemyAgent] = []
var _disk: MeshInstance3D


func _on_setup() -> void:
	_disk = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.05
	cyl.radial_segments = 32
	_disk.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(data.color, 0.28)
	_disk.material_override = mat
	_disk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disk.position.y = 0.08
	add_child(_disk)
	Audio.play(&"weapon_gas_start")
	Audio.start_loop(&"weapon_gas", &"weapon_gas_loop")


func _process(_delta: float) -> void:
	if _disk:
		var r := final_area()
		_disk.scale = Vector3(r, 1.0, r)
		_disk.rotation.y += 0.02


func attack() -> void:
	if enemies == null:
		return
	var from := origin()
	var r := final_area()
	enemies.grid.query_radius(from, r + EnemyManager.MAX_ENEMY_RADIUS, _targets)
	for e: EnemyAgent in _targets:
		if e.alive and e.pos.distance_to(from) <= r + e.radius:
			hit(e, (e.pos - from).normalized() * 0.3)


func _exit_tree() -> void:
	Audio.stop_loop(&"weapon_gas", 0.4)
