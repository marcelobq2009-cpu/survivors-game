class_name EnemyAgent
extends RefCounted
## Um zumbi "vivo" na simulacao. Nao e um no (Node): e so dados, o que
## permite centenas de zumbis com custo baixo. O EnemyManager move todos e o
## EnemyRenderer desenha todos de uma vez (MultiMesh).

var uid: int = 0
var data: EnemyData
var pos: Vector2 = Vector2.ZERO
var heading: float = 0.0
var hp: float = 1.0
var max_hp: float = 1.0
var speed: float = 1.0
var radius: float = 0.4
var damage: float = 1.0
var xp: int = 1
var scale: float = 1.0
var elite: bool = false
var alive: bool = false
var knockback: Vector2 = Vector2.ZERO
var flash: float = 0.0
## Fase da animacao de andar (para nao balancarem todos juntos).
var anim_phase: float = 0.0
## Estado do comportamento especial (explodir, investida...).
var state: int = 0
var state_timer: float = 0.0
var charge_dir: Vector2 = Vector2.ZERO
## Posicao no array do EnemyManager (remocao O(1)).
var index: int = -1


func hp_ratio() -> float:
	return hp / max_hp if max_hp > 0.0 else 0.0
