class_name WaveData
extends Resource
## Uma "onda": de start_time ate a proxima onda, nascem estes inimigos neste ritmo.

## Segundos desde o inicio da partida em que esta onda comeca.
@export var start_time: float = 0.0
## Tipos que podem nascer (sorteados com peso igual; repita para dar mais peso).
@export var enemies: Array[EnemyData] = []
## Segundos entre cada leva de spawn.
@export var spawn_interval: float = 1.0
## Quantos inimigos por leva.
@export var spawn_count: int = 1
## Limite de inimigos vivos ao mesmo tempo nesta onda.
@export var max_alive: int = 50
## Multiplica a vida dos inimigos desta onda (dificuldade crescente).
@export var health_multiplier: float = 1.0
