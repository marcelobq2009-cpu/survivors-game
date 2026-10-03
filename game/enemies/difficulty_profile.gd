class_name DifficultyProfile
extends Resource
## Como a dificuldade cresce com o tempo (data/difficulty/*.tres).
## Usado pelo DifficultyDirector. Nao e so "mais vida": combina quantidade,
## dano, velocidade, elites, chefes e eventos de horda.

@export_group("Crescimento por minuto")
## +X de vida por minuto (0.06 = +6%/min, linear).
@export var health_growth_per_min: float = 0.05
@export var damage_growth_per_min: float = 0.03
@export var speed_growth_per_min: float = 0.01
@export var max_speed_mult: float = 1.45
## Spawns por segundo ficam X% mais frequentes por minuto.
@export var spawn_rate_growth_per_min: float = 0.04
@export var max_spawn_rate_mult: float = 4.0

@export_group("Elites")
@export var elite_chance_start: float = 0.0
@export var elite_chance_per_min: float = 0.004
@export var elite_chance_max: float = 0.12
@export var elite_health_mult: float = 6.0
@export var elite_damage_mult: float = 1.5
@export var elite_scale: float = 1.4
@export var elite_xp_mult: int = 6

@export_group("Chefes")
## Um chefe a cada X segundos (0 = sem chefes).
@export var boss_interval: float = 300.0
## Chefes em rodizio.
@export var bosses: Array[EnemyData] = []
## Cada chefe seguinte tem +X de vida.
@export var boss_health_growth: float = 0.6

@export_group("Eventos de horda")
## Um "cerco" a cada X segundos (0 = desligado).
@export var horde_interval: float = 150.0
@export var horde_size: int = 30
@export var horde_size_growth_per_min: float = 2.0

@export_group("Eventos especiais")
## Um evento (queda de suprimentos ou area contaminada) a cada X segundos.
@export var event_interval: float = 95.0
## Area contaminada so aparece depois deste tempo.
@export var toxic_from: float = 180.0

@export_group("Depois do fim da timeline (ranqueado)")
## Acelera tudo depois que acabam as ondas definidas (ranqueado infinito).
@export var overtime_growth_mult: float = 1.5
