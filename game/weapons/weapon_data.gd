class_name WeaponData
extends Resource
## Stats base de uma arma (data/weapons/*.tres).
## `scene` define o COMPORTAMENTO (projetil, corpo a corpo, arremesso, aura).
## Pistola, espingarda e metralhadora usam o MESMO comportamento (projetil),
## so mudam os numeros. Arma nova com comportamento existente = so um .tres.

enum Visual { BULLET, PELLET, BALL }

@export var id: StringName = &"weapon"
@export var display_name: String = "Arma"
@export_multiline var description: String = ""
## Cena com o script de comportamento (deve estender Weapon).
@export var scene: PackedScene
@export var icon: Texture2D
@export var color: Color = Color.WHITE

@export_group("Stats")
@export var damage: float = 5.0
## Segundos entre ataques.
@export var cooldown: float = 1.0
## Raio em metros: do projetil, da explosao, da aura ou do golpe.
@export var area: float = 0.25
## Metros por segundo.
@export var projectile_speed: float = 18.0
@export var projectile_count: int = 1
## Abertura do leque de projeteis (graus).
@export var spread_degrees: float = 10.0
## Quantos zumbis o projetil atravessa antes de sumir.
@export var pierce: int = 1
## Tempo de vida do projetil (s) ou tempo de voo do arremesso.
@export var lifetime: float = 1.2
## Alcance para procurar alvo (metros).
@export var target_range: float = 14.0
@export var knockback: float = 3.0
## Se true, recebe os projeteis extras do jogador (stat projectile_bonus).
@export var uses_projectile_bonus: bool = true
@export var max_level: int = 8

@export_group("Visual")
@export var projectile_visual: Visual = Visual.BULLET
@export var sound_id: StringName = &"shoot"
