class_name SafeAreaContainer
extends MarginContainer
## Margens que evitam o notch e as bordas arredondadas do celular.
## Le a "area segura" do sistema e converte para as coordenadas do jogo.

@export var base_margin: int = 16


func _ready() -> void:
	get_viewport().size_changed.connect(_update)
	_update()


func _update() -> void:
	var window_size := Vector2(DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var view := get_viewport_rect().size
	var left := 0.0
	var top := 0.0
	var right := 0.0
	var bottom := 0.0
	# So no celular nativo; no PC/web a "area segura" e da tela, nao da janela.
	if OS.has_feature("mobile") and window_size.x > 0 and safe.size.x > 0:
		var scale := view / window_size
		left = safe.position.x * scale.x
		top = safe.position.y * scale.y
		right = (window_size.x - safe.end.x) * scale.x
		bottom = (window_size.y - safe.end.y) * scale.y
	add_theme_constant_override(&"margin_left", base_margin + maxi(0, roundi(left)))
	add_theme_constant_override(&"margin_top", base_margin + maxi(0, roundi(top)))
	add_theme_constant_override(&"margin_right", base_margin + maxi(0, roundi(right)))
	add_theme_constant_override(&"margin_bottom", base_margin + maxi(0, roundi(bottom)))
