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
	_box = UiKit.vbox(8)
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_box)
	_build()


func _build() -> void:
	for c: Node in _box.get_children():
		c.queue_free()
	var s := _settings
	_section("ÁUDIO")
	_toggle("Silenciar tudo", s.mute_all, func(v: bool) -> void: s.mute_all = v)
	_toggle("Música", s.music_on, func(v: bool) -> void: s.music_on = v)
	_toggle("Efeitos sonoros", s.sfx_on, func(v: bool) -> void: s.sfx_on = v)
	_slider("Volume geral", s.master_volume, func(v: float) -> void: s.master_volume = v)
	_slider("Música", s.music_volume, func(v: float) -> void: s.music_volume = v)
	_slider("Efeitos (armas, impactos)", s.sfx_volume, func(v: float) -> void: s.sfx_volume = v)
	_slider("Ambiente (cidade, praia, morro)", s.ambience_volume, func(v: float) -> void: s.ambience_volume = v)
	_slider("Zumbis", s.zombies_volume, func(v: float) -> void: s.zombies_volume = v)
	_slider("Interface", s.ui_volume, func(v: float) -> void: s.ui_volume = v)
	_slider("Chefes", s.bosses_volume, func(v: float) -> void: s.bosses_volume = v)
	_slider("Alertas de perigo", s.alerts_volume, func(v: float) -> void: s.alerts_volume = v)
	var test := UiKit.button("TESTAR ÁUDIO", Vector2(0, 64), 22, UiKit.TOXIC)
	test.pressed.connect(func() -> void: Audio.test_sequence())
	_box.add_child(test)

	_section("ACESSIBILIDADE")
	_toggle("Legendas para alertas importantes", s.captions, func(v: bool) -> void: s.captions = v)
	_toggle("Setas para ameaças fora da tela", s.threat_indicators,
			func(v: bool) -> void: s.threat_indicators = v)
	_toggle("Áudio mono", s.mono_audio, func(v: bool) -> void: s.mono_audio = v)
	_toggle("Reduzir sons intensos", s.reduce_intense, func(v: bool) -> void: s.reduce_intense = v)
	_toggle("Aumentar alertas de perigo", s.boost_alerts, func(v: bool) -> void: s.boost_alerts = v)
	_toggle("Música mais baixa durante o combate", s.reduce_music_in_combat,
			func(v: bool) -> void: s.reduce_music_in_combat = v)
	_toggle("Vibração", s.vibration, func(v: bool) -> void: s.vibration = v)

	_section("JOGO")
	_name_field()
	_options("Idioma", ["Português (Brasil)", "English (em breve)"], 0,
			func(_i: int) -> void: s.language = "pt_BR", [1])
	_toggle("Notificações", s.notifications, func(v: bool) -> void: s.notifications = v)

	_section("GRÁFICOS E DESEMPENHO")
	_options("Qualidade gráfica", ["Baixa (celular fraco)", "Média", "Alta (sombras)"], s.quality,
			func(i: int) -> void: s.quality = i)
	_options("Limite de FPS", ["30 (economiza bateria)", "60"], 0 if s.fps_limit == 30 else 1,
			func(i: int) -> void: s.fps_limit = 30 if i == 0 else 60)
	_toggle("Partículas reduzidas", s.reduced_particles, func(v: bool) -> void: s.reduced_particles = v)
	_options("Quantidade de zumbis", ["Reduzida (celular fraco)", "Normal"],
			0 if s.enemy_density < 0.99 else 1, func(i: int) -> void: s.enemy_density = 0.6 if i == 0 else 1.0)
	_slider("Zoom da câmera (ver mais cidade)", inverse_lerp(0.8, 1.3, s.camera_zoom),
			func(v: float) -> void: s.camera_zoom = lerpf(0.8, 1.3, v))

	var restore := UiKit.button("RESTAURAR CONFIGURAÇÕES PADRÃO", Vector2(0, 64), 22)
	restore.pressed.connect(func() -> void:
		var fresh := GameSettings.new()
		fresh.debug_unlocked = _settings.debug_unlocked
		Save.profile.settings = fresh
		_settings = fresh
		_changed()
		_build())
	_box.add_child(restore)
	_about_section()
	if Config.game.debug_tools_enabled():
		_debug_section()


## Creditos e licencas (obrigatorio: aviso da licenca MIT do Godot Engine).
func _about_section() -> void:
	_section("SOBRE O JOGO")
	var about := "%s  •  %s
Arte 3D, músicas e efeitos sonoros: originais, criados por código para este jogo.
Feito com Godot Engine (licença MIT) — godotengine.org" % [
		ProjectSettings.get_setting("application/config/name", ""), MainMenu.version_text()]
	_box.add_child(UiKit.wrap_label(about, 18, UiKit.MUTED))
	var lic := UiKit.button("LICENÇA DO GODOT ENGINE", Vector2(0, 60), 20)
	var text := UiKit.wrap_label(Engine.get_license_text(), 14, UiKit.MUTED)
	text.hide()
	lic.pressed.connect(func() -> void: text.visible = not text.visible)
	_box.add_child(lic)
	_box.add_child(text)


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
			wipe.text = "TEM CERTEZA? TOQUE DE NOVO PARA APAGAR"
			return
		Save.reset_progress()
		_wipe_armed = false
		wipe.text = "PROGRESSO APAGADO")
	_box.add_child(wipe)
	var hide_dbg := UiKit.button("ESCONDER FERRAMENTAS DE DEBUG", Vector2(0, 64), 22)
	hide_dbg.pressed.connect(func() -> void:
		_settings.debug_unlocked = false
		_changed()
		_build())
	_box.add_child(hide_dbg)


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
	row.custom_minimum_size.y = 58
	var l := UiKit.label(text, 22)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
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
		Audio.play(&"ui_select")
		_changed())
	row.add_child(cb)


func _slider(text: String, value: float, setter: Callable) -> void:
	var row := _row(text)
	var pct := UiKit.label("%d%%" % roundi(value * 100), 20, UiKit.MUTED)
	pct.custom_minimum_size.x = 64
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(300, 48)
	s.focus_mode = Control.FOCUS_NONE
	s.value_changed.connect(func(v: float) -> void:
		setter.call(v)
		pct.text = "%d%%" % roundi(v * 100)
		Audio.apply_settings(_settings))
	s.drag_ended.connect(func(_c: bool) -> void:
		Audio.play(&"ui_click")
		_changed())
	row.add_child(s)
	row.add_child(pct)


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
		Audio.play(&"ui_select")
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
