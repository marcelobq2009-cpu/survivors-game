class_name InstanceRenderer
extends MultiMeshInstance3D
## Desenha MUITAS copias de uma malha numa unica chamada (MultiMesh).
## Uso por frame:  begin() -> add(...) para cada objeto -> finish()
## Cada copia tem posicao, giro em Y, escala, cor e 4 numeros extras
## ("custom", lidos no shader: ex. flash de dano, brilho de elite).

const STRIDE := 20  # 12 (transformacao) + 4 (cor) + 4 (custom)

var _buffer := PackedFloat32Array()
var _count: int = 0
var _capacity: int = 0


func setup(mesh: Mesh, material: Material, capacity: int = 64, shadows: bool = false) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = mesh
	multimesh = mm
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Os objetos ficam sempre perto do jogador: nao precisa de culling por instancia.
	custom_aabb = AABB(Vector3(-2000, -50, -2000), Vector3(4000, 200, 4000))
	_resize(maxi(8, capacity))
	mm.visible_instance_count = 0


func begin() -> void:
	_count = 0


func add(pos: Vector3, yaw: float, scale: float, color: Color, custom: Color = Color(0, 0, 0, 0)) -> void:
	if _count >= _capacity:
		_resize(_capacity * 2)
	var i := _count * STRIDE
	var c := cos(yaw) * scale
	var s := sin(yaw) * scale
	_buffer[i] = c
	_buffer[i + 1] = 0.0
	_buffer[i + 2] = s
	_buffer[i + 3] = pos.x
	_buffer[i + 4] = 0.0
	_buffer[i + 5] = scale
	_buffer[i + 6] = 0.0
	_buffer[i + 7] = pos.y
	_buffer[i + 8] = -s
	_buffer[i + 9] = 0.0
	_buffer[i + 10] = c
	_buffer[i + 11] = pos.z
	_buffer[i + 12] = color.r
	_buffer[i + 13] = color.g
	_buffer[i + 14] = color.b
	_buffer[i + 15] = color.a
	_buffer[i + 16] = custom.r
	_buffer[i + 17] = custom.g
	_buffer[i + 18] = custom.b
	_buffer[i + 19] = custom.a
	_count += 1


func finish() -> void:
	multimesh.buffer = _buffer
	multimesh.visible_instance_count = _count


func count() -> int:
	return _count


func _resize(n: int) -> void:
	_capacity = n
	multimesh.instance_count = n
	_buffer.resize(n * STRIDE)
