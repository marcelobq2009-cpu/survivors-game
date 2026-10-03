class_name TouchJoystick
extends Control
## Joystick flutuante para toque (paisagem): aparece onde o dedo encosta no
## lado ESQUERDO da tela (60%), fora da faixa do HUD no topo. So reage a TOQUE.
## Em vez de falar com o jogador, ele "aperta" as acoes move_* com forca
## proporcional — o jogador le Input.get_vector como faria com o teclado.

@export var radius: float = 110.0
@export var knob_radius: float = 46.0
@export var dead_zone: float = 0.12
## Fracao da largura da tela (a partir da esquerda) que aceita o joystick.
@export var area_width: float = 0.6
## Faixa do topo reservada para o HUD (botoes).
@export var top_reserved: float = 150.0

var _touch_index: int = -1
var _origin: Vector2
var _knob: Vector2


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var vp := get_viewport_rect().size
		if touch.pressed and _touch_index == -1 and touch.position.x < vp.x * area_width \
				and touch.position.y > top_reserved:
			_touch_index = touch.index
			_origin = touch.position
			_knob = touch.position
			_apply()
		elif not touch.pressed and touch.index == _touch_index:
			_reset()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			# Joystick "segue" o dedo se ele passar do raio (mais confortavel).
			var offset := drag.position - _origin
			if offset.length() > radius:
				_origin = drag.position - offset.normalized() * radius
			_knob = drag.position
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
		Input.action_press(action, minf(1.0, strength))
	else:
		Input.action_release(action)


func _draw() -> void:
	if _touch_index == -1:
		return
	draw_circle(_origin, radius, Color(0, 0, 0, 0.25))
	draw_arc(_origin, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 4.0, true)
	draw_circle(_knob, knob_radius, Color(0.95, 0.55, 0.2, 0.6))
