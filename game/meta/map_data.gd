class_name MapData
extends ContentData
## Um mapa jogavel (data/maps/*.tres).

## Cena 3D do mapa (raiz deve estender GameMap).
@export var scene: PackedScene
## Imagem para o card (opcional).
@export var preview: Texture2D
@export_range(1, 5) var difficulty: int = 1
## Quais zumbis aparecem em cada momento.
@export var timeline: WaveTimeline
## Como a dificuldade sobe com o tempo (normal e ranqueado).
@export var difficulty_profile: DifficultyProfile
## Duracao do modo normal neste mapa. 0 = Config.game.match_duration().
@export var match_duration: float = 0.0
## Id da musica da partida (ver autoload/audio.gd).
@export var music_id: StringName = &"music_game"


func effective_duration() -> float:
	return match_duration if match_duration > 0.0 else Config.game.match_duration()
