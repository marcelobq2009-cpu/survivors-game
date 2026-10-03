class_name Hud
extends CanvasLayer
## HUD da partida (paisagem, minimalista). So escuta Events / le GameState.
## Topo: barra de XP. Esquerda: vida, nivel, armas. Centro: tempo, chefe,
## avisos. Direita: abates, ouro, pausa (e DBG no modo de teste).

var _xp_bar: ProgressBar
var _hp_bar: ProgressBar
var _hp_label: Label
var _level_label: Label
var _time_label: Label
var _mode_label: Label
var _kills_label: Label
var _gold_label: Label
var _weapons_row: HBoxContainer
var _boss_box: VBoxContainer
var _boss_bar: ProgressBar
var _boss_name: Label
var _announce: Label
var _low_hp: ColorRect
var _announce_queue: Array[Array] = []
var _announce_busy: bool = false
var _hp_ratio: float = 1.0
var _boss_poll: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	layer = 1
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UiKit.full_rect(root))
	_low_hp = ColorRect.new()
	_low_hp.color = Color(0.8, 0.0, 0.0, 0.0)
	_low_hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(UiKit.full_rect(_low_hp))
	root.add_child(UiKit.full_rect(TouchJoystick.new()))

	_xp_bar = UiKit.bar(Color(0.35, 0.85, 1.0), 12)
	_xp_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_xp_bar.offset_bottom = 12
	root.add_child(_xp_bar)

	var safe := SafeAreaContainer.new()
	safe.base_margin = 16
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(UiKit.full_rect(safe))
	var top := UiKit.hbox(16)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	safe.add_child(top)
	top.add_child(_build_left())
	top.add_child(_build_center())
	top.add_child(_build_right())

	_announce = UiKit.label("", 46, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	_announce.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_announce.offset_top = 190
	_announce.offset_left = -600
	_announce.offset_right = 600
	_announce.modulate.a = 0.0
	root.add_child(_announce)

	Events.xp_changed.connect(_on_xp_changed)
	Events.player_health_changed.connect(_on_health_changed)
	Events.weapons_changed.connect(_refresh_weapons)
	Events.announcement.connect(_queue_announcement)
	Events.level_up.connect(func(l: int) -> void: _queue_announcement("NÍVEL %d!" % l, UiKit.TOXIC))
	Events.gold_collected.connect(func(_g: int) -> void: _pulse(_gold_label))
	_mode_label.text = "RANQUEADO" if GameState.setup.is_ranked() else ""


func _build_left() -> Control:
	var col := UiKit.vbox(6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.custom_minimum_size.x = 360
	var row := UiKit.hbox(10)
	_level_label = UiKit.label("Nv 1", 28, UiKit.TOXIC)
	row.add_child(_level_label)
	_hp_label = UiKit.label("100", 20, UiKit.TEXT)
	row.add_child(_hp_label)
	col.add_child(row)
	_hp_bar = UiKit.bar(UiKit.DANGER, 18)
	col.add_child(_hp_bar)
	_weapons_row = UiKit.hbox(6)
	col.add_child(_weapons_row)
	return col


func _build_center() -> Control:
	var col := UiKit.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_time_label = UiKit.label("00:00", 44, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_time_label)
	_mode_label = UiKit.label("", 18, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_mode_label)
	_boss_box = UiKit.vbox(2)
	_boss_box.visible = false
	_boss_name = UiKit.label("", 22, UiKit.DANGER, HORIZONTAL_ALIGNMENT_CENTER)
	_boss_box.add_child(_boss_name)
	_boss_bar = UiKit.bar(UiKit.DANGER, 16)
	_boss_bar.custom_minimum_size.x = 420
	_boss_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_boss_box.add_child(_boss_bar)
	col.add_child(_boss_box)
	return col


func _build_right() -> Control:
	var col := UiKit.vbox(6)
	col.custom_minimum_size.x = 360
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := UiKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_END
	if Config.game.debug_tools_enabled():
		var dbg := UiKit.button("DBG", Vector2(76, 72), 20, UiKit.TOXIC)
		dbg.pressed.connect(func() -> void: DebugPanel.find(get_tree()).toggle())
		row.add_child(dbg)
	var pause := UiKit.button("II", Vector2(84, 72), 30)
	pause.pressed.connect(Events.pause_requested.emit)
	row.add_child(pause)
	col.add_child(row)
	_kills_label = UiKit.label("0 abates", 22, UiKit.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	col.add_child(_kills_label)
	_gold_label = UiKit.label("OURO 0", 22, UiKit.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	col.add_child(_gold_label)
	return col


func _process(delta: float) -> void:
	_time += delta
	var dur := GameState.setup.duration()
	_time_label.text = UiKit.time_text(GameState.elapsed) if dur <= 0.0 \
			else "%s / %s" % [UiKit.time_text(GameState.elapsed), UiKit.time_text(dur)]
	_kills_label.text = "%d abates" % GameState.kills
	_gold_label.text = "OURO %d" % GameState.gold
	# Vida baixa: tela avermelhada pulsando.
	var danger := clampf((0.3 - _hp_ratio) / 0.3, 0.0, 1.0)
	_low_hp.color.a = danger * (0.12 + 0.08 * sin(_time * 6.0))
	_boss_poll -= delta
	if _boss_poll <= 0.0:
		_boss_poll = 0.15
		_update_boss()


func _update_boss() -> void:
	var manager := EnemyManager.find(get_tree())
	var boss: EnemyAgent = manager.current_boss() if manager else null
	_boss_box.visible = boss != null
	if boss:
		_boss_name.text = boss.data.display_name.to_upper()
		_boss_bar.max_value = boss.max_hp
		_boss_bar.value = boss.hp


func _on_xp_changed(current: int, needed: int, level: int) -> void:
	_xp_bar.max_value = needed
	_xp_bar.value = current
	_level_label.text = "Nv %d" % level


func _on_health_changed(current: float, max_value: float) -> void:
	_hp_bar.max_value = max_value
	_hp_bar.value = current
	_hp_label.text = "%d / %d" % [ceili(current), roundi(max_value)]
	_hp_ratio = current / maxf(1.0, max_value)


func _refresh_weapons() -> void:
	for c: Node in _weapons_row.get_children():
		c.queue_free()
	var player := Player.find(get_tree())
	if player == null:
		return
	for id: StringName in GameState.owned_weapons:
		var w: Weapon = player.weapons.get(id)
		if w == null:
			continue
		var slot := UiKit.badge(w.data.display_name.left(1), w.data.color, 46)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lvl := UiKit.label(str(GameState.weapon_level(id)), 14, UiKit.TEXT)
		lvl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		slot.add_child(lvl)
		_weapons_row.add_child(slot)


func _queue_announcement(text: String, color: Color) -> void:
	_announce_queue.append([text, color])
	if not _announce_busy:
		_show_next_announcement()


func _show_next_announcement() -> void:
	if _announce_queue.is_empty():
		_announce_busy = false
		return
	_announce_busy = true
	var item: Array = _announce_queue.pop_front()
	_announce.text = item[0]
	_announce.add_theme_color_override(&"font_color", item[1] as Color)
	_announce.scale = Vector2(1.3, 1.3)
	_announce.pivot_offset = _announce.size * 0.5
	var tw := create_tween()
	tw.tween_property(_announce, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(_announce, "scale", Vector2.ONE, 0.2)
	tw.tween_interval(1.4)
	tw.tween_property(_announce, "modulate:a", 0.0, 0.3)
	tw.tween_callback(_show_next_announcement)


func _pulse(c: Control) -> void:
	c.pivot_offset = c.size * 0.5
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2(1.2, 1.2), 0.06)
	tw.tween_property(c, "scale", Vector2.ONE, 0.1)
