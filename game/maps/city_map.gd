class_name CityMap
extends GameMap
## Mapa de cidade gerado por codigo a partir de um CityLayout (arte placeholder).
## Junta milhares de pecas em poucas malhas (predios por "pedaco" do mapa,
## objetos repetidos em MultiMesh) para rodar bem no celular.
## Trocar por um mapa feito a mao no futuro: crie outra cena GameMap.

const CHUNK := 64.0
const CAR_COLORS: Array[Color] = [
	Color(0.75, 0.1, 0.1), Color(0.9, 0.9, 0.88), Color(0.15, 0.15, 0.18),
	Color(0.2, 0.35, 0.6), Color(0.55, 0.55, 0.55), Color(0.95, 0.8, 0.15),
]
const HOUSE_COLORS: Array[Color] = [
	Color(0.75, 0.38, 0.25), Color(0.85, 0.5, 0.3), Color(0.9, 0.85, 0.4), Color(0.35, 0.55, 0.8),
	Color(0.9, 0.55, 0.6), Color(0.95, 0.95, 0.9), Color(0.5, 0.75, 0.45), Color(0.7, 0.45, 0.3),
]
const GLASS := Color(0.12, 0.14, 0.18)
const BUILDING_SHADER: Shader = preload("res://game/maps/building.gdshader")

@export var layout: CityLayout

var _rng := RandomNumberGenerator.new()
var _ground: SurfaceTool
var _chunks: Dictionary = {}  # Vector2i -> SurfaceTool (predios)
var _scenery: SurfaceTool     # cenario fora da area jogavel (morro, Cristo...)
var _props: Dictionary = {}   # nome -> Array[Transform3D]
var _cars: Array[Transform3D] = []
var _car_colors: Array[Color] = []
var _obstacles: StaticBody3D
var _city_max_z: float = 0.0


func build_async() -> void:
	if layout == null:
		layout = CityLayout.new()
	_rng.seed = layout.seed
	var he := layout.half_extents
	bounds = Rect2(-he.x, -he.y, he.x * 2.0, he.y * 2.0)
	grid = MapGrid.new(bounds, 0.5)
	_ground = PlaceholderMeshes.begin()
	_scenery = PlaceholderMeshes.begin()
	_obstacles = StaticBody3D.new()
	_obstacles.name = "Obstacles"
	_obstacles.collision_layer = 16  # camada 5: "world" (o jogador colide com ela)
	_obstacles.collision_mask = 0
	add_child(_obstacles)
	_city_max_z = he.y - (layout.beach_depth if layout.beach_south else 0.0)

	_build_ground()
	await _step(0.05, "Asfalto e calçadas")
	var centers := _block_centers()
	for i: int in centers.size():
		_build_block(centers[i])
		if i % 4 == 3:
			await _step(0.05 + 0.55 * float(i) / centers.size(), "Prédios e caixas d'água")
	_build_streets()
	_build_street_life(centers)
	await _step(0.65, "Ruas, orelhões e bancas")
	if layout.beach_south:
		_build_beach()
		await _step(0.75, "Orla de Copacabana")
	if layout.morro_north:
		_build_morro()
		await _step(0.85, "Morro e comunidade")
	if layout.sugarloaf:
		_build_sugarloaf()
	_build_landmark_signs()
	_build_walls()
	_commit()
	await _step(0.97, "Últimos detalhes")
	player_spawn = grid.nearest_free(Vector2(0, 0))
	is_built = true
	build_progress.emit(1.0, "Pronto")


## Avisa o progresso e deixa um frame passar (a tela de carregamento anima).
func _step(ratio: float, label: String) -> void:
	build_progress.emit(ratio, label)
	await get_tree().process_frame


## Regiao do mapa num ponto (audio de ambiente, avisos): beach, hills ou city.
func region_at(p: Vector2) -> StringName:
	if layout.beach_south and p.y > _city_max_z:
		return &"beach"
	if layout.morro_north and p.y < -layout.half_extents.y + 28.0:
		return &"hills"
	return &"city"


# --- Chao ---------------------------------------------------------------------

func _build_ground() -> void:
	var he := layout.half_extents
	# Terra escura em volta (para nao ver "o vazio") e asfalto na area jogavel.
	PlaceholderMeshes.add_box(_ground, Vector3(900, 0.1, 900), Vector3(0, -0.2, 0),
			layout.asphalt_color.darkened(0.35))
	PlaceholderMeshes.add_box(_ground, Vector3(he.x * 2.0 + 40.0, 0.1, he.y * 2.0 + 40.0),
			Vector3(0, -0.05, 0), layout.asphalt_color)


func _pitch() -> float:
	return layout.block_size + layout.street_width


## Centros dos quarteiroes que cabem inteiros na cidade.
func _block_centers() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var he := layout.half_extents
	var half := layout.block_size * 0.5
	var n := ceili(maxf(he.x, he.y) / _pitch()) + 1
	for gx: int in range(-n, n):
		for gz: int in range(-n, n):
			var c := Vector2((gx + 0.5) * _pitch(), (gz + 0.5) * _pitch())
			if absf(c.x) + half > he.x - 2.0:
				continue
			if c.y - half < -he.y + 2.0 or c.y + half > _city_max_z - layout.street_width:
				continue
			out.append(c)
	return out


# --- Quarteiroes e predios ------------------------------------------------------

func _build_block(c: Vector2) -> void:
	var bs := layout.block_size
	PlaceholderMeshes.add_box(_ground, Vector3(bs, 0.15, bs), Vector3(c.x, 0.075, c.y),
			layout.sidewalk_color)
	if _rng.randf() < layout.plaza_ratio:
		_build_plaza(c)
	else:
		_build_lots(c)
	for i: int in roundi(layout.rubble_per_block * _rng.randf_range(0.0, 2.0)):
		var p := c + Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).normalized() \
				* (bs * 0.5 + _rng.randf_range(0.5, 2.5))
		_add_prop("rubble", p, _rng.randf() * TAU, 1.0, Vector2(1.6, 1.4))
	# Postes nos cantos da calcada.
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		if _rng.randf() < 0.6:
			_add_prop("lamp", c + corner * (bs * 0.5 - 0.6), PI * 0.25 * corner.x, 1.0,
					Vector2.ZERO)


func _build_plaza(c: Vector2) -> void:
	var size := layout.block_size - 3.0
	PlaceholderMeshes.add_box(_ground, Vector3(size, 0.2, size), Vector3(c.x, 0.1, c.y),
			layout.grass_color)
	for i: int in _rng.randi_range(3, 6):
		var p := c + Vector2(_rng.randf_range(-0.38, 0.38), _rng.randf_range(-0.38, 0.38)) * size
		if p.length() < 6.0:
			continue
		_add_prop("tree", p, _rng.randf() * TAU, _rng.randf_range(0.8, 1.3), Vector2(0.9, 0.9))


func _build_lots(c: Vector2) -> void:
	var inner := layout.block_size - 3.2  # calcada em volta
	var split := _rng.randi_range(1, 4)
	var lots: Array[Rect2] = []
	var r := Rect2(c - Vector2(inner, inner) * 0.5, Vector2(inner, inner))
	match split:
		1:
			lots.append(r)
		2:
			lots.append(Rect2(r.position, Vector2(r.size.x * 0.5, r.size.y)))
			lots.append(Rect2(r.position + Vector2(r.size.x * 0.5, 0), Vector2(r.size.x * 0.5, r.size.y)))
		3:
			lots.append(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.5)))
			lots.append(Rect2(r.position + Vector2(0, r.size.y * 0.5), Vector2(r.size.x, r.size.y * 0.5)))
		_:
			var h := r.size * 0.5
			for ix: int in 2:
				for iz: int in 2:
					lots.append(Rect2(r.position + Vector2(ix * h.x, iz * h.y), h))
	for lot: Rect2 in lots:
		_build_building(lot.grow(-0.6))


func _build_building(lot: Rect2) -> void:
	var destroyed := _rng.randf() < layout.destroyed_ratio
	var floors := _rng.randi_range(layout.min_floors, layout.max_floors)
	var color: Color = layout.palette[_rng.randi_range(0, layout.palette.size() - 1)] \
			if not layout.palette.is_empty() else Color(0.8, 0.78, 0.72)
	if destroyed:
		floors = maxi(1, floors / 3)
		color = color.darkened(0.4)
	var h := floors * layout.floor_height
	var w := lot.size.x
	var d := lot.size.y
	var c2 := lot.get_center()
	var st := _chunk_tool(c2)
	PlaceholderMeshes.add_box(st, Vector3(w, h, d), Vector3(c2.x, h * 0.5, c2.y), color)
	# Faixas de janelas (uma por andar).
	for f: int in floors:
		var y := f * layout.floor_height + layout.floor_height * 0.55
		PlaceholderMeshes.add_box(st, Vector3(w + 0.08, 0.9, d + 0.08), Vector3(c2.x, y, c2.y),
				GLASS if not destroyed else Color(0.05, 0.05, 0.05))
	# Laje e caixa d'agua (bem carioca).
	PlaceholderMeshes.add_box(st, Vector3(w + 0.3, 0.35, d + 0.3), Vector3(c2.x, h + 0.17, c2.y),
			color.darkened(0.25))
	if not destroyed and _rng.randf() < 0.6:
		PlaceholderMeshes.add_box(st, Vector3(1.4, 1.2, 1.4),
				Vector3(c2.x + w * 0.2, h + 0.95, c2.y - d * 0.2), Color(0.2, 0.4, 0.75))
	_add_collision(c2, Vector3(w, h, d), 0.0)
	grid.block_rect(c2, Vector2(w, d), 0.0, 0.05)
	if destroyed:
		for i: int in 3:
			var p := c2 + Vector2(_rng.randf_range(-0.6, 0.6) * w, (d * 0.5 + 1.2) * (1 if _rng.randf() < 0.5 else -1))
			_add_prop("rubble", p, _rng.randf() * TAU, 1.2, Vector2(1.8, 1.6))


# --- Ruas ---------------------------------------------------------------------

func _build_streets() -> void:
	var he := layout.half_extents
	var p := _pitch()
	var n := ceili(maxf(he.x, he.y) / p) + 1
	# Ruas verticais (x fixo) e horizontais (z fixo) passam pelos multiplos do pitch.
	for k: int in range(-n, n + 1):
		var x := k * p
		if absf(x) < he.x - 3.0:
			_street_segments(Vector2(x, -he.y), Vector2(x, _city_max_z), true)
		var z := k * p
		if z > -he.y + 3.0 and z < _city_max_z:
			_street_segments(Vector2(-he.x, z), Vector2(he.x, z), false)


func _street_segments(a: Vector2, b: Vector2, vertical: bool) -> void:
	var length := a.distance_to(b)
	var dir := (b - a).normalized()
	var rot := GroundPlane.heading(dir)
	# Faixa central tracejada.
	var t := 2.0
	while t < length:
		var m := a + dir * t
		PlaceholderMeshes.add_box(_ground, Vector3(0.18, 0.04, 2.2), Vector3(m.x, 0.02, m.y),
				layout.lane_color, rot)
		t += 6.0
	# Carros abandonados, onibus e barricadas.
	var seg := _pitch()
	var s := 0.0
	while s < length:
		var count := floori(layout.cars_per_street + _rng.randf())
		for i: int in count:
			var along := s + _rng.randf_range(layout.street_width * 0.6, seg - 2.0)
			var lane := _rng.randf_range(1.6, 3.2) * (1.0 if _rng.randf() < 0.5 else -1.0)
			var pos := a + dir * along + dir.orthogonal() * lane
			var crashed := _rng.randf() < 0.2
			var car_rot := rot + (_rng.randf_range(-1.2, 1.2) if crashed else _rng.randf_range(-0.15, 0.15))
			if _rng.randf() < 0.06:
				_add_bus(pos, car_rot)
			else:
				_add_car(pos, car_rot)
		if _rng.randf() < layout.barricade_chance:
			var bpos := a + dir * (s + seg * 0.5) + dir.orthogonal() * _rng.randf_range(-2.0, 2.0)
			_add_prop("barricade", bpos, rot + PI * 0.5, 1.0, Vector2(3.2, 1.0))
		s += seg


func _add_car(pos: Vector2, rot: float) -> void:
	if pos.length() < 7.0 or grid.is_blocked(pos):
		return
	_cars.append(Transform3D(Basis(Vector3.UP, rot), GroundPlane.to_3d(pos)))
	_car_colors.append(CAR_COLORS[_rng.randi_range(0, CAR_COLORS.size() - 1)])
	_add_collision(pos, Vector3(1.8, 1.4, 4.2), rot)
	grid.block_rect(pos, Vector2(1.8, 4.2), rot, 0.05)


func _add_bus(pos: Vector2, rot: float) -> void:
	if pos.length() < 10.0 or grid.is_blocked(pos):
		return
	var xf := Transform3D(Basis(Vector3.UP, rot), GroundPlane.to_3d(pos))
	var mesh := PlaceholderMeshes.bus(layout.bus_color)
	var st := _chunk_tool(pos)
	st.append_from(mesh, 0, xf)
	_add_collision(pos, Vector3(2.5, 3.0, 11.0), rot)
	grid.block_rect(pos, Vector2(2.5, 11.0), rot, 0.05)


# --- Orla (praia ao sul) -------------------------------------------------------

func _build_beach() -> void:
	var he := layout.half_extents
	var z0 := _city_max_z  # inicio da avenida da orla
	var calcadao_z := z0 + layout.street_width
	var calcadao_w := 7.0
	# Calcadao com o desenho de ondas (textura gerada).
	var walk := MeshInstance3D.new()
	walk.name = "Calcadao"
	var plane := PlaneMesh.new()
	plane.size = Vector2(he.x * 2.0 + 40.0, calcadao_w)
	walk.mesh = plane
	walk.position = Vector3(0, 0.12, calcadao_z + calcadao_w * 0.5)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _wave_texture()
	mat.uv1_scale = Vector3(plane.size.x / 7.0, 1, 1)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	walk.material_override = mat
	add_child(walk)
	# Areia e mar.
	var sand_z0 := calcadao_z + calcadao_w
	var sand_len := he.y + 25.0 - sand_z0
	PlaceholderMeshes.add_box(_ground, Vector3(he.x * 2.0 + 40.0, 0.2, sand_len),
			Vector3(0, 0.0, sand_z0 + sand_len * 0.5), layout.sand_color)
	var sea := MeshInstance3D.new()
	sea.name = "Mar"
	var sea_plane := PlaneMesh.new()
	sea_plane.size = Vector2(900, 400)
	sea.mesh = sea_plane
	sea.position = Vector3(0, -0.15, he.y + 25.0 + 200.0)
	var sea_mat := StandardMaterial3D.new()
	sea_mat.albedo_color = layout.sea_color
	sea_mat.roughness = 0.15
	sea_mat.metallic_specular = 0.8
	sea.material_override = sea_mat
	add_child(sea)
	# Palmeiras no calcadao e quiosques na areia.
	var x := -he.x + 4.0
	while x < he.x - 4.0:
		_add_prop("palm", Vector2(x + _rng.randf_range(-1, 1), calcadao_z + calcadao_w - 1.0),
				_rng.randf() * TAU, _rng.randf_range(0.9, 1.15), Vector2(0.7, 0.7))
		x += 9.0
	_build_beach_life(sand_z0, calcadao_z)
	x = -he.x + 20.0
	while x < he.x - 10.0:
		var kp := Vector2(x, sand_z0 + 8.0)
		var st := _chunk_tool(kp)
		PlaceholderMeshes.add_box(st, Vector3(3.0, 2.6, 3.0), GroundPlane.to_3d(kp, 1.3), Color(0.95, 0.95, 0.9))
		PlaceholderMeshes.add_box(st, Vector3(4.2, 0.3, 4.2), GroundPlane.to_3d(kp, 2.75), Color(0.9, 0.35, 0.2))
		_add_collision(kp, Vector3(3.0, 2.6, 3.0), 0.0)
		grid.block_rect(kp, Vector2(3.0, 3.0), 0.0, 0.05)
		x += 38.0 + _rng.randf_range(-6, 6)


## Textura do calcadao de Copacabana: ondas pretas e brancas.
func _wave_texture() -> ImageTexture:
	var size := 128
	var img := Image.create_empty(size, size, true, Image.FORMAT_RGB8)
	var black := Color(0.12, 0.12, 0.12)
	var white := Color(0.92, 0.9, 0.86)
	for y: int in size:
		for x: int in size:
			var u := float(x) / size
			var v := float(y) / size
			var wave := v * 2.0 + 0.22 * sin(u * TAU)
			img.set_pixel(x, y, black if fposmod(wave, 1.0) < 0.5 else white)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# --- Morro com comunidade, Cristo e Pao de Acucar (cenario) ---------------------

func _build_morro() -> void:
	var he := layout.half_extents
	var hills: Array[Vector4] = []  # (x, z, raio, achatamento)
	var x := -he.x - 20.0
	while x < he.x + 40.0:
		hills.append(Vector4(x, -he.y - 32.0 - _rng.randf_range(0, 12), _rng.randf_range(42, 58), 0.42))
		x += 62.0
	var green := Color(0.22, 0.4, 0.2)
	for h: Vector4 in hills:
		PlaceholderMeshes.add_sphere(_scenery, h.z, Vector3(h.x, 0, h.y), green.lightened(_rng.randf() * 0.1),
				Vector3(1, h.w, 1), 18)
	# Casinhas da comunidade na encosta voltada para a cidade.
	for i: int in layout.morro_houses:
		var h: Vector4 = hills[_rng.randi_range(0, hills.size() - 1)]
		var off := Vector2(_rng.randf_range(-0.85, 0.85) * h.z, _rng.randf_range(0.05, 0.85) * h.z)
		var d2 := off.length_squared()
		if d2 > h.z * h.z * 0.8:
			continue
		var y := h.w * sqrt(h.z * h.z - d2)
		var size := Vector3(_rng.randf_range(3, 5), _rng.randf_range(2.6, 5.5), _rng.randf_range(3, 5))
		var col: Color = HOUSE_COLORS[_rng.randi_range(0, HOUSE_COLORS.size() - 1)]
		PlaceholderMeshes.add_box(_scenery, size, Vector3(h.x + off.x, y + size.y * 0.3, h.y + off.y),
				col, _rng.randf_range(-0.2, 0.2))
	if layout.cristo:
		# Corcovado: morro mais alto ao fundo, com o Cristo no topo.
		var cz := -he.y - 120.0
		var r := 75.0
		var squash := 0.95
		PlaceholderMeshes.add_sphere(_scenery, r, Vector3(-20, 0, cz), Color(0.2, 0.36, 0.2),
				Vector3(1, squash, 1), 20)
		var top := r * squash
		var stone := Color(0.9, 0.9, 0.86)
		PlaceholderMeshes.add_box(_scenery, Vector3(6, 6, 6), Vector3(-20, top + 2, cz), stone)
		PlaceholderMeshes.add_box(_scenery, Vector3(4, 22, 3.5), Vector3(-20, top + 16, cz), stone)
		PlaceholderMeshes.add_box(_scenery, Vector3(26, 3, 3), Vector3(-20, top + 22, cz), stone)
		PlaceholderMeshes.add_sphere(_scenery, 2.2, Vector3(-20, top + 28.5, cz), stone)


func _build_sugarloaf() -> void:
	var he := layout.half_extents
	var rock := Color(0.42, 0.45, 0.38)
	PlaceholderMeshes.add_sphere(_scenery, 28.0, Vector3(he.x * 0.55, -2, he.y + 110.0), rock,
			Vector3(1, 1.9, 1), 18)
	PlaceholderMeshes.add_sphere(_scenery, 17.0, Vector3(he.x * 0.55 - 48.0, -2, he.y + 90.0),
			rock.lightened(0.05), Vector3(1, 1.5, 1), 16)


# --- Utilitarios ----------------------------------------------------------------

func _build_walls() -> void:
	var he := layout.half_extents
	for w: Array in [[Vector2(0, -he.y - 1), Vector3(he.x * 2 + 4, 6, 2)],
			[Vector2(0, he.y + 1), Vector3(he.x * 2 + 4, 6, 2)],
			[Vector2(-he.x - 1, 0), Vector3(2, 6, he.y * 2 + 4)],
			[Vector2(he.x + 1, 0), Vector3(2, 6, he.y * 2 + 4)]]:
		_add_collision(w[0] as Vector2, w[1] as Vector3, 0.0)


func _chunk_tool(p: Vector2) -> SurfaceTool:
	var key := Vector2i(floori(p.x / CHUNK), floori(p.y / CHUNK))
	if not _chunks.has(key):
		_chunks[key] = PlaceholderMeshes.begin()
	return _chunks[key]


func _add_collision(center: Vector2, size: Vector3, rot: float) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.transform = Transform3D(Basis(Vector3.UP, rot), GroundPlane.to_3d(center, size.y * 0.5))
	_obstacles.add_child(shape)


func _add_prop(kind: String, pos: Vector2, rot: float, scale: float, footprint: Vector2) -> void:
	if pos.length() < 5.0:
		return  # Area livre em volta do inicio do jogador.
	if footprint != Vector2.ZERO:
		if grid.is_blocked(pos):
			return
		grid.block_rect(pos, footprint * scale, rot, 0.0)
		_add_collision(pos, Vector3(footprint.x * scale, 1.5, footprint.y * scale), rot)
	if not _props.has(kind):
		_props[kind] = [] as Array[Transform3D]
	(_props[kind] as Array[Transform3D]).append(
			Transform3D(Basis(Vector3.UP, rot).scaled(Vector3.ONE * scale), GroundPlane.to_3d(pos)))


func _prop_mesh(kind: String) -> Mesh:
	match kind:
		"palm": return PlaceholderMeshes.palm()
		"tree": return PlaceholderMeshes.tree()
		"lamp": return PlaceholderMeshes.lamp_post()
		"barricade": return PlaceholderMeshes.barricade()
		_: return PlaceholderMeshes.rubble()


func _commit() -> void:
	_add_mesh("Ground", PlaceholderMeshes.finish(_ground), false)
	_add_mesh("Scenery", PlaceholderMeshes.finish(_scenery), false)
	# Predios usam o shader com "buraco de visao" (o jogador nunca some atras deles).
	var building_mat := ShaderMaterial.new()
	building_mat.shader = BUILDING_SHADER
	for key: Vector2i in _chunks:
		var mi := _add_mesh("Buildings_%d_%d" % [key.x, key.y], PlaceholderMeshes.finish(_chunks[key]), true)
		mi.material_override = building_mat
	for kind: String in _props:
		_add_multimesh(kind, _prop_mesh(kind), _props[kind], [])
	_add_multimesh("Cars", PlaceholderMeshes.car(Color.WHITE), _cars, _car_colors)


func _add_mesh(node_name: String, mesh: Mesh, shadows: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _add_multimesh(node_name: String, mesh: Mesh, xforms: Array[Transform3D], colors: Array[Color]) -> void:
	if xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colors.is_empty()
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i: int in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		if mm.use_colors:
			mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	add_child(mmi)


# --- Identidade carioca: orla, rua e pontos turisticos -----------------------------

const UMBRELLA_COLORS: Array[Color] = [Color(0.95, 0.3, 0.25), Color(1.0, 0.85, 0.2),
	Color(0.2, 0.6, 0.95), Color(0.25, 0.75, 0.4), Color(1.0, 0.55, 0.15)]


## Guarda-sois, cadeiras, postos salva-vidas numerados e o letreiro COPACABANA.
func _build_beach_life(sand_z0: float, calcadao_z: float) -> void:
	var he := layout.half_extents
	var x := -he.x + 10.0
	while x < he.x - 8.0:
		var p := Vector2(x + _rng.randf_range(-3, 3), sand_z0 + _rng.randf_range(14.0, 24.0))
		if p.y < he.y - 1.0 and grid.is_free(p):
			var col: Color = UMBRELLA_COLORS[_rng.randi_range(0, UMBRELLA_COLORS.size() - 1)]
			var cst := _chunk_tool(p)
			PlaceholderMeshes.add_box(cst, Vector3(0.08, 2.2, 0.08), GroundPlane.to_3d(p, 1.1), Color(0.9, 0.9, 0.9))
			PlaceholderMeshes.add_sphere(cst, 1.3, GroundPlane.to_3d(p, 2.2), col, Vector3(1, 0.28, 1), 10)
			PlaceholderMeshes.add_box(cst, Vector3(0.6, 0.12, 1.4), GroundPlane.to_3d(p + Vector2(0.9, 0.3), 0.3),
					col.lightened(0.3), 0.2)
		x += _rng.randf_range(6.0, 11.0)
	# Postos salva-vidas (Posto 4, 5, 6...) com placa.
	var posto := 4
	x = -he.x + 30.0
	while x < he.x - 20.0:
		var p2 := Vector2(x, sand_z0 + 6.0)
		var pst := _chunk_tool(p2)
		PlaceholderMeshes.add_box(pst, Vector3(3.2, 3.0, 3.2), GroundPlane.to_3d(p2, 1.5), Color(0.95, 0.95, 0.92))
		PlaceholderMeshes.add_box(pst, Vector3(3.6, 0.3, 3.6), GroundPlane.to_3d(p2, 3.15), Color(0.2, 0.45, 0.85))
		_add_collision(p2, Vector3(3.2, 3.0, 3.2), 0.0)
		grid.block_rect(p2, Vector2(3.2, 3.2), 0.0, 0.05)
		_add_sign("POSTO %d" % posto, GroundPlane.to_3d(p2, 4.3), 28, Color(0.95, 0.25, 0.2))
		posto += 1
		x += 55.0
	_add_sign("COPACABANA", Vector3(0, 0.6, calcadao_z + 3.5), 140, Color(1.0, 0.85, 0.3))
	_add_sign("AV. ATLÂNTICA", Vector3(-he.x * 0.5, 2.5, calcadao_z - 2.0), 36, Color(0.3, 0.55, 0.95))


## Orelhoes, bancas de jornal, pontos de onibus e placas de rua nas calcadas.
func _build_street_life(centers: Array[Vector2]) -> void:
	var names: PackedStringArray = ["R. BARATA RIBEIRO", "R. SANTA CLARA", "R. FIGUEIREDO MAGALHÃES",
		"R. TONELERO", "R. SIQUEIRA CAMPOS", "R. HILÁRIO DE GOUVEIA"]
	var n := 0
	for i: int in centers.size():
		var c := centers[i]
		var half := layout.block_size * 0.5
		var r := _rng.randf()
		var side := Vector2(half - 0.9, _rng.randf_range(-half * 0.6, half * 0.6))
		if _rng.randf() < 0.5:
			side = Vector2(_rng.randf_range(-half * 0.6, half * 0.6), half - 0.9)
		var p := c + side
		var st := _chunk_tool(p)
		if r < 0.22:
			# Orelhao (cabine telefonica laranja, bem brasileira).
			PlaceholderMeshes.add_box(st, Vector3(0.12, 1.6, 0.12), GroundPlane.to_3d(p, 0.8), Color(0.3, 0.3, 0.3))
			PlaceholderMeshes.add_sphere(st, 0.6, GroundPlane.to_3d(p, 1.9), Color(1.0, 0.5, 0.1), Vector3(1, 0.9, 0.8), 10)
		elif r < 0.38:
			# Banca de jornal.
			PlaceholderMeshes.add_box(st, Vector3(2.4, 2.2, 1.6), GroundPlane.to_3d(p, 1.1), Color(0.15, 0.45, 0.3))
			PlaceholderMeshes.add_box(st, Vector3(2.8, 0.15, 2.0), GroundPlane.to_3d(p, 2.3), Color(0.85, 0.85, 0.8))
			_add_collision(p, Vector3(2.4, 2.2, 1.6), 0.0)
			grid.block_rect(p, Vector2(2.4, 1.6), 0.0, 0.05)
		elif r < 0.52:
			# Ponto de onibus (banco + cobertura).
			PlaceholderMeshes.add_box(st, Vector3(2.6, 0.12, 1.2), GroundPlane.to_3d(p, 2.4), Color(0.25, 0.3, 0.35))
			PlaceholderMeshes.add_box(st, Vector3(0.08, 2.4, 0.08), GroundPlane.to_3d(p + Vector2(1.2, 0), 1.2), Color(0.3, 0.3, 0.3))
			PlaceholderMeshes.add_box(st, Vector3(0.08, 2.4, 0.08), GroundPlane.to_3d(p - Vector2(1.2, 0), 1.2), Color(0.3, 0.3, 0.3))
			PlaceholderMeshes.add_box(st, Vector3(2.2, 0.1, 0.5), GroundPlane.to_3d(p, 0.5), Color(0.5, 0.35, 0.2))
		if i % 7 == 3 and n < names.size():
			_add_sign(names[n], GroundPlane.to_3d(c + Vector2(-half + 0.5, -half + 0.5), 3.2), 26,
					Color(0.3, 0.55, 0.95))
			n += 1


## Entrada de tunel no pe do morro e placas dos pontos turisticos.
func _build_landmark_signs() -> void:
	var he := layout.half_extents
	if layout.morro_north:
		var tp := Vector2(he.x * 0.35, -he.y - 3.0)
		PlaceholderMeshes.add_box(_scenery, Vector3(12, 8, 4), GroundPlane.to_3d(tp, 4.0), Color(0.45, 0.43, 0.4))
		PlaceholderMeshes.add_box(_scenery, Vector3(8, 5.5, 4.2), GroundPlane.to_3d(tp + Vector2(0, 0.1), 2.75),
				Color(0.05, 0.05, 0.06))
		_add_sign("TÚNEL NOVO", GroundPlane.to_3d(tp + Vector2(0, 2.2), 8.6), 36, Color(1.0, 0.85, 0.3))
	if layout.cristo:
		_add_sign("CRISTO REDENTOR", Vector3(-20, 30, -he.y - 60.0), 90, Color(0.95, 0.95, 0.9))
	if layout.sugarloaf:
		_add_sign("PÃO DE AÇÚCAR", Vector3(he.x * 0.55, 18, he.y + 60.0), 90, Color(0.95, 0.95, 0.9))


func _add_sign(text: String, pos: Vector3, size: int, color: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = size
	l.pixel_size = 0.02
	l.modulate = color
	l.outline_size = 10
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.shaded = false
	l.double_sided = true
	add_child(l)
