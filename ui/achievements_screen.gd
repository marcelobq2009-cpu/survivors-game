class_name AchievementsScreen
extends UiScreen
## Conquistas (data/achievements/*.tres): progresso, recompensa e status.


func _init() -> void:
	super("Conquistas")


func build_content() -> void:
	show_gold()
	var done := 0
	for a: AchievementData in Content.achievements:
		if Save.profile.achievements.has(String(a.id)):
			done += 1
	content.add_child(UiKit.label("%d de %d conquistadas" % [done, Content.achievements.size()], 22, UiKit.MUTED))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override(&"h_separation", 16)
	grid.add_theme_constant_override(&"v_separation", 16)
	scroll.add_child(grid)
	for a: AchievementData in Content.achievements:
		grid.add_child(_card(a))


func _card(a: AchievementData) -> Control:
	var owned := Save.profile.achievements.has(String(a.id))
	var p := UiKit.panel(Color(0.1, 0.12, 0.08, 0.92) if owned else UiKit.PANEL,
			UiKit.GOLD if owned else Color(0.32, 0.28, 0.25))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := UiKit.hbox(16)
	p.add_child(row)
	row.add_child(UiKit.badge("V" if owned else "?", UiKit.GOLD if owned else UiKit.LOCKED, 70))
	var col := UiKit.vbox(4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var hidden := a.hidden and not owned
	col.add_child(UiKit.label("???" if hidden else a.display_name, 24, UiKit.GOLD if owned else UiKit.TEXT))
	col.add_child(UiKit.wrap_label("Conquista secreta" if hidden else a.description, 18))
	if owned:
		col.add_child(UiKit.label("CONQUISTADA  (+%d ouro)" % a.reward_gold, 18, UiKit.TOXIC))
	else:
		var total := 0.0
		for r: UnlockRequirement in a.unlock_requirements:
			total += r.progress(Save.profile)
		var bar := UiKit.bar(UiKit.ACCENT, 10)
		bar.max_value = 1.0
		bar.value = total / maxf(1.0, a.unlock_requirements.size())
		col.add_child(bar)
		col.add_child(UiKit.label("Recompensa: %d ouro" % a.reward_gold, 16, UiKit.MUTED))
	return p
