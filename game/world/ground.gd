class_name Ground
extends Node2D
## Chao placeholder: uma grade que acompanha o jogador (da sensacao de movimento).

@export var cell: float = 128.0
@export var line_color: Color = Color(1, 1, 1, 0.06)

var _last_cell: Vector2i = Vector2i(999999, 999999)


func _process(_delta: float) -> void:
	var c := Vector2i((GameState.player_position / cell).floor())
	if c != _last_cell:
		_last_cell = c
		queue_redraw()


func _draw() -> void:
	var half := EnemySpawner.offscreen_radius(get_viewport())
	var center := Vector2(_last_cell) * cell
	var steps := ceili(half / cell) + 1
	for i: int in range(-steps, steps + 1):
		var x := center.x + i * cell
		var y := center.y + i * cell
		draw_line(Vector2(x, center.y - steps * cell), Vector2(x, center.y + steps * cell), line_color, 2.0)
		draw_line(Vector2(center.x - steps * cell, y), Vector2(center.x + steps * cell, y), line_color, 2.0)
