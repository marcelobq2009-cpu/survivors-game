class_name LevelUpScreen
extends CanvasLayer
## Tela de level-up: pausa o jogo e mostra ate 3 cartas sorteadas.
## Se subir varios niveis de uma vez, mostra uma tela por nivel.

const CHOICES := 3
## Evita que um toque "atrasado" escolha uma carta sem querer.
const INPUT_DELAY := 0.35
const CARD_SIZE := Vector2(620, 170)

var _all_upgrades: Array[UpgradeData] = []
var _pending: int = 0
var _rng := RandomNumberGenerator.new()

@onready var title_label: Label = %Title
@onready var cards_box: VBoxContainer = %Cards


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_all_upgrades = UpgradeLibrary.load_all()
	_rng.randomize()
	Events.level_up.connect(_on_level_up)


func _on_level_up(_new_level: int) -> void:
	_pending += 1
	if not visible:
		_show_next.call_deferred()


func _show_next() -> void:
	if _pending <= 0 or not GameState.is_running:
		_close()
		return
	_pending -= 1
	var choices := UpgradePicker.pick(_all_upgrades, GameState.upgrade_counts,
			GameState.owned_weapons, CHOICES, _rng)
	if choices.is_empty():
		_show_next()
		return
	for child: Node in cards_box.get_children():
		child.queue_free()
	for u: UpgradeData in choices:
		cards_box.add_child(_make_card(u))
	title_label.text = "Nivel %d!" % (GameState.level - _pending)
	get_tree().paused = true
	show()
	Audio.play(&"level_up")
	_set_cards_enabled(false)
	await get_tree().create_timer(INPUT_DELAY, true).timeout
	_set_cards_enabled(true)


func _make_card(u: UpgradeData) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CARD_SIZE
	b.focus_mode = Control.FOCUS_NONE
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var picks: int = GameState.upgrade_counts.get(u.id, 0)
	var level_text := "" if u.max_picks <= 0 else "  (%d/%d)" % [picks + 1, u.max_picks]
	b.text = "%s%s\n%s" % [u.title, level_text, u.description]
	var style := (b.get_theme_stylebox(&"normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
	style.border_color = u.color
	b.add_theme_stylebox_override(&"normal", style)
	b.pressed.connect(_on_card_pressed.bind(u))
	return b


func _set_cards_enabled(enabled: bool) -> void:
	for child: Node in cards_box.get_children():
		(child as Button).disabled = not enabled


func _on_card_pressed(u: UpgradeData) -> void:
	_set_cards_enabled(false)
	GameState.register_pick(u)
	Events.upgrade_chosen.emit(u)
	if _pending > 0:
		_show_next()
	else:
		_close()


func _close() -> void:
	hide()
	if GameState.is_running:
		get_tree().paused = false
