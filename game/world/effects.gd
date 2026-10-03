class_name Effects
extends Node3D
## Efeitos visuais da partida: numeros de dano, particulas de morte,
## explosoes, golpe de facao e anel de level-up.
## Cada tipo tem um "pool" proprio (reaproveita nos) e um limite, para nao
## pesar no celular.

const GROUP := &"effects"
const MAX_NUMBERS := 28
const MAX_BURSTS := 18
const MAX_BLASTS := 8
const NUMBER_TIME := 0.6

var show_damage_numbers: bool = true

var _numbers: Array[Label3D] = []
var _bursts: Array[CPUParticles3D] = []
var _blasts: Array[MeshInstance3D] = []
var _slashes: Array[MeshInstance3D] = []
var _number_settings_font_size: int = 40


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	Events.damage_dealt.connect(_on_damage)
	Events.enemy_killed.connect(_on_killed)
	Events.explosion.connect(_on_explosion)
	Events.explosion_warning.connect(_on_explosion_warning)
	Events.charge_warning.connect(_on_charge_warning)
	Events.level_up.connect(func(_l: int) -> void: ring(GameState.player_position, Color(0.4, 0.9, 1.0)))


static func find(tree: SceneTree) -> Effects:
	return tree.get_first_node_in_group(GROUP) as Effects


# --- Numeros de dano ----------------------------------------------------------

func _on_damage(pos: Vector2, amount: float, crit: bool) -> void:
	if not show_damage_numbers:
		return
	var label := _take(_numbers, MAX_NUMBERS, _new_number) as Label3D
	if label == null:
		return
	label.text = str(roundi(amount))
	label.modulate = Color(1.0, 0.85, 0.2) if crit else Color.WHITE
	label.font_size = 56 if crit else 40
	label.position = GroundPlane.to_3d(pos + Vector2(randf_range(-0.3, 0.3), 0), 2.2)
	var tw := _tween(label).set_parallel()
	tw.tween_property(label, "position:y", 3.4, NUMBER_TIME)
	tw.tween_property(label, "modulate:a", 0.0, NUMBER_TIME * 0.5).set_delay(NUMBER_TIME * 0.5)
	tw.chain().tween_callback(label.hide)


func _new_number() -> Node3D:
	var l := Label3D.new()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0009
	l.outline_size = 10
	l.outline_modulate = Color.BLACK
	l.render_priority = 10
	return l


# --- Morte (particulas) -------------------------------------------------------

func _on_killed(a: EnemyAgent) -> void:
	var p := _take(_bursts, MAX_BURSTS, _new_burst) as CPUParticles3D
	if p == null:
		return
	p.position = GroundPlane.to_3d(a.pos, 1.0)
	p.color = a.data.skin_color.lerp(Color(0.25, 0.4, 0.15), 0.5)
	p.scale = Vector3.ONE * (1.6 if a.data.is_boss else 1.0)
	p.restart()
	get_tree().create_timer(p.lifetime + 0.1, false).timeout.connect(p.hide)


func _new_burst() -> Node3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = 5 if Save.profile.settings.reduced_particles else 10
	p.lifetime = 0.5
	p.explosiveness = 1.0
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 0.12, 0.12)
	box.material = PlaceholderMeshes.vertex_color_material()
	p.mesh = box
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	p.gravity = Vector3(0, -14, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	return p


# --- Explosoes ----------------------------------------------------------------

func _on_explosion(pos: Vector2, radius: float, _sound: StringName) -> void:
	var m := _take(_blasts, MAX_BLASTS, _new_blast) as MeshInstance3D
	if m == null:
		return
	m.position = GroundPlane.to_3d(pos, 0.3)
	m.scale = Vector3.ONE * 0.2
	var mat := m.material_override as StandardMaterial3D
	mat.albedo_color = Color(1.0, 0.55, 0.15, 0.85)
	var tw := _tween(m).set_parallel()
	tw.tween_property(m, "scale", Vector3(radius, radius * 0.6, radius), 0.18)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.35).set_delay(0.08)
	tw.chain().tween_callback(m.hide)


func _new_blast() -> Node3D:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 2.0
	s.radial_segments = 16
	s.rings = 8
	m.mesh = s
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


# --- Chamas (molotov) ------------------------------------------------------------

func fire_patch(pos: Vector2, radius: float, duration: float) -> void:
	var root := Node3D.new()
	root.position = GroundPlane.to_3d(pos, 0.1)
	add_child(root)
	var disk := _warning_mesh(CylinderMesh.new())
	disk.reparent(root, false)
	disk.position = Vector3.ZERO
	(disk.mesh as CylinderMesh).top_radius = radius
	(disk.mesh as CylinderMesh).bottom_radius = radius
	(disk.mesh as CylinderMesh).height = 0.04
	var mat := disk.material_override as StandardMaterial3D
	mat.albedo_color = Color(1.0, 0.45, 0.1, 0.45)
	mat.no_depth_test = false
	var flames := CPUParticles3D.new()
	flames.amount = 8 if Save.profile.settings.reduced_particles else 22
	flames.lifetime = 0.7
	flames.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	flames.emission_sphere_radius = radius * 0.8
	flames.direction = Vector3.UP
	flames.spread = 15.0
	flames.gravity = Vector3(0, 2.5, 0)
	flames.initial_velocity_min = 0.5
	flames.initial_velocity_max = 1.5
	var box := BoxMesh.new()
	box.size = Vector3(0.25, 0.25, 0.25)
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.vertex_color_use_as_albedo = true
	box.material = fm
	flames.mesh = box
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.3))
	grad.set_color(1, Color(0.9, 0.2, 0.05, 0.0))
	flames.color_ramp = grad
	root.add_child(flames)
	var tw := root.create_tween()
	for i: int in int(duration * 4.0):
		tw.tween_property(mat, "albedo_color:a", 0.6 if i % 2 == 0 else 0.35, 0.25)
	tw.tween_callback(func() -> void: flames.emitting = false)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.4)
	tw.tween_callback(root.queue_free)


# --- Eventos (suprimentos, area contaminada) -------------------------------------

func supply_beacon(pos: Vector2, fall_time: float) -> void:
	var root := Node3D.new()
	root.position = GroundPlane.to_3d(pos)
	add_child(root)
	# Feixe de luz verde (onde a caixa vai cair).
	var beam := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.6
	cyl.bottom_radius = 0.6
	cyl.height = 30.0
	beam.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.5, 1.0, 0.4, 0.35)
	beam.material_override = mat
	beam.position.y = 15.0
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(beam)
	# Caixa caindo.
	var crate := MeshInstance3D.new()
	crate.mesh = PlaceholderMeshes.chest()
	crate.scale = Vector3.ONE * 1.6
	crate.position.y = 18.0
	root.add_child(crate)
	var tw := root.create_tween()
	tw.tween_property(crate, "position:y", 0.0, fall_time).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		Events.camera_shake_requested.emit(1.5)
		crate.queue_free())
	tw.tween_interval(6.0)
	tw.tween_property(mat, "albedo_color:a", 0.0, 1.0)
	tw.tween_callback(root.queue_free)


func toxic_zone(pos: Vector2, radius: float, warning: float, duration: float) -> void:
	var m := _warning_mesh(CylinderMesh.new())
	(m.mesh as CylinderMesh).top_radius = radius
	(m.mesh as CylinderMesh).bottom_radius = radius
	(m.mesh as CylinderMesh).height = 0.05
	m.position = GroundPlane.to_3d(pos, 0.1)
	var mat := m.material_override as StandardMaterial3D
	mat.albedo_color = Color(0.6, 1.0, 0.2, 0.2)
	var tw := m.create_tween()
	# Aviso: pisca amarelo-esverdeado.
	for i: int in 3:
		tw.tween_property(mat, "albedo_color:a", 0.5, warning / 6.0)
		tw.tween_property(mat, "albedo_color:a", 0.15, warning / 6.0)
	# Ativo: nevoa verde forte.
	tw.tween_property(mat, "albedo_color", Color(0.35, 0.9, 0.15, 0.32), 0.2)
	tw.tween_interval(maxf(0.0, duration - warning - 0.6))
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.4)
	tw.tween_callback(m.queue_free)
	if not Save.profile.settings.reduced_particles:
		var fog := CPUParticles3D.new()
		fog.amount = 8
		fog.lifetime = 1.2
		fog.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		fog.emission_sphere_radius = radius * 0.8
		fog.direction = Vector3.UP
		fog.gravity = Vector3(0, 0.25, 0)
		fog.initial_velocity_max = 0.2
		var sphere := SphereMesh.new()
		sphere.radius = 0.22
		sphere.height = 0.44
		var fm := StandardMaterial3D.new()
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fm.albedo_color = Color(0.5, 0.95, 0.2, 0.14)
		sphere.material = fm
		fog.mesh = sphere
		m.add_child(fog)


# --- Avisos de perigo (justica: o jogador ve antes de levar o golpe) ------------

func _on_explosion_warning(pos: Vector2, radius: float, duration: float) -> void:
	var m := _warning_mesh(CylinderMesh.new())
	(m.mesh as CylinderMesh).top_radius = 1.0
	(m.mesh as CylinderMesh).bottom_radius = 1.0
	(m.mesh as CylinderMesh).height = 0.04
	m.position = GroundPlane.to_3d(pos, 0.12)
	m.scale = Vector3(radius, 1, radius)
	_pulse_and_free(m, duration)


func _on_charge_warning(pos: Vector2, dir: Vector2, length: float, duration: float) -> void:
	var box := BoxMesh.new()
	box.size = Vector3(2.2, 0.04, length)
	var m := _warning_mesh(box)
	m.position = GroundPlane.to_3d(pos + dir * length * 0.5, 0.12)
	m.rotation.y = GroundPlane.heading(dir)
	_pulse_and_free(m, duration + 0.2)


func _warning_mesh(mesh: Mesh) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.15, 0.1, 0.35)
	mat.no_depth_test = true
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	return m


## Pisca cada vez mais rapido ate o golpe, depois some.
func _pulse_and_free(m: MeshInstance3D, duration: float) -> void:
	var mat := m.material_override as StandardMaterial3D
	var tw := m.create_tween()
	var pulses := 4
	for i: int in pulses:
		var t := duration / pulses / 2.0
		tw.tween_property(mat, "albedo_color:a", 0.6, t)
		tw.tween_property(mat, "albedo_color:a", 0.25, t)
	tw.tween_callback(m.queue_free)


# --- Golpe corpo a corpo e anel -------------------------------------------------

func slash(pos: Vector2, dir: Vector2, reach: float, color: Color) -> void:
	var m := _take(_slashes, 6, _new_slash) as MeshInstance3D
	if m == null:
		return
	m.position = GroundPlane.to_3d(pos, 0.9)
	m.rotation = Vector3(0, GroundPlane.heading(dir), 0)
	m.scale = Vector3(reach, 1, reach)
	var mat := m.material_override as StandardMaterial3D
	mat.albedo_color = Color(color, 0.8)
	var tw := _tween(m)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.18)
	tw.tween_callback(m.hide)


func ring(pos: Vector2, color: Color) -> void:
	var m := _take(_slashes, 6, _new_slash) as MeshInstance3D
	if m == null:
		return
	m.position = GroundPlane.to_3d(pos, 0.2)
	m.rotation = Vector3.ZERO
	m.scale = Vector3(0.5, 1, 0.5)
	var mat := m.material_override as StandardMaterial3D
	mat.albedo_color = Color(color, 0.7)
	var tw := _tween(m).set_parallel()
	tw.tween_property(m, "scale", Vector3(4, 1, 4), 0.4)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.4)
	tw.chain().tween_callback(m.hide)


func _new_slash() -> Node3D:
	var m := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 1.0
	c.bottom_radius = 1.0
	c.height = 0.05
	c.radial_segments = 24
	m.mesh = c
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


## Cria uma animacao nova no no, cancelando a anterior (nos sao reaproveitados).
func _tween(node: Node) -> Tween:
	if node.has_meta(&"tw"):
		var old: Tween = node.get_meta(&"tw")
		if old and old.is_valid():
			old.kill()
	var tw := node.create_tween()
	node.set_meta(&"tw", tw)
	return tw


## Pega um no escondido do pool (ou cria um novo se nao passou do limite).
func _take(pool: Array, limit: int, factory: Callable) -> Node3D:
	for n: Node3D in pool:
		if not n.visible:
			n.show()
			return n
	if pool.size() >= limit:
		return null
	var node: Node3D = factory.call()
	add_child(node)
	pool.append(node)
	return node
