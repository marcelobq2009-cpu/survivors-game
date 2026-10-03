class_name UpgradesScreen
extends UiScreen
## Loja de MELHORIAS permanentes (gasta o ouro ganho nas partidas).

var _grid: GridContainer
var _gold_label: Label


func _init() -> void:
	super("Melhorias")


func build_content() -> void:
	_gold_label = UiKit.label("", 30, UiKit.GOLD)
	header_right.add_child(_gold_label)
	content.add_child(UiKit.label("Melhorias permanentes: valem em todas as partidas. Ganhe ouro sobrevivendo!",
			20, UiKit.MUTED))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override(&"h_separation", 16)
	_grid.add_theme_constant_override(&"v_separation", 14)
	scroll.add_child(_grid)
	_refresh()


func _refresh() -> void:
	_gold_label.text = "OURO  %d" % Save.profile.gold
	for c: Node in _grid.get_children():
		c.queue_free()
	for m: MetaUpgradeData in Content.meta_upgrades:
		_grid.add_child(_card(m))


func _card(m: MetaUpgradeData) -> Control:
	var p := Save.profile
	var lvl := MetaShop.level(p, m)
	var panel := UiKit.panel(UiKit.PANEL, m.color.darkened(0.2))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := UiKit.hbox(14)
	panel.add_child(row)
	row.add_child(UiKit.badge(m.title.left(1), m.color, 64))
	var col := UiKit.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	col.add_child(UiKit.label("%s  (Nv %d/%d)" % [m.title, lvl, m.max_level], 24, UiKit.TEXT))
	var now := m.effect_text(lvl) if lvl > 0 else "Nenhum bônus ainda"
	col.add_child(UiKit.label("Atual: " + now, 18, UiKit.MUTED))
	if not MetaShop.is_maxed(p, m):
		col.add_child(UiKit.label("Próximo: " + m.effect_text(lvl + 1), 18, m.color.lightened(0.2)))
	var bar := UiKit.bar(m.color, 8)
	bar.max_value = m.max_level
	bar.value = lvl
	col.add_child(bar)
	var buy := UiKit.button("MÁXIMO" if MetaShop.is_maxed(p, m) else "%d" % MetaShop.next_cost(p, m),
			Vector2(150, 70), 26, UiKit.GOLD)
	buy.disabled = not MetaShop.can_buy(p, m)
	buy.pressed.connect(_buy.bind(m))
	row.add_child(buy)
	return panel


func _buy(m: MetaUpgradeData) -> void:
	if MetaShop.buy(Save.profile, m):
		Save.save_data()
		Audio.play(&"reward_achievement")
		_refresh()
