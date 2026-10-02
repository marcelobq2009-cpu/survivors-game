extends Node
## Pontos de audio do jogo (autoload "Audio").
## O codigo chama Audio.play(&"hit") etc. Enquanto nao houver sons, nada toca
## ("silencio estruturado"). Para adicionar um som: coloque o arquivo em
## assets/audio/ e registre o id em SOUNDS abaixo.

const SOUNDS: Dictionary[StringName, String] = {
	# &"hit": "res://assets/audio/hit.wav",
	# &"enemy_die": "res://assets/audio/enemy_die.wav",
	# &"pickup": "res://assets/audio/pickup.wav",
	# &"level_up": "res://assets/audio/level_up.wav",
	# &"player_hurt": "res://assets/audio/player_hurt.wav",
}
const MAX_VOICES := 8

var _streams: Dictionary[StringName, AudioStream] = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id: StringName in SOUNDS:
		var stream := load(SOUNDS[id]) as AudioStream
		if stream:
			_streams[id] = stream
	for i: int in MAX_VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(id: StringName, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _streams.get(id)
	if stream == null:
		return  # Ponto de audio ainda sem som.
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.play()
