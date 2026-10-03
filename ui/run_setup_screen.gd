class_name RunSetupScreen
extends UiScreen
## Selecao antes da partida: PERSONAGEM -> MAPA -> CONFIRMAR -> partida.
## Tambem serve de galeria (menu PERSONAGENS / MAPAS, sem iniciar partida).
## Parametros (SceneFlow.params):
##   mode: RunSetup.Mode (NORMAL/RANKED)   view: "play" | "characters" | "maps"

enum Step { CHARACTER, MAP, CONFIRM }

var _mode: RunSetup.Mode = RunSetup.Mode.NORMAL
var _view: String = "play"
var _step: Step = Step.CHARACTER
var _character: CharacterData
var _map: MapData
var _cards_row: HBoxContainer
var _details: VBoxContainer
var _steps_label: Label
var _next_button: Button
var _group := ButtonGroup.new()


func _init() -> void:
	super("Jogar")


func build_content() -> void:
	_mode = SceneFlow.params.get("mode", RunSetup.Mode.NORMAL)
	_view = SceneFlow.params.get("view", "play")
	_step = Step.MAP if _view == "maps" else Step.CHARACTER
	_character = _first_unlocked(Content.characters, Save.profile.last_character_id) as CharacterData
	_map = _first_unlocked(Content.maps, Save.profile.last_map_id) as MapData
	_steps_label = UiKit.label("", 24, UiKit.MUTED)
	header_right.add_child(_steps_label)
	show_gold()

	var body := UiKit.hbox(20)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_cards_row = UiKit.hbox(16)
	_cards_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	scroll.add_child(_cards_row)
	var detail_panel := UiKit.panel()
	detail_panel.custom_minimum_size = Vector2(400, 0)
	body.add_child(detail_panel)
	_details = UiKit.vbox(10)
	detail_panel.add_child(_details)

	var footer := UiKit.hbox(16)
	footer.add_child(UiKit.spacer())
	_next_button = UiKit.button("PRÓXIMO", Vector2(320, 84), 30, UiKit.TOXIC)
	_next_button.pressed.connect(_on_next)
	footer.add_child(_next_button)
	content.add_child(footer)
	_show_step()


func go_back() -> void:
	if _view == "play" and _step != Step.CHARACTER:
		_step = (_step - 1) as Step
		_show_step()
	else:
		SceneFlow.go_to(SceneFlow.MENU)


func _show_step() -> void:
	for c: Node in _cards_row.get_children():
		c.queue_free()
	var title := "RANQUEADO" if _mode == RunSetup.Mode.RANKED else "JOGAR"
	match _view:
		"characters":
			title = "PERSONAGENS"
		"maps":
			title = "MAPAS"
	var parts: PackedStringArray = []
	if _view == "play":
		for i: int in 3:
			var step_name: String = ["Personagem", "Mapa", "Confirmar"][i]
			parts.append(("[%d %s]" if i == _step else "%d %s") % [i + 1, step_name])
	title_label.text = title
	_steps_label.text = "  ›  ".join(parts)
	_next_button.visible = _view == "play"
	match _step:
		Step.CHARACTER:
			for c: CharacterData in Content.characters:
				_add_card(c, c == _character)
			_show_character_details(_character)
			_next_button.text = "PRÓXIMO"
		Step.MAP:
			for m: MapData in Content.maps:
				_add_card(m, m == _map)
			_show_map_details(_map)
			_next_button.text = "PRÓXIMO"
		Step.CONFIRM:
			_show_confirm()
			_next_button.text = "INICIAR"
	_update_next()


func _add_card(c: ContentData, selected: bool) -> void:
	var card := ContentCard.new()
	card.setup(c, ProgressService.is_unlocked(c, Save.profile))
	card.button_group = _group
	card.button_pressed = selected
	card.pressed.connect(_on_card_pressed.bind(c))
	_cards_row.add_child(card)


func _on_card_pressed(c: ContentData) -> void:
	if c is CharacterData:
		_show_character_details(c as CharacterData)
		if ProgressService.is_unlocked(c, Save.profile):
			_character = c as CharacterData
	elif c is MapData:
		_show_map_details(c as MapData)
		if ProgressService.is_unlocked(c, Save.profile):
			_map = c as MapData
	_update_next()


func _update_next() -> void:
	match _step:
		Step.CHARACTER:
			_next_button.disabled = _character == null
		Step.MAP:
			_next_button.disabled = _map == null
		_:
			_next_button.disabled = false


func _on_next() -> void:
	if _step == Step.CONFIRM:
		var setup := RunSetup.new()
		setup.mode = _mode
		setup.character = _character
		setup.map = _map
		GameState.setup = setup
		Save.profile.last_character_id = String(_character.id)
		Save.profile.last_map_id = String(_map.id)
		Save.save_data()
		SceneFlow.start_run()
		return
	_step = (_step + 1) as Step
	_show_step()


# --- Painel de detalhes -------------------------------------------------------

func _clear_details() -> void:
	for c: Node in _details.get_children():
		c.queue_free()


func _show_character_details(c: CharacterData) -> void:
	_clear_details()
	if c == null:
		return
	_details.add_child(UiKit.label(c.display_name.to_upper(), 34, c.color.lightened(0.2)))
	_details.add_child(UiKit.wrap_label(c.description, 20, UiKit.TEXT))
	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override(&"h_separation", 24)
	for row: Array in [["Vida", "%d" % c.max_health], ["Velocidade", "%.1f" % c.move_speed],
			["Armadura", "%d" % c.armor], ["Regeneração", "%.1f/s" % c.regen],
			["Crítico", "%d%%" % roundi(c.crit_chance * 100)],
			["Arma inicial", c.starting_weapon.display_name if c.starting_weapon else "-"]]:
		stats.add_child(UiKit.label(row[0] as String, 20, UiKit.MUTED))
		stats.add_child(UiKit.label(row[1] as String, 20, UiKit.TEXT))
	_details.add_child(stats)
	if c.passive_name != "":
		_details.add_child(UiKit.label("Passiva: " + c.passive_name, 22, UiKit.TOXIC))
		_details.add_child(UiKit.wrap_label(c.passive_description, 18))
	if c.ability_name != "":
		_details.add_child(UiKit.label("Habilidade: " + c.ability_name, 22, UiKit.ACCENT))
	_add_lock_info(c)


func _show_map_details(m: MapData) -> void:
	_clear_details()
	if m == null:
		return
	_details.add_child(UiKit.label(m.display_name.to_upper(), 34, m.color.lightened(0.2)))
	_details.add_child(UiKit.wrap_label(m.description, 20, UiKit.TEXT))
	_details.add_child(UiKit.label("Dificuldade: %d/5" % m.difficulty, 20, UiKit.MUTED))
	var best := float(Save.profile.best_time_by_map.get(String(m.id), 0.0))
	_details.add_child(UiKit.label("Seu recorde: %s" % UiKit.time_text(best), 20, UiKit.MUTED))
	if not m.coming_soon:
		var dur := "Sem limite" if _mode == RunSetup.Mode.RANKED else UiKit.time_text(m.effective_duration())
		_details.add_child(UiKit.label("Duração: %s" % dur, 20, UiKit.MUTED))
	_add_lock_info(m)


func _add_lock_info(c: ContentData) -> void:
	if c.coming_soon:
		_details.add_child(UiKit.label("EM BREVE", 24, UiKit.ACCENT))
		return
	if ProgressService.is_unlocked(c, Save.profile):
		return
	_details.add_child(UiKit.label("BLOQUEADO", 24, UiKit.DANGER))
	for r: UnlockRequirement in c.unlock_requirements:
		_details.add_child(UiKit.wrap_label(r.describe(), 20, UiKit.TEXT))
		var bar := UiKit.bar(UiKit.ACCENT, 12)
		bar.max_value = 1.0
		bar.value = r.progress(Save.profile)
		_details.add_child(bar)


func _show_confirm() -> void:
	_clear_details()
	var summary := UiKit.vbox(16)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(UiKit.label("PRONTO PARA SOBREVIVER?", 40, UiKit.TOXIC))
	var ranked := _mode == RunSetup.Mode.RANKED
	summary.add_child(UiKit.label("Modo: %s" % ("Ranqueado (sem limite de tempo)" if ranked else "Normal"), 26))
	summary.add_child(UiKit.label("Personagem: %s" % _character.display_name, 26))
	summary.add_child(UiKit.label("Mapa: %s" % _map.display_name, 26))
	var goal := "Sobreviva o máximo que conseguir. A dificuldade nunca para de subir." if ranked \
			else "Sobreviva %d minutos." % roundi(_map.effective_duration() / 60.0)
	summary.add_child(UiKit.wrap_label(goal, 22, UiKit.TEXT))
	_cards_row.add_child(summary)
	_details.add_child(UiKit.badge(_character.display_name.left(1), _character.color, 120))
	_details.add_child(UiKit.label(_character.display_name, 28))
	_details.add_child(UiKit.label("em " + _map.display_name, 24, _map.color))


func _first_unlocked(list: Array, preferred_id: String) -> ContentData:
	var first: ContentData = null
	for c: ContentData in list:
		if not ProgressService.is_unlocked(c, Save.profile):
			continue
		if String(c.id) == preferred_id:
			return c
		if first == null:
			first = c
	return first
