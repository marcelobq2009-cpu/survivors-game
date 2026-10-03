class_name UiScreen
extends Control
## Base das telas de menu: fundo, margens seguras, cabecalho (titulo + botao
## Voltar) e uma area de conteudo. Subclasses implementam build_content().

var content: VBoxContainer
var header_right: HBoxContainer
var title_label: Label
var _title_text: String = ""


func _init(title: String = "") -> void:
	_title_text = title


func _ready() -> void:
	UiKit.full_rect(self)
	add_child(MenuBackdrop.new())
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UiKit.full_rect(dim))
	var safe := SafeAreaContainer.new()
	safe.base_margin = 22
	add_child(UiKit.full_rect(safe))
	var root := UiKit.vbox(14)
	safe.add_child(root)
	var header := UiKit.hbox(16)
	root.add_child(header)
	if _title_text != "":
		var back := UiKit.button("‹ Voltar", Vector2(170, 64), 24)
		back.pressed.connect(go_back)
		header.add_child(back)
		title_label = UiKit.label(_title_text.to_upper(), 40, UiKit.TEXT)
		header.add_child(title_label)
	header.add_child(UiKit.spacer())
	header_right = UiKit.hbox(14)
	header.add_child(header_right)
	content = UiKit.vbox(14)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)
	build_content()


## Implementado por cada tela.
func build_content() -> void:
	pass


func go_back() -> void:
	SceneFlow.go_to(SceneFlow.MENU)


func _unhandled_input(event: InputEvent) -> void:
	# Botao "voltar" do Android / Esc no PC.
	if event.is_action_pressed(&"ui_cancel") and _title_text != "":
		get_viewport().set_input_as_handled()
		go_back()


## Mostra o ouro do jogador no canto superior direito.
func show_gold() -> void:
	header_right.add_child(UiKit.label("OURO  %d" % Save.profile.gold, 28, UiKit.GOLD))
