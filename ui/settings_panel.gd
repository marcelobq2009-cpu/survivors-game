class_name SettingsPanel
extends ScrollContainer
## Painel de configuracoes reutilizavel (tela de Configuracoes e menu de pausa).
## Cada mudanca e aplicada na hora e salva no perfil.

var _settings: GameSettings
var _box: VBoxContainer
var _wipe_armed: bool = false


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings = Save.profile.settings
	_box = UiKit.vbox(10)
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_box)
	_build()


func _build() -> void:
	for c: Node in _box.get_children():
		c.queue_free()
	_section("ÁUDIO")
	_toggle("Música", _settings.music_on, func(v: bool) -> void: _settings.music_on = v)
	_toggle("Efeitos sonoros", _settings.sfx_on, func(v: bool) -> void: _settings.sfx_on = v)
	_slider("Volume geral", _settings.master_volume, func(v: float) -> void: _settings.master_volume = v)
	_slider("Volume da música", _settings.music_volume, func(v: float) -> void: _settings.music_volume = v)
	_slider("Volume dos efeitos", _settings.sfx_volume, func(v: float) -> void: _settings.sfx_volume = v)
	_section("JOGO")
	_name_field()
	_options("Idioma", ["Português (Brasil)", "English (em breve)"], 0,
			func(_i: int) -> void: _settings.language = "pt_BR", [1])
	_toggle("Vibração", _settings.vibration, func(v: bool) -> void: _settings.vibration = v)
	_toggle("Notificações", _settings.notifications, func(v: bool) -> void: _settings.notifications = v)
	_section("GRÁFICOS")
	_options("Qualidade gráfica", ["Baixa (celular fraco)", "Média", "Alta (sombras)"], _settings.quality,
			func(i: int) -> void: _settings.quality = i)
	var restore := UiKit.button("RESTAURAR CONFIGURAÇÕES", Vector2(0, 64), 22)
	restore.pressed.connect(func() -> void:
		var fresh := GameSettings.new()
		Save.profile.settings = fresh
		_settings = fresh
		_changed()
		_build())
	_box.add_child(restore)
	if Config.game.debug_tools_enabled():
		_debug_section()


func _debug_section() -> void:
	_section("DEBUG (desenvolvimento)")
	_toggle("Partidas curtas (%ds) para testar o fim" % roundi(Config.game.debug_match_duration),
			_settings.debug_short_match, func(v: bool) -> void: _settings.debug_short_match = v)
	var unlock := UiKit.button("DESBLOQUEAR TUDO", Vector2(0, 64), 22, UiKit.TOXIC)
	unlock.pressed.connect(func() -> void:
		for c: ContentData in Content.unlockables():
			if not Save.profile.unlocked.has(String(c.id)):
				Save.profile.unlocked.append(String(c.id))
		Save.save_data()
		unlock.text = "TUDO DESBLOQUEADO")
	_box.add_child(unlock)
	var gold := UiKit.button("+500 OURO", Vector2(0, 64), 22, UiKit.GOLD)
	gold.pressed.connect(func() -> void:
		Save.profile.gold += 500
		Save.save_data())
	_box.add_child(gold)
	var wipe := UiKit.button("APAGAR TODO O PROGRESSO", Vector2(0, 64), 22, UiKit.DANGER)
	wipe.pressed.connect(func() -> void:
		if not _wipe_armed:
			_wipe_armed = true
			wipe.text = "TOQUE DE NOVO PARA CONFIRMAR"
			return
		Save.reset_progress()
		_wipe_armed = false
		wipe.text = "PROGRESSO APAGADO")
	_box.add_child(wipe)


func _changed() -> void:
	Audio.apply_settings(_settings)
	GraphicsSettings.apply(get_tree(), _settings)
	Save.apply_runtime_settings()
	Save.save_data()


func _section(title: String) -> void:
	var l := UiKit.label(title, 22, UiKit.ACCENT)
	_box.add_child(l)


func _row(text: String) -> HBoxContainer:
	var row := UiKit.hbox(16)
	row.custom_minimum_size.y = 60
	var l := UiKit.label(text, 22)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	_box.add_child(row)
	return row


func _toggle(text: String, value: bool, setter: Callable) -> void:
	var row := _row(text)
	var cb := CheckButton.new()
	cb.button_pressed = value
	cb.focus_mode = Control.FOCUS_NONE
	cb.scale = Vector2(1.6, 1.6)
	cb.custom_minimum_size = Vector2(70, 40)
	cb.toggled.connect(func(v: bool) -> void:
		setter.call(v)
		_changed())
	row.add_child(cb)


func _slider(text: String, value: float, setter: Callable) -> void:
	var row := _row(text)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(320, 48)
	s.focus_mode = Control.FOCUS_NONE
	s.value_changed.connect(func(v: float) -> void:
		setter.call(v)
		Audio.apply_settings(_settings))
	s.drag_ended.connect(func(_c: bool) -> void: _changed())
	row.add_child(s)


func _options(text: String, items: Array, selected: int, setter: Callable,
		disabled: Array = []) -> void:
	var row := _row(text)
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(320, 56)
	ob.focus_mode = Control.FOCUS_NONE
	for i: int in items.size():
		ob.add_item(items[i] as String, i)
		if disabled.has(i):
			ob.set_item_disabled(i, true)
	ob.select(selected)
	ob.item_selected.connect(func(i: int) -> void:
		setter.call(i)
		_changed())
	row.add_child(ob)


func _name_field() -> void:
	var row := _row("Nome no ranking")
	var le := LineEdit.new()
	le.text = Save.profile.player_name
	le.max_length = 16
	le.custom_minimum_size = Vector2(320, 56)
	le.text_submitted.connect(func(t: String) -> void: _set_name(t))
	le.focus_exited.connect(func() -> void: _set_name(le.text))
	row.add_child(le)


func _set_name(t: String) -> void:
	var clean := t.strip_edges()
	if clean == "" or clean == Save.profile.player_name:
		return
	Save.profile.player_name = clean
	Save.save_data()
