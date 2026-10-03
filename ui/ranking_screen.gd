class_name RankingScreen
extends UiScreen
## Ranking global (modo ranqueado). Hoje os dados vem do LocalRankingProvider
## (mock); com um backend real, so o provider muda (autoload/ranking.gd).

var _map_id: String = "rio"
var _list: VBoxContainer
var _mine: VBoxContainer
var _tabs: HBoxContainer
var _group := ButtonGroup.new()


func _init() -> void:
	super("Ranking")


func build_content() -> void:
	_tabs = UiKit.hbox(12)
	content.add_child(_tabs)
	for m: MapData in Content.maps:
		if m.coming_soon or not ProgressService.is_unlocked(m, Save.profile):
			continue
		var b := UiKit.button(m.display_name, Vector2(220, 60), 22)
		b.toggle_mode = true
		b.button_group = _group
		b.button_pressed = String(m.id) == _map_id
		b.pressed.connect(_select.bind(String(m.id)))
		_tabs.add_child(b)
	var body := UiKit.hbox(20)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	var list_panel := UiKit.panel()
	list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(list_panel)
	var list_box := UiKit.vbox(6)
	list_panel.add_child(list_box)
	list_box.add_child(_row("#", "JOGADOR", "PERSONAGEM", "TEMPO", "PONTOS", UiKit.MUTED))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_box.add_child(scroll)
	_list = UiKit.vbox(4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var mine_panel := UiKit.panel(Color(0.1, 0.12, 0.08, 0.92), UiKit.TOXIC)
	mine_panel.custom_minimum_size = Vector2(320, 0)
	body.add_child(mine_panel)
	_mine = UiKit.vbox(10)
	mine_panel.add_child(_mine)
	content.add_child(UiKit.label("Ranking local de teste (mock). O ranking online chega com o backend.",
			16, UiKit.MUTED))
	Ranking.leaderboard_ready.connect(_on_leaderboard)
	_select(_map_id)


func _select(map_id: String) -> void:
	_map_id = map_id
	for c: Node in _list.get_children():
		c.queue_free()
	_list.add_child(UiKit.label("Carregando...", 22, UiKit.MUTED))
	Ranking.request_leaderboard(map_id, 50)


func _on_leaderboard(map_id: String, entries: Array[RankingEntry], player_entry: RankingEntry) -> void:
	if map_id != _map_id or not is_inside_tree():
		return
	for c: Node in _list.get_children():
		c.queue_free()
	for e: RankingEntry in entries:
		var color := UiKit.TOXIC if e.is_player else (UiKit.GOLD if e.rank <= 3 else UiKit.TEXT)
		_list.add_child(_row(str(e.rank), e.player_name, _character_name(e.character_id),
				UiKit.time_text(e.time), str(e.score), color))
	_show_mine(player_entry)


func _show_mine(e: RankingEntry) -> void:
	for c: Node in _mine.get_children():
		c.queue_free()
	_mine.add_child(UiKit.label("MINHA POSIÇÃO", 28, UiKit.TOXIC))
	if e == null:
		_mine.add_child(UiKit.wrap_label("Jogue uma partida RANQUEADA neste mapa para entrar no ranking.", 20, UiKit.TEXT))
		return
	var pos := Ranking.position_for_score(_map_id, e.score)
	_mine.add_child(UiKit.label("#%d" % pos, 56, UiKit.GOLD))
	_mine.add_child(UiKit.label("Jogador: %s" % e.player_name, 20))
	_mine.add_child(UiKit.label("Melhor tempo: %s" % UiKit.time_text(e.time), 20))
	_mine.add_child(UiKit.label("Melhor pontuação: %d" % e.score, 20))
	_mine.add_child(UiKit.label("Personagem: %s" % _character_name(e.character_id), 20))
	var map := Content.find_map(StringName(_map_id))
	_mine.add_child(UiKit.label("Mapa: %s" % (map.display_name if map else _map_id), 20))


func _row(rank: String, player: String, character: String, time: String, score: String,
		color: Color) -> HBoxContainer:
	var h := UiKit.hbox(10)
	for cell: Array in [[rank, 56], [player, 250], [character, 170], [time, 120], [score, 120]]:
		var l := UiKit.label(cell[0] as String, 20, color)
		l.custom_minimum_size.x = cell[1] as int
		l.clip_text = true
		h.add_child(l)
	return h


func _character_name(id: String) -> String:
	var c := Content.find_character(StringName(id))
	return c.display_name if c else "-"
