class_name UiKit
extends RefCounted
## Kit de componentes da interface (cores, botoes, textos, paineis).
## Todas as telas usam isto, entao mudar o visual de tudo = mudar aqui e no
## tema (ui/main_theme.tres).

const BG := Color(0.06, 0.06, 0.07)
const PANEL := Color(0.08, 0.08, 0.09, 0.92)
const ACCENT := Color(0.95, 0.55, 0.2)      # laranja "por do sol"
const TOXIC := Color(0.55, 0.95, 0.35)      # verde zumbi
const DANGER := Color(0.95, 0.3, 0.28)
const GOLD := Color(1.0, 0.82, 0.3)
const TEXT := Color(0.96, 0.93, 0.88)
const MUTED := Color(0.62, 0.6, 0.57)
const LOCKED := Color(0.35, 0.34, 0.33)

## Altura minima de botoes tocaveis (o dedo precisa de ~9 mm).
const TOUCH_HEIGHT := 76.0


static func button(text: String, min_size: Vector2 = Vector2(0, TOUCH_HEIGHT), font_size: int = 26,
		accent: Color = ACCENT) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override(&"font_size", font_size)
	if accent != ACCENT:
		var s := (b.get_theme_stylebox(&"normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
		s.border_color = accent
		b.add_theme_stylebox_override(&"normal", s)
	add_press_feedback(b)
	return b


## "Afunda" o botao ao tocar e toca um clique (feedback de toque).
static func add_press_feedback(b: BaseButton) -> void:
	b.resized.connect(func() -> void: b.pivot_offset = b.size * 0.5)
	b.button_down.connect(func() -> void:
		b.create_tween().tween_property(b, "scale", Vector2(0.95, 0.95), 0.06))
	b.button_up.connect(func() -> void:
		b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.08))
	b.pressed.connect(func() -> void: Audio.play(&"click", -8.0))


static func label(text: String, font_size: int = 24, color: Color = TEXT,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", color)
	l.horizontal_alignment = align
	return l


static func wrap_label(text: String, font_size: int = 20, color: Color = MUTED) -> Label:
	var l := label(text, font_size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 120
	return l


static func panel(color: Color = PANEL, border: Color = Color(0.32, 0.28, 0.25)) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(16)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	p.add_theme_stylebox_override(&"panel", s)
	return p


static func vbox(separation: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", separation)
	return v


static func hbox(separation: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", separation)
	return h


static func spacer(expand_h: bool = true, expand_v: bool = false) -> Control:
	var c := Control.new()
	if expand_h:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if expand_v:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func bar(color: Color, height: float = 14.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(0, height)
	b.show_percentage = false
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(6)
	b.add_theme_stylebox_override(&"fill", fill)
	return b


## Faz o Control ocupar a tela toda.
static func full_rect(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


## Quadrado colorido com uma letra (placeholder de icone/retrato).
static func badge(text: String, color: Color, size: float = 64.0) -> PanelContainer:
	var p := panel(color.darkened(0.55), color)
	p.custom_minimum_size = Vector2(size, size)
	var l := label(text, int(size * 0.45), color.lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


static func time_text(seconds: float) -> String:
	var s := floori(seconds)
	if s >= 3600:
		return "%d:%02d:%02d" % [floori(s / 3600.0), floori((s % 3600) / 60.0), s % 60]
	return "%02d:%02d" % [floori(s / 60.0), s % 60]
