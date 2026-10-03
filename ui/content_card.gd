class_name ContentCard
extends Button
## Card de personagem/mapa nas telas de selecao. Mostra bloqueio, requisito e
## progresso. Feito para toque: grande e com feedback.

var content: ContentData
var unlocked: bool = false
var _border: StyleBoxFlat


func setup(p_content: ContentData, p_unlocked: bool) -> void:
	content = p_content
	unlocked = p_unlocked
	custom_minimum_size = Vector2(230, 300)
	focus_mode = Control.FOCUS_NONE
	toggle_mode = true
	clip_contents = true
	var color := content.color if unlocked else UiKit.LOCKED
	_border = StyleBoxFlat.new()
	_border.bg_color = Color(0.08, 0.08, 0.09, 0.95)
	_border.border_color = color.darkened(0.2)
	_border.set_border_width_all(3)
	_border.set_corner_radius_all(16)
	add_theme_stylebox_override(&"normal", _border)
	add_theme_stylebox_override(&"hover", _border)
	add_theme_stylebox_override(&"disabled", _border)
	var selected := _border.duplicate() as StyleBoxFlat
	selected.border_color = UiKit.TOXIC
	selected.set_border_width_all(6)
	selected.bg_color = Color(0.12, 0.14, 0.1, 0.95)
	add_theme_stylebox_override(&"pressed", selected)
	add_theme_stylebox_override(&"hover_pressed", selected)
	UiKit.add_press_feedback(self)

	var box := UiKit.vbox(8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.full_rect(box)
	box.offset_left = 14
	box.offset_right = -14
	box.offset_top = 14
	box.offset_bottom = -14
	add_child(box)
	var art := UiKit.badge(content.display_name.left(1), color, 140)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(art)
	var name_label := UiKit.label(content.display_name, 26, UiKit.TEXT if unlocked else UiKit.MUTED,
			HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(name_label)
	if content.coming_soon:
		box.add_child(UiKit.label("EM BREVE", 20, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	elif not unlocked:
		box.add_child(UiKit.label("BLOQUEADO", 20, UiKit.DANGER, HORIZONTAL_ALIGNMENT_CENTER))
		var bar := UiKit.bar(UiKit.ACCENT, 10)
		bar.max_value = 1.0
		bar.value = _progress()
		box.add_child(bar)
	elif content is MapData:
		box.add_child(UiKit.label("Dificuldade %d/5" % (content as MapData).difficulty, 18,
				UiKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	for c: Node in box.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _progress() -> float:
	if content.unlock_requirements.is_empty():
		return 0.0
	var total := 0.0
	for r: UnlockRequirement in content.unlock_requirements:
		total += r.progress(Save.profile)
	return total / content.unlock_requirements.size()
