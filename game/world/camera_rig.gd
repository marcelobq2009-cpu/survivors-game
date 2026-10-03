class_name CameraRig
extends Node3D
## Camera isometrica/top-down independente do jogador (estilo "cidade vista de
## cima"). Segue um ponto do chao (por padrao GameState.player_position).
##
## API para eventos (chefes, cutscenes, ataques especiais):
##   shake(forca)                 tremor (tambem via Events.camera_shake_requested)
##   zoom_to(tamanho, segundos)   zoom suave (0 = volta ao zoom padrao)
##   focus_on(ponto, segundos)    olha para outro ponto por um tempo
##   set_follow_target(no3d)      segue um no em vez do jogador

const GROUP := &"camera_rig"

## Angulo horizontal (45 = classico isometrico) e inclinacao para baixo.
@export var yaw_degrees: float = 45.0
@export var pitch_degrees: float = 52.0
@export var distance: float = 60.0
## Zoom = altura visivel em metros (camera ortogonal). Maior = ve mais cidade.
@export var default_zoom: float = 17.0
@export var min_zoom: float = 12.0
@export var max_zoom: float = 40.0
## Suavidade do seguimento (maior = segue mais rapido).
@export var follow_speed: float = 8.0
@export var shake_decay: float = 2.5
@export var max_shake: float = 0.6

var _follow_node: Node3D
var _focus_point: Vector3
var _focus_left: float = 0.0
var _zoom_target: float
var _zoom_speed: float = 0.0
var _shake: float = 0.0
var _anchor: Vector3

@onready var camera: Camera3D = $Camera3D


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = default_zoom
	camera.near = 1.0
	camera.far = 400.0
	_zoom_target = default_zoom
	_anchor = _target_point()
	_apply_transform(_anchor)
	Events.camera_shake_requested.connect(shake)


static func find(tree: SceneTree) -> CameraRig:
	return tree.get_first_node_in_group(GROUP) as CameraRig


func shake(strength: float) -> void:
	_shake = minf(max_shake, _shake + strength * 0.05)


func zoom_to(size: float, seconds: float = 0.6) -> void:
	_zoom_target = clampf(size if size > 0.0 else default_zoom, min_zoom, max_zoom)
	_zoom_speed = absf(_zoom_target - camera.size) / maxf(0.01, seconds)


func focus_on(point: Vector3, seconds: float) -> void:
	_focus_point = point
	_focus_left = seconds


func set_follow_target(node: Node3D) -> void:
	_follow_node = node


## Direcao no chao correspondente ao "para a direita/para cima" da tela.
## Usado para o joystick/teclado andarem relativo a camera.
func screen_to_ground(input: Vector2) -> Vector2:
	var right := GroundPlane.to_2d(camera.global_basis.x).normalized()
	var up := -GroundPlane.to_2d(camera.global_basis.z).normalized()
	return right * input.x - up * input.y


## Raio (no chao) que cobre toda a tela, a partir do centro. Usado pelo spawner
## para nascer zumbis logo fora da tela.
func visible_ground_radius() -> float:
	var vp := get_viewport().get_visible_rect().size
	var h := camera.size
	var w := h * vp.x / maxf(1.0, vp.y)
	var depth := h / maxf(0.2, sin(deg_to_rad(pitch_degrees)))
	return Vector2(w * 0.5, depth * 0.5).length()


func _process(delta: float) -> void:
	var target := _target_point()
	if _focus_left > 0.0:
		_focus_left -= delta
		target = _focus_point
	_anchor = _anchor.lerp(target, minf(1.0, follow_speed * delta))
	if _zoom_speed > 0.0:
		camera.size = move_toward(camera.size, _zoom_target, _zoom_speed * delta)
		if is_equal_approx(camera.size, _zoom_target):
			_zoom_speed = 0.0
	var offset := Vector3.ZERO
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - shake_decay * delta)
		offset = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * _shake
	_apply_transform(_anchor + offset)


func _target_point() -> Vector3:
	if is_instance_valid(_follow_node):
		return _follow_node.global_position
	return GroundPlane.to_3d(GameState.player_position)


func _apply_transform(look_at_point: Vector3) -> void:
	var yaw := deg_to_rad(yaw_degrees)
	var pitch := deg_to_rad(pitch_degrees)
	var back := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	camera.global_position = look_at_point + back * distance
	camera.look_at(look_at_point, Vector3.UP)
