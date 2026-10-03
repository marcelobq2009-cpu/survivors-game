class_name SettingsScreen
extends UiScreen
## Tela de Configuracoes (menu principal).


func _init() -> void:
	super("Configurações")


func build_content() -> void:
	var p := UiKit.panel()
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(p)
	p.add_child(SettingsPanel.new())
