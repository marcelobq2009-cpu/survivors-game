class_name DebugOverlay
extends CanvasLayer
## Overlay de debug: FPS, inimigos, projeteis, gemas e draw calls.
## Liga/desliga com F3 ou tocando com 3 dedos ao mesmo tempo.

const PROJECTILE_SCENE: PackedScene = preload("res://game/weapons/projectile.tscn")
const GEM_SCENE: PackedScene = preload("res://game/pickups/xp_gem.tscn")
const REFRESH := 0.25

var _touches: Dictionary[int, bool] = {}
var _refresh_left: float = 0.0
var _enemies: EnemyManager

@onready var label: Label = %Info


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_enemies = EnemyManager.find(get_tree())


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_toggle"):
		visible = not visible
	elif event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touches[t.index] = true
			if _touches.size() == 3:
				visible = not visible
		else:
			_touches.erase(t.index)


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_left -= delta
	if _refresh_left > 0.0:
		return
	_refresh_left = REFRESH
	label.text = "FPS: %d\nInimigos: %d\nProjeteis: %d\nGemas: %d\nDraw calls: %d\nNos: %d" % [
		Engine.get_frames_per_second(),
		_enemies.count() if _enemies else 0,
		Pool.active_count(PROJECTILE_SCENE),
		Pool.active_count(GEM_SCENE),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
	]
