class_name TouchJoystick
extends Control
## Joystick flutuante para toque: aparece onde o dedo encosta na metade de
## baixo da tela. So reage a eventos de TOQUE (no PC com mouse nao aparece).
## Em vez de falar com o jogador, ele "aperta" as acoes move_* com forca
## proporcional — o jogador le Input.get_vector como faria com o teclado.

@export var radius: float = 120.0
@export var knob_radius: float = 50.0
@export var dead_zone: float = 0.15

var _touch_index: int = -1
var _origin: Vector2
var _knob: Vector2


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1 and touch.position.y > get_viewport_rect().size.y * 0.5:
			_touch_index = touch.index
			_origin = touch.position
			_knob = touch.position
			_apply()
		elif not touch.pressed and touch.index == _touch_index:
			_reset()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_knob = _origin + (drag.position - _origin).limit_length(radius)
			_apply()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		_reset()


func _apply() -> void:
	var v := (_knob - _origin) / radius
	if v.length() < dead_zone:
		v = Vector2.ZERO
	_set_action(&"move_left", maxf(0.0, -v.x))
	_set_action(&"move_right", maxf(0.0, v.x))
	_set_action(&"move_up", maxf(0.0, -v.y))
	_set_action(&"move_down", maxf(0.0, v.y))
	queue_redraw()


func _reset() -> void:
	if _touch_index == -1:
		return
	_touch_index = -1
	for a: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(a)
	queue_redraw()


func _set_action(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _draw() -> void:
	if _touch_index == -1:
		return
	draw_circle(_origin, radius, Color(1, 1, 1, 0.12))
	draw_arc(_origin, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 4.0, true)
	draw_circle(_knob, knob_radius, Color(1, 1, 1, 0.45))
