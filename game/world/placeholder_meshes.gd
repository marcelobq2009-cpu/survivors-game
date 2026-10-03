class_name PlaceholderMeshes
extends RefCounted
## Fabrica de modelos 3D placeholder montados com formas simples (caixas,
## esferas, cilindros) e cores por vertice. Cada modelo e UMA malha so
## (barato de desenhar). Para trocar por arte real: preencha `mesh`/`model_scene`
## nos .tres — o codigo do jogo nao muda.
## Convencao: modelos olham para +Z e tem os pes em y = 0.

static var _cache: Dictionary = {}
static var _vertex_color_material: StandardMaterial3D


## Material padrao: usa a cor dos vertices (e a cor por instancia do MultiMesh).
static func vertex_color_material() -> StandardMaterial3D:
	if _vertex_color_material == null:
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 0.9
		_vertex_color_material = m
	return _vertex_color_material


# --- Pecas publicas (usadas pelo gerador de cidade para juntar tudo numa malha) --

static func begin() -> SurfaceTool:
	return _begin()


static func finish(st: SurfaceTool) -> ArrayMesh:
	return _finish(st)


static func add_box(st: SurfaceTool, size: Vector3, center: Vector3, color: Color,
		rot_y: float = 0.0) -> void:
	_box(st, size, center, color, rot_y)


static func add_sphere(st: SurfaceTool, radius: float, center: Vector3, color: Color,
		squash: Vector3 = Vector3.ONE, segments: int = 12) -> void:
	_sphere(st, radius, center, color, squash, segments)


# --- Pecas -------------------------------------------------------------------

static func _box(st: SurfaceTool, size: Vector3, center: Vector3, color: Color,
		rot_y: float = 0.0, rot_x: float = 0.0) -> void:
	var b := BoxMesh.new()
	b.size = size
	var xf := Transform3D(Basis.from_euler(Vector3(rot_x, rot_y, 0.0)), center)
	_append(st, b, xf, color)


static func _sphere(st: SurfaceTool, radius: float, center: Vector3, color: Color,
		squash: Vector3 = Vector3.ONE, segments: int = 10) -> void:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = segments
	s.rings = maxi(3, segments / 2)
	_append(st, s, Transform3D(Basis.from_scale(squash), center), color)


static func _cylinder(st: SurfaceTool, radius: float, height: float, center: Vector3,
		color: Color, basis: Basis = Basis.IDENTITY, segments: int = 8) -> void:
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = segments
	c.rings = 1
	_append(st, c, Transform3D(basis, center), color)


## Copia uma forma primitiva para o SurfaceTool com transformacao e cor.
static func _append(st: SurfaceTool, prim: PrimitiveMesh, xf: Transform3D, color: Color) -> void:
	var arrays := prim.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i: int in indices:
		st.set_color(color)
		st.set_normal((xf.basis * normals[i]).normalized())
		st.add_vertex(xf * verts[i])


static func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func _finish(st: SurfaceTool) -> ArrayMesh:
	var mesh := st.commit()
	if mesh.get_surface_count() > 0:  # Pedaco vazio (sem nada dentro) nao tem superficie.
		mesh.surface_set_material(0, vertex_color_material())
	return mesh


static func _cached(key: String, builder: Callable) -> Mesh:
	if not _cache.has(key):
		_cache[key] = builder.call()
	return _cache[key]


# --- Modelos ------------------------------------------------------------------

## Zumbi: bracos esticados para frente (+Z). A cor final ainda e multiplicada
## pela cor da instancia no MultiMesh.
static func zombie(body: Color, skin: Color) -> Mesh:
	return _cached("zombie_%s_%s" % [body.to_html(), skin.to_html()], func() -> Mesh:
		var st := _begin()
		var pants := body.darkened(0.45)
		_box(st, Vector3(0.18, 0.8, 0.2), Vector3(-0.12, 0.4, 0.0), pants)
		_box(st, Vector3(0.18, 0.8, 0.2), Vector3(0.12, 0.4, 0.05), pants)
		_box(st, Vector3(0.5, 0.62, 0.28), Vector3(0.0, 1.12, 0.0), body, 0.0, 0.15)
		_sphere(st, 0.17, Vector3(0.02, 1.6, 0.08), skin)
		_box(st, Vector3(0.12, 0.12, 0.6), Vector3(-0.2, 1.3, 0.32), skin, 0.0, -0.1)
		_box(st, Vector3(0.12, 0.12, 0.55), Vector3(0.2, 1.26, 0.3), skin, 0.0, 0.05)
		return _finish(st))


## Modelo de zumbi por tipo (silhueta diferente = leitura rapida da ameaca).
static func zombie_kind(kind: int, body: Color, skin: Color) -> Mesh:
	match kind:
		EnemyData.ModelKind.RUNNER:
			return _cached("runner_%s" % body.to_html(), func() -> Mesh:
				var st := _begin()
				var pants := body.darkened(0.5)
				_box(st, Vector3(0.14, 0.85, 0.16), Vector3(-0.1, 0.42, -0.05), pants, 0.0, 0.25)
				_box(st, Vector3(0.14, 0.85, 0.16), Vector3(0.1, 0.42, 0.1), pants, 0.0, -0.3)
				_box(st, Vector3(0.36, 0.55, 0.22), Vector3(0.0, 1.0, 0.18), body, 0.0, 0.55)
				_sphere(st, 0.14, Vector3(0.0, 1.25, 0.48), skin)
				_box(st, Vector3(0.09, 0.09, 0.75), Vector3(-0.2, 0.95, 0.5), skin, 0.2, 0.3)
				_box(st, Vector3(0.09, 0.09, 0.75), Vector3(0.2, 0.9, 0.48), skin, -0.2, 0.35)
				return _finish(st))
		EnemyData.ModelKind.BRUTE:
			return _cached("brute_%s" % body.to_html(), func() -> Mesh:
				var st := _begin()
				var pants := body.darkened(0.4)
				_box(st, Vector3(0.26, 0.7, 0.28), Vector3(-0.2, 0.35, 0.0), pants)
				_box(st, Vector3(0.26, 0.7, 0.28), Vector3(0.2, 0.35, 0.0), pants)
				_box(st, Vector3(0.8, 0.75, 0.45), Vector3(0.0, 1.08, 0.0), body, 0.0, 0.2)
				_sphere(st, 0.16, Vector3(0.0, 1.52, 0.18), skin)
				_box(st, Vector3(0.22, 0.75, 0.24), Vector3(-0.52, 0.95, 0.15), skin, 0.0, -0.4)
				_box(st, Vector3(0.22, 0.75, 0.24), Vector3(0.52, 0.95, 0.15), skin, 0.0, -0.4)
				_sphere(st, 0.17, Vector3(-0.55, 0.62, 0.38), skin.darkened(0.2))
				_sphere(st, 0.17, Vector3(0.55, 0.62, 0.38), skin.darkened(0.2))
				return _finish(st))
		EnemyData.ModelKind.BLOATER:
			return _cached("bloater_%s" % body.to_html(), func() -> Mesh:
				var st := _begin()
				_box(st, Vector3(0.18, 0.6, 0.2), Vector3(-0.16, 0.3, 0.0), body.darkened(0.4))
				_box(st, Vector3(0.18, 0.6, 0.2), Vector3(0.16, 0.3, 0.0), body.darkened(0.4))
				_sphere(st, 0.52, Vector3(0.0, 1.0, 0.08), skin, Vector3(1.0, 0.9, 1.05), 12)
				_sphere(st, 0.15, Vector3(0.0, 1.55, 0.05), skin.darkened(0.15))
				var glow := Color(1.0, 0.85, 0.25)
				for p: Vector3 in [Vector3(0.3, 1.2, 0.4), Vector3(-0.35, 0.9, 0.35), Vector3(0.1, 0.75, 0.52), Vector3(-0.1, 1.35, 0.42)]:
					_sphere(st, 0.09, p, glow, Vector3.ONE, 6)
				_box(st, Vector3(0.1, 0.1, 0.4), Vector3(-0.42, 1.1, 0.2), skin)
				_box(st, Vector3(0.1, 0.1, 0.4), Vector3(0.42, 1.1, 0.2), skin)
				return _finish(st))
		EnemyData.ModelKind.COLOSSUS:
			return _cached("colossus_%s" % body.to_html(), func() -> Mesh:
				var st := _begin()
				var rock := Color(0.45, 0.42, 0.38)
				_box(st, Vector3(0.3, 0.75, 0.3), Vector3(-0.22, 0.37, 0.0), body.darkened(0.4))
				_box(st, Vector3(0.3, 0.75, 0.3), Vector3(0.22, 0.37, 0.0), body.darkened(0.4))
				_box(st, Vector3(0.9, 0.8, 0.5), Vector3(0.0, 1.1, 0.05), body, 0.0, 0.25)
				_box(st, Vector3(0.45, 0.25, 0.5), Vector3(-0.55, 1.5, 0.0), rock, 0.3)
				_box(st, Vector3(0.45, 0.25, 0.5), Vector3(0.55, 1.5, 0.0), rock, -0.3)
				_sphere(st, 0.15, Vector3(0.0, 1.55, 0.3), skin)
				_box(st, Vector3(0.26, 0.9, 0.28), Vector3(-0.62, 0.95, 0.2), skin, 0.0, -0.5)
				_box(st, Vector3(0.26, 0.9, 0.28), Vector3(0.62, 0.95, 0.2), skin, 0.0, -0.5)
				return _finish(st))
		EnemyData.ModelKind.MUTANT:
			return _cached("mutant_%s" % body.to_html(), func() -> Mesh:
				var st := _begin()
				var spike := Color(0.85, 0.85, 0.7)
				_box(st, Vector3(0.14, 1.0, 0.16), Vector3(-0.14, 0.5, 0.0), body.darkened(0.4))
				_box(st, Vector3(0.14, 1.0, 0.16), Vector3(0.14, 0.5, 0.0), body.darkened(0.4))
				_box(st, Vector3(0.45, 0.8, 0.28), Vector3(0.0, 1.38, 0.0), body)
				_sphere(st, 0.15, Vector3(0.0, 1.95, 0.08), skin)
				for side: float in [-1.0, 1.0]:
					_box(st, Vector3(0.09, 0.09, 0.8), Vector3(0.3 * side, 1.6, 0.35), skin, 0.15 * side)
					_box(st, Vector3(0.08, 0.08, 0.6), Vector3(0.3 * side, 1.15, 0.3), skin.darkened(0.2), -0.2 * side)
				for i: int in 4:
					_box(st, Vector3(0.06, 0.28, 0.06), Vector3(0.0, 1.55 + i * 0.12, -0.17), spike, 0.0, -0.6)
				return _finish(st))
	return zombie(body, skin)


## Pessoa (sobrevivente): bracos ao lado do corpo e mochila nas costas.
static func human(shirt: Color, pants: Color = Color(0.2, 0.22, 0.3),
		skin: Color = Color(0.78, 0.58, 0.42), pack: Color = Color(0.35, 0.28, 0.2)) -> Mesh:
	return _cached("human_%s_%s_%s" % [shirt.to_html(), pants.to_html(), skin.to_html()], func() -> Mesh:
		var st := _begin()
		_box(st, Vector3(0.18, 0.82, 0.2), Vector3(-0.12, 0.41, 0.0), pants)
		_box(st, Vector3(0.18, 0.82, 0.2), Vector3(0.12, 0.41, 0.0), pants)
		_box(st, Vector3(0.5, 0.62, 0.28), Vector3(0.0, 1.13, 0.0), shirt)
		_sphere(st, 0.17, Vector3(0.0, 1.62, 0.0), skin)
		_box(st, Vector3(0.12, 0.6, 0.14), Vector3(-0.32, 1.1, 0.0), shirt.darkened(0.15))
		_box(st, Vector3(0.12, 0.6, 0.14), Vector3(0.32, 1.1, 0.0), shirt.darkened(0.15))
		_box(st, Vector3(0.38, 0.45, 0.2), Vector3(0.0, 1.15, -0.24), pack)
		_box(st, Vector3(0.12, 0.08, 0.2), Vector3(0.0, 1.68, 0.12), Color(0.1, 0.1, 0.1))
		return _finish(st))


static func car(color: Color) -> Mesh:
	return _cached("car_%s" % color.to_html(), func() -> Mesh:
		var st := _begin()
		var glass := Color(0.15, 0.2, 0.25)
		var tire := Color(0.08, 0.08, 0.08)
		_box(st, Vector3(1.8, 0.6, 4.2), Vector3(0, 0.55, 0), color)
		_box(st, Vector3(1.6, 0.55, 2.2), Vector3(0, 1.1, -0.2), glass)
		for x: float in [-0.85, 0.85]:
			for z: float in [-1.35, 1.35]:
				_cylinder(st, 0.32, 0.24, Vector3(x, 0.32, z), tire,
						Basis(Vector3.FORWARD, PI * 0.5))
		return _finish(st))


static func bus(color: Color) -> Mesh:
	return _cached("bus_%s" % color.to_html(), func() -> Mesh:
		var st := _begin()
		_box(st, Vector3(2.5, 2.6, 11.0), Vector3(0, 1.6, 0), color)
		_box(st, Vector3(2.55, 0.8, 10.0), Vector3(0, 2.2, 0.2), Color(0.15, 0.2, 0.25))
		return _finish(st))


static func palm() -> Mesh:
	return _cached("palm", func() -> Mesh:
		var st := _begin()
		var trunk := Color(0.45, 0.35, 0.22)
		var leaf := Color(0.18, 0.5, 0.2)
		for i: int in 5:
			_cylinder(st, 0.18 - i * 0.02, 1.4, Vector3(i * 0.08, 0.7 + i * 1.35, 0), trunk,
					Basis(Vector3.FORWARD, -0.06))
		for i: int in 7:
			var a := TAU * i / 7.0
			_box(st, Vector3(0.5, 0.06, 2.6), Vector3(0.4 + sin(a) * 1.1, 6.9, cos(a) * 1.1),
					leaf, a, 0.35)
		return _finish(st))


static func tree() -> Mesh:
	return _cached("tree", func() -> Mesh:
		var st := _begin()
		_cylinder(st, 0.2, 2.0, Vector3(0, 1.0, 0), Color(0.4, 0.3, 0.2))
		_sphere(st, 1.6, Vector3(0, 3.0, 0), Color(0.2, 0.45, 0.2), Vector3(1, 0.8, 1), 8)
		return _finish(st))


static func lamp_post() -> Mesh:
	return _cached("lamp", func() -> Mesh:
		var st := _begin()
		_cylinder(st, 0.08, 6.0, Vector3(0, 3.0, 0), Color(0.3, 0.32, 0.3))
		_box(st, Vector3(0.2, 0.15, 1.4), Vector3(0, 6.0, 0.6), Color(0.3, 0.32, 0.3))
		return _finish(st))


static func barricade() -> Mesh:
	return _cached("barricade", func() -> Mesh:
		var st := _begin()
		var sand := Color(0.62, 0.55, 0.4)
		for i: int in 4:
			_sphere(st, 0.42, Vector3(-1.2 + i * 0.8, 0.28, 0), sand, Vector3(1.0, 0.6, 0.8), 8)
		for i: int in 3:
			_sphere(st, 0.42, Vector3(-0.8 + i * 0.8, 0.75, 0), sand.darkened(0.1),
					Vector3(1.0, 0.6, 0.8), 8)
		return _finish(st))


static func rubble() -> Mesh:
	return _cached("rubble", func() -> Mesh:
		var st := _begin()
		var c := Color(0.5, 0.48, 0.45)
		_box(st, Vector3(1.2, 0.5, 0.9), Vector3(0, 0.25, 0), c, 0.4)
		_box(st, Vector3(0.7, 0.4, 0.6), Vector3(0.6, 0.2, 0.5), c.darkened(0.2), 1.1)
		_box(st, Vector3(0.9, 0.3, 0.5), Vector3(-0.5, 0.15, -0.4), c.lightened(0.1), 0.2)
		return _finish(st))


static func gem() -> Mesh:
	return _cached("gem", func() -> Mesh:
		var st := _begin()
		_sphere(st, 0.22, Vector3(0, 0.0, 0), Color.WHITE, Vector3(1, 1.5, 1), 4)
		return _finish(st))


static func coin() -> Mesh:
	return _cached("coin", func() -> Mesh:
		var st := _begin()
		_cylinder(st, 0.22, 0.06, Vector3.ZERO, Color(1.0, 0.8, 0.2),
				Basis(Vector3.RIGHT, PI * 0.5), 12)
		return _finish(st))


static func chest() -> Mesh:
	return _cached("chest", func() -> Mesh:
		var st := _begin()
		_box(st, Vector3(0.9, 0.5, 0.6), Vector3(0, 0.25, 0), Color(0.5, 0.3, 0.12))
		_box(st, Vector3(0.95, 0.2, 0.65), Vector3(0, 0.6, 0), Color(0.6, 0.38, 0.15))
		_box(st, Vector3(0.18, 0.22, 0.05), Vector3(0, 0.45, 0.33), Color(1.0, 0.85, 0.3))
		return _finish(st))


## Projetil alongado (aponta para +Z).
static func bullet() -> Mesh:
	return _cached("bullet", func() -> Mesh:
		var st := _begin()
		_box(st, Vector3(0.1, 0.1, 0.45), Vector3.ZERO, Color.WHITE)
		return _finish(st))


static func ball() -> Mesh:
	return _cached("ball", func() -> Mesh:
		var st := _begin()
		_sphere(st, 0.18, Vector3.ZERO, Color.WHITE)
		return _finish(st))
