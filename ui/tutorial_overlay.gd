class_name TutorialOverlay
extends CanvasLayer
## Tutorial rapido da primeira partida (5 cartoes, pode pular).
## Aparece so enquanto Save.profile.tutorial_done for false.

const STEPS: Array = [
	["MOVIMENTO", "Arraste o dedo no lado ESQUERDO da tela para andar.\nNo PC: WASD ou setas."],
	["COMBATE", "Suas armas atacam SOZINHAS o zumbi mais próximo.\nFoque em se posicionar e fugir."],
	["EXPERIÊNCIA", "Zumbis derrubam gemas. Chegue perto para coletar e ganhar XP."],
	["MELHORIAS", "Ao subir de nível, escolha 1 de 3 melhorias.\nCombine armas e passivas para montar sua build."],
	["OBJETIVO", "Sobreviva até o fim! Chefes aparecem a cada 5 minutos.\nBoa sorte, sobrevivente."],
]

var _step: int = 0
var _root: Control
var _title: Label
var _text: Label
var _next: Button
var _dots: Label


func _ready() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Save.profile.tutorial_done:
		queue_free()
		return
	_build()
	Events.run_started.connect(_begin, CONNECT_ONE_SHOT)


func _begin() -> void:
	await get_tree().create_timer(0.4, true).timeout
	_root.show()
	GameState.request_pause(self)
	_show_step()


func _build() -> void:
	_root = Control.new()
	add_child(UiKit.full_rect(_root))
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	_root.add_child(UiKit.full_rect(dim))
	var center := CenterContainer.new()
	_root.add_child(UiKit.full_rect(center))
	var panel := UiKit.panel(Color(0.08, 0.07, 0.06, 0.96), UiKit.ACCENT)
	panel.custom_minimum_size = Vector2(720, 0)
	center.add_child(panel)
	var col := UiKit.vbox(16)
	panel.add_child(col)
	_title = UiKit.label("", 40, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_title)
	_text = UiKit.label("", 26, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_text)
	_dots = UiKit.label("", 22, UiKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_dots)
	var row := UiKit.hbox(16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var skip := UiKit.button("PULAR TUTORIAL", Vector2(280, 76), 22)
	skip.pressed.connect(_finish)
	row.add_child(skip)
	_next = UiKit.button("PRÓXIMO", Vector2(280, 76), 26, UiKit.TOXIC)
	_next.pressed.connect(_advance)
	row.add_child(_next)
	col.add_child(row)
	_root.hide()


func _show_step() -> void:
	var step: Array = STEPS[_step]
	_title.text = step[0]
	var text: String = step[1]
	if _step == STEPS.size() - 1 and GameState.setup.is_ranked():
		text = "No RANQUEADO não há tempo limite: a dificuldade sobe para sempre.\nSobreviva o máximo que puder!"
	_text.text = text
	_dots.text = "%d / %d" % [_step + 1, STEPS.size()]
	_next.text = "JOGAR!" if _step == STEPS.size() - 1 else "PRÓXIMO"


func _advance() -> void:
	_step += 1
	if _step >= STEPS.size():
		_finish()
	else:
		_show_step()


func _finish() -> void:
	Save.profile.tutorial_done = true
	Save.save_data()
	_root.hide()
	GameState.release_pause(self)
	queue_free()
