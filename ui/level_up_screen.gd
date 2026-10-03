class_name LevelUpScreen
extends CanvasLayer
## Tela de level-up (e de bau): pausa o jogo e mostra ate 3 cartas sorteadas.
## Varios niveis de uma vez = uma tela por nivel. Bau = mesma tela, outro titulo.

const CHOICES := 3
## Evita que um toque "atrasado" escolha uma carta sem querer.
const INPUT_DELAY := 0.4
const CARD_SIZE := Vector2(330, 360)
const TAG_NAMES: Dictionary = {
	&"dano": "DANO", &"cadencia": "CADÊNCIA", &"critico": "CRÍTICO", &"area": "ÁREA",
	&"projeteis": "PROJÉTEIS", &"defesa": "DEFESA", &"utilidade": "UTILIDADE",
	&"arma": "NOVA ARMA", &"evolucao": "EVOLUÇÃO", &"reserva": "EXTRA",
}

var _all_upgrades: Array[UpgradeData] = []
var _queue: Array[String] = []  # "level" ou "chest"
var _scheduled: bool = false  # evita abrir varias telas no mesmo frame
var _rng := RandomNumberGenerator.new()
var _root: Control
var _title: Label
var _subtitle: Label
var _cards: HBoxContainer


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_all_upgrades = UpgradeLibrary.load_all()
	_rng.randomize()
	_build()
	_root.hide()
	Events.level_up.connect(func(_l: int) -> void: _enqueue("level"))
	Events.chest_opened.connect(func() -> void: _enqueue("chest"))


func _build() -> void:
	_root = Control.new()
	add_child(UiKit.full_rect(_root))
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	_root.add_child(UiKit.full_rect(dim))
	var center := CenterContainer.new()
	_root.add_child(UiKit.full_rect(center))
	var col := UiKit.vbox(18)
	center.add_child(col)
	_title = UiKit.label("NÍVEL 2!", 56, UiKit.TOXIC, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_title)
	_subtitle = UiKit.label("Escolha uma melhoria", 24, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_subtitle)
	_cards = UiKit.hbox(22)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(_cards)


func _enqueue(kind: String) -> void:
	_queue.append(kind)
	if not _root.visible and not _scheduled:
		_scheduled = true
		_show_next.call_deferred()


func is_open() -> bool:
	return _root.visible


func _show_next() -> void:
	_scheduled = false
	if _queue.is_empty() or not GameState.is_running:
		_close()
		return
	var kind: String = _queue.pop_front()
	var choices := UpgradePicker.pick(_all_upgrades, GameState.upgrade_counts,
			GameState.owned_weapons, CHOICES, _rng, GameState.weapon_levels)
	if choices.is_empty():
		_show_next()
		return
	for child: Node in _cards.get_children():
		child.queue_free()
	for u: UpgradeData in choices:
		_cards.add_child(_make_card(u))
	if kind == "chest":
		_title.text = "BAÚ ENCONTRADO!"
		_title.add_theme_color_override(&"font_color", UiKit.GOLD)
		_subtitle.text = "Escolha um prêmio"
	else:
		var pending_levels := _queue.count("level")
		_title.text = "NÍVEL %d!" % (GameState.level - pending_levels)
		_title.add_theme_color_override(&"font_color", UiKit.TOXIC)
		_subtitle.text = "Escolha uma melhoria"
	GameState.request_pause(self)
	_root.show()
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.15)
	Audio.play(&"level_up" if kind == "level" else &"chest")
	_set_cards_enabled(false)
	await get_tree().create_timer(INPUT_DELAY, true).timeout
	_set_cards_enabled(true)


func _make_card(u: UpgradeData) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CARD_SIZE
	b.focus_mode = Control.FOCUS_NONE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.08, 0.08, 0.97)
	style.border_color = u.color
	style.set_border_width_all(4)
	style.border_width_top = 14
	style.set_corner_radius_all(18)
	b.add_theme_stylebox_override(&"normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.16, 0.13, 0.1, 0.98)
	b.add_theme_stylebox_override(&"hover", hover)
	b.add_theme_stylebox_override(&"pressed", hover)
	b.add_theme_stylebox_override(&"disabled", style)
	UiKit.add_press_feedback(b)
	var col := UiKit.vbox(10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.full_rect(col)
	col.offset_left = 18
	col.offset_right = -18
	col.offset_top = 28
	col.offset_bottom = -18
	b.add_child(col)
	col.add_child(UiKit.label(TAG_NAMES.get(u.tag, "MELHORIA"), 18, u.color, HORIZONTAL_ALIGNMENT_CENTER))
	var title := UiKit.label(u.title, 28, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)
	var desc := UiKit.label(u.description, 22, UiKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(desc)
	col.add_child(UiKit.label(_level_text(u), 22, u.color, HORIZONTAL_ALIGNMENT_CENTER))
	for c: Node in col.get_children():
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.pressed.connect(_on_card_pressed.bind(u))
	return b


func _level_text(u: UpgradeData) -> String:
	match u.kind:
		UpgradeData.Kind.NEW_WEAPON:
			return "NOVA!"
		UpgradeData.Kind.EVOLVE:
			return "ARMA EVOLUÍDA"
		UpgradeData.Kind.WEAPON_STAT:
			var lvl := GameState.weapon_level(u.weapon.id) if u.weapon else 0
			return "Nv %d  ›  %d" % [lvl, lvl + 1]
		UpgradeData.Kind.PLAYER_STAT:
			var picks: int = GameState.upgrade_counts.get(u.id, 0)
			return "%d / %d" % [picks + 1, u.max_picks] if u.max_picks > 0 else ""
	return ""


func _set_cards_enabled(enabled: bool) -> void:
	for child: Node in _cards.get_children():
		(child as Button).disabled = not enabled


func _on_card_pressed(u: UpgradeData) -> void:
	_set_cards_enabled(false)
	GameState.register_pick(u)
	Events.upgrade_chosen.emit(u)
	if u.kind == UpgradeData.Kind.EVOLVE:
		Audio.play(&"evolve")
	if not _queue.is_empty():
		_show_next()
	else:
		_close()


func _close() -> void:
	_root.hide()
	GameState.release_pause(self)
