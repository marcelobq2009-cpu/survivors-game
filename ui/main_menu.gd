class_name MainMenu
extends Control
## Menu inicial: jogar, recordes e versao + commit (para saber se a build e nova).

const WORLD_SCENE := "res://game/world/world.tscn"
## Gerado pelo scripts/build-web (nao vai pro git). Se nao existir, mostra "dev".
const BUILD_INFO_PATH := "res://game/build_info.gd"

@onready var play_button: Button = %PlayButton
@onready var best_label: Label = %BestLabel
@onready var version_label: Label = %VersionLabel


func _ready() -> void:
	get_tree().paused = false
	play_button.pressed.connect(_play)
	best_label.text = "Recorde: %s  |  %d abates" % [UiFormat.time(Save.best_time), Save.best_kills]
	version_label.text = version_text()


func _play() -> void:
	get_tree().change_scene_to_file(WORLD_SCENE)


static func version_text() -> String:
	var version: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
	var commit := "dev"
	if ResourceLoader.exists(BUILD_INFO_PATH):
		var info := load(BUILD_INFO_PATH) as GDScript
		if info and info.get_script_constant_map().has("COMMIT"):
			commit = str(info.get_script_constant_map()["COMMIT"])
	return "v%s (%s)" % [version, commit]
