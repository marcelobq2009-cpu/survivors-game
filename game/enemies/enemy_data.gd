class_name EnemyData
extends Resource
## Stats de um tipo de zumbi/inimigo. Novo inimigo = novo .tres em data/enemies/.

enum Behavior {
	CHASE,     ## Persegue o jogador.
	EXPLODER,  ## Persegue; perto do jogador para, pisca e explode.
	CHARGER,   ## Persegue e de tempos em tempos da uma investida rapida (chefes).
}

@export var id: StringName = &"enemy"
@export var display_name: String = "Zumbi"
@export var behavior: Behavior = Behavior.CHASE
@export var is_boss: bool = false

enum ModelKind { WALKER, RUNNER, BRUTE, BLOATER, COLOSSUS, MUTANT }
## Silhueta do modelo placeholder (cada tipo reconhecivel de longe).
@export var model_kind: ModelKind = ModelKind.WALKER

@export_group("Stats")
@export var max_health: float = 10.0
## Metros por segundo.
@export var speed: float = 1.5
@export var contact_damage: float = 5.0
@export var xp_value: int = 1
## Raio de colisao em metros.
@export var radius: float = 0.4
## 0 = empurrado normalmente, 1 = imune a empurrao.
@export_range(0.0, 1.0) var knockback_resistance: float = 0.0

@export_group("Comportamento especial")
## EXPLODER: distancia para comecar a explodir, raio e dano da explosao.
@export var explode_trigger_distance: float = 1.6
@export var explode_radius: float = 2.6
@export var explode_damage: float = 18.0
@export var explode_fuse: float = 1.0
## CHARGER: a cada X segundos, investida com esta velocidade por Y segundos.
@export var charge_interval: float = 5.0
@export var charge_speed: float = 9.0
@export var charge_duration: float = 0.7

@export_group("Drops")
@export_range(0.0, 1.0) var gold_chance: float = 0.04
@export var gold_value: int = 1
@export_range(0.0, 1.0) var chest_chance: float = 0.0

@export_group("Visual")
## Malha 3D. Vazio = placeholder gerado (PlaceholderMeshes.zombie()).
@export var mesh: Mesh
@export var body_color: Color = Color(0.35, 0.45, 0.35)
@export var skin_color: Color = Color(0.55, 0.7, 0.5)
## Escala visual do modelo (1 = altura de uma pessoa).
@export var model_scale: float = 1.0
