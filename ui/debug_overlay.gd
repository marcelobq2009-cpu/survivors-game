class_name DebugOverlay
extends CanvasLayer
## Overlay de performance: FPS, zumbis, projeteis, gemas, draw calls e nos.
## Liga/desliga com F3 ou tocando com 3 dedos ao mesmo tempo.

const REFRESH := 0.25

var _touches: Dictionary[int, bool] = {}
var _refresh_left: float = 0.0
var _label: Label


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = UiKit.label("", 20, UiKit.TOXIC)
	_label.position = Vector2(20, 210)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	visible = false


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
	var tree := get_tree()
	var enemies := EnemyManager.find(tree)
	var projectiles := ProjectileManager.find(tree)
	var pickups := PickupManager.find(tree)
	_label.text = "FPS: %d\nZumbis: %d\nProjéteis: %d\nGemas: %d\nDraw calls: %d\nNós: %d" % [
		Engine.get_frames_per_second(),
		enemies.count() if enemies else 0,
		projectiles.count() if projectiles else 0,
		pickups.gem_count() if pickups else 0,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
	]
