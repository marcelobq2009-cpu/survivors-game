class_name LoadingScreen
extends CanvasLayer
## Tela de carregamento da partida: mapa, modo, dica e progresso real da
## construcao do mapa (GameMap.build_progress). Some com fade quando pronto.

const TIPS: PackedStringArray = [
	"Zumbis derrubam gemas de XP: chegue perto para coletar.",
	"O Inchado pisca e faz bipes antes de explodir. Afaste-se do círculo vermelho!",
	"Chefes aparecem a cada 5 minutos. Eles avisam antes de dar a investida.",
	"Zumbis dourados são elites: mais fortes, mas dão muito XP e podem soltar baú.",
	"Baús curam vida e dão uma melhoria extra.",
	"Pistola no nível 5 + Mira Treinada = Pistola Rajada.",
	"Gaste o ouro em MELHORIAS no menu para começar cada partida mais forte.",
	"No ranqueado não existe fim: a dificuldade cresce para sempre.",
	"Combine passivas da mesma categoria para montar uma build forte.",
]

var _root: Control
var _bar: ProgressBar
var _step: Label


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	add_child(UiKit.full_rect(_root))
	_root.add_child(MenuBackdrop.new())
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	_root.add_child(UiKit.full_rect(dim))
	var center := CenterContainer.new()
	_root.add_child(UiKit.full_rect(center))
	var col := UiKit.vbox(16)
	col.custom_minimum_size.x = 760
	center.add_child(col)
	var setup := GameState.setup
	var map_name := setup.map.display_name if setup.map else ""
	col.add_child(UiKit.label(map_name.to_upper(), 64, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	var mode := "MODO RANQUEADO" if setup.is_ranked() else "MODO NORMAL — SOBREVIVA %d MIN" % roundi(setup.duration() / 60.0)
	col.add_child(UiKit.label(mode, 26, UiKit.TOXIC, HORIZONTAL_ALIGNMENT_CENTER))
	_bar = UiKit.bar(UiKit.ACCENT, 22)
	_bar.max_value = 1.0
	col.add_child(_bar)
	_step = UiKit.label("Preparando...", 22, UiKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_step)
	var tip := UiKit.label("DICA: " + TIPS[randi() % TIPS.size()], 24, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(tip)
	Audio.play_music(&"loading")


## Progresso do mapa (0..70% da barra).
func set_map_progress(ratio: float, step: String) -> void:
	set_progress(ratio * 0.7, step)


## Progresso do audio (70..100% da barra).
func set_audio_progress(ratio: float, step: String) -> void:
	set_progress(0.7 + ratio * 0.3, step)


func set_progress(ratio: float, step: String) -> void:
	_bar.value = maxf(_bar.value, ratio)
	if step != "":
		_step.text = step + "..."


func finish() -> void:
	_bar.value = 1.0
	Audio.play(&"ui_transition")
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.35)
	await tw.finished
	queue_free()
