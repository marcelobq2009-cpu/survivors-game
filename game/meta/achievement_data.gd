class_name AchievementData
extends ContentData
## Uma conquista (data/achievements/*.tres).
## A condicao e a lista `unlock_requirements` (herdada): cumpriu tudo = conquistou.

@export var reward_gold: int = 50
## Escondida ate ser conquistada.
@export var hidden: bool = false
