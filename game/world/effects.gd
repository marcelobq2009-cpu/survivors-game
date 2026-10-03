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
	p.amount = 10
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

func _on_explosion(pos: Vector2, radius: float) -> void:
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
