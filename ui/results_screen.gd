class_name ResultsScreen
extends CanvasLayer
## Tela de resultado (vitoria ou morte): estatisticas, recompensas,
## desbloqueios, conquistas e, no ranqueado, recorde/posicao global.
## Os numeros aparecem um a um (sensacao de recompensa).

var _root: Control
var _rows: VBoxContainer
var _side: VBoxContainer


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.run_ended.connect(_on_run_ended)


func _on_run_ended(r: RunResult) -> void:
	_root = Control.new()
	add_child(UiKit.full_rect(_root))
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.03, 0.82)
	_root.add_child(UiKit.full_rect(dim))
	var safe := SafeAreaContainer.new()
	safe.base_margin = 26
	_root.add_child(UiKit.full_rect(safe))
	var col := UiKit.vbox(14)
	safe.add_child(col)

	var title := "VOCÊ SOBREVIVEU!" if r.victory else "VOCÊ MORREU"
	var color := UiKit.TOXIC if r.victory else UiKit.DANGER
	if r.is_ranked():
		title = "FIM DA CORRIDA RANQUEADA"
		color = UiKit.ACCENT
	col.add_child(UiKit.label(title, 52, color, HORIZONTAL_ALIGNMENT_CENTER))
	if r.death_cause != "":
		col.add_child(UiKit.label("Causa da morte: %s" % r.death_cause, 26, UiKit.TEXT,
				HORIZONTAL_ALIGNMENT_CENTER))

	var body := UiKit.hbox(24)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	var stats_panel := UiKit.panel()
	stats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(stats_panel)
	_rows = UiKit.vbox(6)
	stats_panel.add_child(_rows)
	var side_panel := UiKit.panel(Color(0.1, 0.09, 0.06, 0.94), UiKit.GOLD)
	side_panel.custom_minimum_size = Vector2(430, 0)
	body.add_child(side_panel)
	_side = UiKit.vbox(10)
	side_panel.add_child(_side)

	var buttons := UiKit.hbox(16)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	var again := UiKit.button("JOGAR NOVAMENTE", Vector2(340, 84), 28, UiKit.TOXIC)
	again.pressed.connect(func() -> void: SceneFlow.go_to(SceneFlow.GAME))
	buttons.add_child(again)
	if r.is_ranked():
		var rank := UiKit.button("VER RANKING", Vector2(260, 84), 26)
		rank.pressed.connect(func() -> void: SceneFlow.go_to(SceneFlow.RANKING))
		buttons.add_child(rank)
	var menu := UiKit.button("MENU", Vector2(220, 84), 28)
	menu.pressed.connect(func() -> void: SceneFlow.go_to(SceneFlow.MENU))
	buttons.add_child(menu)
	col.add_child(buttons)
	_fill(r)


func _fill(r: RunResult) -> void:
	var best_id := r.best_weapon_id()
	var best_weapon := best_id
	var player := Player.find(get_tree())
	if player and player.weapons.has(StringName(best_id)):
		best_weapon = player.weapons[StringName(best_id)].data.display_name
	var stats: Array = [
		["Tempo sobrevivido", UiKit.time_text(r.time)],
		["Zumbis derrotados", str(r.kills)],
		["Nível", str(r.level)],
		["XP", str(r.xp_total)],
		["Ouro coletado", str(r.gold_collected)],
		["Dano causado", str(roundi(r.damage_total))],
		["Melhor arma", best_weapon if best_weapon != "" else "-"],
		["Chefes derrotados", str(r.bosses_killed)],
	]
	if r.is_ranked():
		stats.append(["Pontuação", str(r.score)])
	for i: int in stats.size():
		var row := UiKit.hbox(10)
		var name_l := UiKit.label(stats[i][0] as String, 24, UiKit.MUTED)
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_l)
		row.add_child(UiKit.label(stats[i][1] as String, 26, UiKit.TEXT, HORIZONTAL_ALIGNMENT_RIGHT))
		row.modulate.a = 0.0
		_rows.add_child(row)
		var tw := row.create_tween()
		tw.tween_interval(0.08 * i)
		tw.tween_property(row, "modulate:a", 1.0, 0.15)

	# Lado direito: recompensas, recorde, desbloqueios.
	_side.add_child(UiKit.label("RECOMPENSAS", 26, UiKit.GOLD))
	_side.add_child(UiKit.label("+%d de ouro" % r.gold_reward, 34, UiKit.GOLD))
	_side.add_child(UiKit.label("Total: %d" % Save.profile.gold, 20, UiKit.MUTED))
	if r.is_ranked():
		if r.new_record:
			_side.add_child(UiKit.label("NOVO RECORDE!", 34, UiKit.TOXIC))
		_side.add_child(UiKit.label("Sua posição global: #%d" % r.rank_position, 26, UiKit.TEXT))
	elif r.new_record:
		_side.add_child(UiKit.label("NOVO RECORDE DE TEMPO!", 28, UiKit.TOXIC))
	if not r.new_unlocks.is_empty():
		_side.add_child(UiKit.label("DESBLOQUEADO!", 28, UiKit.TOXIC))
		for c: ContentData in r.new_unlocks:
			var kind := "Personagem" if c is CharacterData else "Mapa"
			_side.add_child(UiKit.label("%s: %s" % [kind, c.display_name], 24, c.color.lightened(0.2)))
	if not r.new_achievements.is_empty():
		_side.add_child(UiKit.label("CONQUISTAS", 26, UiKit.ACCENT))
		for a: AchievementData in r.new_achievements:
			_side.add_child(UiKit.label("%s (+%d)" % [a.display_name, a.reward_gold], 20, UiKit.TEXT))
	_play_reward_sounds(r)
	if r.new_unlocks.is_empty() and not r.victory and not r.is_ranked():
		var hint := _next_goal_hint()
		if hint != "":
			_side.add_child(UiKit.label("PRÓXIMO OBJETIVO", 22, UiKit.ACCENT))
			_side.add_child(UiKit.wrap_label(hint, 20, UiKit.TEXT))


## Dica do proximo desbloqueio (motiva a tentar de novo).
func _next_goal_hint() -> String:
	for c: ContentData in Content.unlockables():
		if c.coming_soon or ProgressService.is_unlocked(c, Save.profile):
			continue
		for req: UnlockRequirement in c.unlock_requirements:
			if not req.is_met(Save.profile):
				return "%s para desbloquear %s." % [req.describe(), c.display_name]
	return ""


## Sons das recompensas em sequencia (sem atropelar), depois a musica volta suave.
func _play_reward_sounds(r: RunResult) -> void:
	var queue: Array[StringName] = []
	if r.new_record:
		queue.append(&"reward_new_record")
	for c: ContentData in r.new_unlocks:
		queue.append(&"reward_unlock_character" if c is CharacterData else &"reward_unlock_map")
	if not r.new_achievements.is_empty():
		queue.append(&"reward_achievement")
	await get_tree().create_timer(1.6, true, false, true).timeout
	for id: StringName in queue:
		Audio.play(id)
		await get_tree().create_timer(1.3, true, false, true).timeout
	await get_tree().create_timer(1.0, true, false, true).timeout
	Audio.play_music(&"menu")
	Audio.set_intensity(1)
