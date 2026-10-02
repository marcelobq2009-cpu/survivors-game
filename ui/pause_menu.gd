class_name PauseMenu
extends CanvasLayer
## Menu de pausa (Esc ou botao II do HUD).

const MENU_SCENE := "res://ui/main_menu.tscn"

@onready var resume_button: Button = %ResumeButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	Events.pause_requested.connect(_toggle)
	resume_button.pressed.connect(_toggle)
	menu_button.pressed.connect(_go_to_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	if visible:
		hide()
		get_tree().paused = false
		Events.game_paused.emit(false)
	elif GameState.is_running and not get_tree().paused:
		# So pausa se nada mais (level-up, game over) ja pausou o jogo.
		show()
		get_tree().paused = true
		Events.game_paused.emit(true)


func _go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
