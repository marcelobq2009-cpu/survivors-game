class_name GameOverScreen
extends CanvasLayer
## Fim de partida (morte ou vitoria): estatisticas + jogar de novo.

const MENU_SCENE := "res://ui/main_menu.tscn"

@onready var title_label: Label = %Title
@onready var stats_label: Label = %Stats
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	Events.run_ended.connect(_on_run_ended)
	retry_button.pressed.connect(_retry)
	menu_button.pressed.connect(_go_to_menu)


func _on_run_ended(victory: bool) -> void:
	title_label.text = "Voce sobreviveu!" if victory else "Fim de jogo"
	stats_label.text = "Tempo: %s\nAbates: %d\nNivel: %d\n\nRecorde: %s  |  %d abates" % [
		UiFormat.time(GameState.elapsed), GameState.kills, GameState.level,
		UiFormat.time(Save.best_time), Save.best_kills]
	show()


func _retry() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
