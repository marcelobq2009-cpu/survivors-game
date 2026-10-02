class_name Hud
extends CanvasLayer
## HUD: vida, XP, nivel, tempo e abates. So escuta Events / le GameState.

@onready var level_label: Label = %LevelLabel
@onready var time_label: Label = %TimeLabel
@onready var kills_label: Label = %KillsLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var health_bar: ProgressBar = %HealthBar
@onready var pause_button: Button = %PauseButton


func _ready() -> void:
	_style_bar(xp_bar, Color(0.35, 0.8, 1.0))
	_style_bar(health_bar, Color(0.95, 0.3, 0.35))
	Events.xp_changed.connect(_on_xp_changed)
	Events.player_health_changed.connect(_on_health_changed)
	pause_button.pressed.connect(Events.pause_requested.emit)


func _process(_delta: float) -> void:
	time_label.text = UiFormat.time(GameState.elapsed)
	kills_label.text = "%d abates" % GameState.kills


func _on_xp_changed(current: int, needed: int, level: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = current
	level_label.text = "Nv %d" % level


func _on_health_changed(current: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = current


func _style_bar(bar: ProgressBar, color: Color) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(6)
	bar.add_theme_stylebox_override(&"fill", fill)
