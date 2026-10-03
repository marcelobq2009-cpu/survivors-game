extends CanvasLayer
## Navegacao entre telas (autoload "SceneFlow"), com transicao de fade.
## Tambem mostra o aviso "gire o celular" quando a tela esta em pe (o jogo e
## em paisagem).
##
## Uso: SceneFlow.go_to(SceneFlow.MENU)
##      SceneFlow.go_to(SceneFlow.SETUP, {"mode": RunSetup.Mode.RANKED})
## A tela nova le os parametros em SceneFlow.params.

const MENU := "res://ui/main_menu.tscn"
const SETUP := "res://ui/run_setup_screen.tscn"
const RANKING := "res://ui/ranking_screen.tscn"
const ACHIEVEMENTS := "res://ui/achievements_screen.tscn"
const SETTINGS := "res://ui/settings_screen.tscn"
const UPGRADES := "res://ui/upgrades_screen.tscn"
const GAME := "res://game/world/world.tscn"
const FADE_TIME := 0.18

var params: Dictionary = {}
var _fade: ColorRect
var _rotate_hint: Control
var _busy: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.full_rect(_fade)
	add_child(_fade)
	_build_rotate_hint()
	get_viewport().size_changed.connect(_update_rotate_hint)
	_update_rotate_hint()
	GraphicsSettings.apply(get_tree(), Save.profile.settings)


func go_to(path: String, p_params: Dictionary = {}) -> void:
	if _busy:
		return
	_busy = true
	params = p_params
	Audio.play(&"ui_transition")
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await tw.finished
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, FADE_TIME)
	await tw2.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


## Comeca uma partida com as escolhas atuais de GameState.setup.
func start_run() -> void:
	go_to(GAME)


func _build_rotate_hint() -> void:
	_rotate_hint = ColorRect.new()
	(_rotate_hint as ColorRect).color = Color(0.04, 0.04, 0.05, 0.97)
	UiKit.full_rect(_rotate_hint)
	var center := CenterContainer.new()
	UiKit.full_rect(center)
	var box := UiKit.vbox(18)
	box.add_child(UiKit.label("Gire o celular", 40, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UiKit.label("O jogo é na horizontal", 24, UiKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	center.add_child(box)
	_rotate_hint.add_child(center)
	_rotate_hint.hide()
	add_child(_rotate_hint)


func _update_rotate_hint() -> void:
	var s := DisplayServer.window_get_size()
	_rotate_hint.visible = s.y > s.x * 1.05
