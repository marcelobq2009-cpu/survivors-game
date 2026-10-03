class_name MainMenu
extends Control
## Menu principal (paisagem). JOGAR -> Personagem -> Mapa -> Confirmar -> Partida.
## Mostra versao + commit no rodape (para saber se a build web e a nova).

## Gerado pelo scripts/build-web (nao vai pro git). Se nao existir, mostra "dev".
const BUILD_INFO_PATH := "res://game/build_info.gd"


func _ready() -> void:
	get_tree().paused = false
	UiKit.full_rect(self)
	add_child(MenuBackdrop.new())
	var safe := SafeAreaContainer.new()
	safe.base_margin = 28
	add_child(UiKit.full_rect(safe))
	var row := UiKit.hbox(40)
	safe.add_child(row)
	row.add_child(_build_title())
	row.add_child(_build_buttons())
	Audio.play_music(&"music_menu")


func _build_title() -> Control:
	var col := UiKit.vbox(6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UiKit.spacer(false, true))
	col.add_child(UiKit.label("APOCALIPSE", 84, UiKit.ACCENT))
	col.add_child(UiKit.label("BRASIL", 64, UiKit.TEXT))
	col.add_child(UiKit.label("Capítulo 1: Rio de Janeiro", 26, UiKit.TOXIC))
	col.add_child(UiKit.spacer(false, true))
	var p := Save.profile
	var best := 0.0
	for v: Variant in p.best_time_by_map.values():
		best = maxf(best, float(v))
	var info := UiKit.hbox(28)
	info.add_child(UiKit.label("OURO  %d" % p.gold, 24, UiKit.GOLD))
	info.add_child(UiKit.label("Recorde  %s" % UiKit.time_text(best), 24, UiKit.TEXT))
	info.add_child(UiKit.label("Abates  %d" % p.total_kills, 24, UiKit.MUTED))
	col.add_child(info)
	col.add_child(UiKit.label(version_text(), 18, UiKit.MUTED))
	return col


func _build_buttons() -> Control:
	var col := UiKit.vbox(14)
	col.custom_minimum_size.x = 470
	col.add_child(UiKit.spacer(false, true))
	var play := UiKit.button("JOGAR", Vector2(0, 110), 44, UiKit.TOXIC)
	play.pressed.connect(func() -> void:
		SceneFlow.go_to(SceneFlow.SETUP, {"mode": RunSetup.Mode.NORMAL}))
	col.add_child(play)
	var ranked := UiKit.button("RANQUEADO", Vector2(0, 84), 32)
	ranked.pressed.connect(func() -> void:
		SceneFlow.go_to(SceneFlow.SETUP, {"mode": RunSetup.Mode.RANKED}))
	col.add_child(ranked)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 14)
	grid.add_theme_constant_override(&"v_separation", 14)
	var items: Array = [
		["PERSONAGENS", func() -> void: SceneFlow.go_to(SceneFlow.SETUP, {"view": "characters"})],
		["MAPAS", func() -> void: SceneFlow.go_to(SceneFlow.SETUP, {"view": "maps"})],
		["RANKING", func() -> void: SceneFlow.go_to(SceneFlow.RANKING)],
		["CONQUISTAS", func() -> void: SceneFlow.go_to(SceneFlow.ACHIEVEMENTS)],
	]
	for it: Array in items:
		var b := UiKit.button(it[0] as String, Vector2(228, UiKit.TOUCH_HEIGHT), 22)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(it[1] as Callable)
		grid.add_child(b)
	col.add_child(grid)
	var settings := UiKit.button("CONFIGURAÇÕES", Vector2(0, UiKit.TOUCH_HEIGHT), 22)
	settings.pressed.connect(func() -> void: SceneFlow.go_to(SceneFlow.SETTINGS))
	col.add_child(settings)
	col.add_child(UiKit.spacer(false, true))
	return col


static func version_text() -> String:
	var version: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
	var commit := "dev"
	if ResourceLoader.exists(BUILD_INFO_PATH):
		var info := load(BUILD_INFO_PATH) as GDScript
		if info and info.get_script_constant_map().has("COMMIT"):
			commit = str(info.get_script_constant_map()["COMMIT"])
	return "v%s (%s)" % [version, commit]
