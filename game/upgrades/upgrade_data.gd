class_name UpgradeData
extends Resource
## Uma carta de upgrade. Novo upgrade = novo .tres em data/upgrades/
## (o jogo carrega todos os .tres dessa pasta automaticamente).

enum Kind {
	NEW_WEAPON,   ## Da a arma `weapon` ao jogador.
	WEAPON_STAT,  ## Melhora `stat` da arma `weapon` (sobe o nivel da arma).
	PLAYER_STAT,  ## Melhora `stat` do jogador (passiva).
	HEAL,         ## Cura `value` de vida (carta "reserva").
	EVOLVE,       ## Troca `weapon` pela versao evoluida `evolves_to`.
	GOLD,         ## Da `value` de ouro (carta "reserva").
}

@export var id: StringName = &"upgrade"
@export var title: String = "Upgrade"
@export_multiline var description: String = ""
@export var kind: Kind = Kind.PLAYER_STAT
@export var weapon: WeaponData
## Jogador: max_health, move_speed, pickup_radius, damage_mult, area_mult,
## cooldown_mult, armor, regen, crit_chance, crit_damage, projectile_bonus,
## xp_mult, gold_mult. Arma: damage, cooldown, area, projectile_speed,
## projectile_count, spread_degrees, pierce, lifetime, target_range, knockback.
@export var stat: StringName = &""
## Quanto somar (ou multiplicar, se is_multiplier).
@export var value: float = 0.0
@export var is_multiplier: bool = false
## Quantas vezes pode ser escolhido na partida (0 = sem limite).
@export var max_picks: int = 5
## Chance relativa de aparecer no sorteio.
@export var weight: float = 1.0
## Categoria de build (dano, critico, defesa, area...). So informativa/UI.
@export var tag: StringName = &""

@export_group("Requisitos e evolucao")
## Nivel minimo da arma `weapon` para aparecer (EVOLVE usa isto).
@export var requires_weapon_level: int = 0
## Ids de upgrades que precisam ter sido escolhidos antes (combinacoes).
@export var requires_upgrades: Array[StringName] = []
## EVOLVE: arma evoluida.
@export var evolves_to: WeaponData

@export_group("Visual")
@export var icon: Texture2D
@export var color: Color = Color.WHITE
