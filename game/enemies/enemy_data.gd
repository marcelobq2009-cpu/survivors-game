class_name EnemyData
extends Resource
## Stats de um tipo de inimigo. Novo inimigo = novo .tres em data/enemies/.

@export var id: StringName = &"enemy"
@export var display_name: String = "Enemy"
@export_group("Stats")
@export var max_health: float = 10.0
@export var speed: float = 80.0
@export var contact_damage: float = 5.0
@export var xp_value: int = 1
## Raio de colisao em pixels (tambem define o tamanho do sprite).
@export var radius: float = 16.0
## 0 = empurrado normalmente, 1 = imune a empurrao.
@export_range(0.0, 1.0) var knockback_resistance: float = 0.0
@export_group("Visual")
@export var texture: Texture2D
@export var color: Color = Color.WHITE
