class_name PlayerData
extends Resource
## Stats base do jogador (data/player/player.tres).

@export var max_health: float = 100.0
@export var move_speed: float = 220.0
@export var pickup_radius: float = 110.0
@export var radius: float = 18.0
## Segundos invulneravel depois de levar dano.
@export var invincibility_time: float = 0.5
@export var starting_weapon: WeaponData
@export_group("Visual")
@export var texture: Texture2D
@export var color: Color = Color(0.3, 0.8, 1.0)
