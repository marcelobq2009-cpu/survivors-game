class_name CharacterData
extends ContentData
## Um personagem jogavel (data/characters/*.tres).
## Novo personagem = novo .tres (e, se quiser, um modelo 3D proprio).

@export_group("Visual")
## Cena 3D do modelo (placeholder hoje; troque por um modelo real depois).
@export var model_scene: PackedScene
## Miniatura para cards (opcional; sem ela o card usa `color`).
@export var portrait: Texture2D

@export_group("Atributos")
@export var max_health: float = 100.0
## Metros por segundo.
@export var move_speed: float = 4.5
## Raio do ima de XP em metros.
@export var pickup_radius: float = 3.0
## Raio de colisao com zumbis (metros).
@export var radius: float = 0.4
@export var invincibility_time: float = 0.6
## Dano recebido e reduzido nesta quantidade (minimo 1).
@export var armor: float = 0.0
## Vida recuperada por segundo.
@export var regen: float = 0.0
@export var damage_mult: float = 1.0
@export var area_mult: float = 1.0
@export var cooldown_mult: float = 1.0
@export_range(0.0, 1.0) var crit_chance: float = 0.05
@export var crit_damage: float = 1.5
## Projeteis extras em todas as armas de disparo.
@export var projectile_bonus: int = 0
@export var xp_mult: float = 1.0
@export var gold_mult: float = 1.0

@export_group("Arma, habilidade e passiva")
@export var starting_weapon: WeaponData
@export var passive_name: String = ""
@export_multiline var passive_description: String = ""
## Bonus aplicados no inicio da partida (reaproveita UpgradeData do tipo PLAYER_STAT).
@export var passive_bonuses: Array[UpgradeData] = []
## Habilidade ativa: estrutura para o futuro (ainda nao implementada no gameplay).
@export var ability_name: String = ""
@export_multiline var ability_description: String = ""
