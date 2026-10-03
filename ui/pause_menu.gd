class_name PauseMenu
extends CanvasLayer
## Pausa (Esc ou botao II): CONTINUAR, CONFIGURACOES, REINICIAR, SAIR DA PARTIDA.
## Sair encerra a partida como derrota (o progresso da partida e salvo).

var _root: Control
var _main: VBoxContainer
var _settings_box: VBoxContainer
var _quit_button: Button
var _quit_armed: bool = false


func _ready() -> void:
	layer = 4
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.hide()
	Events.pause_requested.connect(toggle)


func _build() -> void:
	_root = Control.new()
	add_child(UiKit.full_rect(_root))
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	_root.add_child(UiKit.full_rect(dim))
	var center := CenterContainer.new()
	_root.add_child(UiKit.full_rect(center))
	var panel := UiKit.panel()
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	var col := UiKit.vbox(14)
	panel.add_child(col)
	col.add_child(UiKit.label("PAUSADO", 48, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	_main = UiKit.vbox(12)
	col.add_child(_main)
	var resume := UiKit.button("CONTINUAR", Vector2(0, 84), 30, UiKit.TOXIC)
	resume.pressed.connect(toggle)
	_main.add_child(resume)
	var settings := UiKit.button("CONFIGURAÇÕES")
	settings.pressed.connect(_show_settings.bind(true))
	_main.add_child(settings)
	var restart := UiKit.button("REINICIAR")
	restart.pressed.connect(func() -> void:
		GameState.clear_pauses()
		SceneFlow.go_to(SceneFlow.GAME))
	_main.add_child(restart)
	_quit_button = UiKit.button("SAIR DA PARTIDA", Vector2(0, UiKit.TOUCH_HEIGHT), 26, UiKit.DANGER)
	_quit_button.pressed.connect(_on_quit)
	_main.add_child(_quit_button)
	_settings_box = UiKit.vbox(10)
	_settings_box.custom_minimum_size = Vector2(760, 440)
	_settings_box.hide()
	col.add_child(_settings_box)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if _root.visible:
		_root.hide()
		_show_settings(false)
		GameState.release_pause(self)
		Audio.play(&"ui_pause_off")
		Events.game_paused.emit(false)
	elif GameState.is_running and not get_tree().paused:
		_quit_armed = false
		_quit_button.text = "SAIR DA PARTIDA"
		_root.show()
		GameState.request_pause(self)
		Audio.play(&"ui_pause_on")
		Events.game_paused.emit(true)


func _show_settings(show_it: bool) -> void:
	_main.visible = not show_it
	_settings_box.visible = show_it
	for c: Node in _settings_box.get_children():
		c.queue_free()
	if show_it:
		_settings_box.add_child(SettingsPanel.new())
		var back := UiKit.button("VOLTAR")
		back.pressed.connect(_show_settings.bind(false))
		_settings_box.add_child(back)


func _on_quit() -> void:
	if not _quit_armed:
		_quit_armed = true
		_quit_button.text = "TOQUE DE NOVO PARA SAIR"
		return
	_root.hide()
	GameState.release_pause(self)
	var world := World.find(get_tree())
	if world:
		world.abandon()
