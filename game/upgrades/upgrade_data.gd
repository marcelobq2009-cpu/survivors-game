class_name UpgradeData
extends Resource
## Uma carta de upgrade. Novo upgrade = novo .tres em data/upgrades/
## (o jogo carrega todos os .tres dessa pasta automaticamente).

enum Kind {
	NEW_WEAPON,   ## Da a arma `weapon` ao jogador.
	WEAPON_STAT,  ## Melhora `stat` da arma `weapon` (precisa ja ter a arma).
	PLAYER_STAT,  ## Melhora `stat` do jogador.
	HEAL,         ## Cura `value` de vida (carta "reserva").
}

@export var id: StringName = &"upgrade"
@export var title: String = "Upgrade"
@export_multiline var description: String = ""
@export var kind: Kind = Kind.PLAYER_STAT
@export var weapon: WeaponData
## Nome do stat. Jogador: max_health, move_speed, pickup_radius, damage_mult,
## area_mult, cooldown_mult. Arma: damage, cooldown, area, projectile_count, pierce.
@export var stat: StringName = &""
## Quanto somar (ou multiplicar, se is_multiplier).
@export var value: float = 0.0
@export var is_multiplier: bool = false
## Quantas vezes pode ser escolhido na partida (0 = sem limite).
@export var max_picks: int = 5
## Chance relativa de aparecer no sorteio.
@export var weight: float = 1.0
@export_group("Visual")
@export var icon: Texture2D
@export var color: Color = Color.WHITE
