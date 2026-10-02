class_name WeaponData
extends Resource
## Stats base de uma arma. Nova arma = novo .tres em data/weapons/.
## `scene` define o COMPORTAMENTO (ex.: projetil, aura). Armas novas que usam um
## comportamento existente nao precisam de codigo novo.

@export var id: StringName = &"weapon"
@export var display_name: String = "Weapon"
@export_multiline var description: String = ""
## Cena com o script de comportamento (deve estender Weapon).
@export var scene: PackedScene
@export_group("Stats")
@export var damage: float = 5.0
## Segundos entre ataques.
@export var cooldown: float = 1.0
## Raio (aura) ou tamanho (projetil) em pixels.
@export var area: float = 8.0
@export var projectile_speed: float = 500.0
@export var projectile_count: int = 1
## Quantos inimigos o projetil atravessa antes de sumir.
@export var pierce: int = 1
## Tempo de vida do projetil em segundos.
@export var lifetime: float = 1.5
## Alcance para procurar alvo.
@export var target_range: float = 450.0
@export_group("Visual")
@export var texture: Texture2D
@export var color: Color = Color.WHITE
