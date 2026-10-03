class_name UnlockRequirement
extends Resource
## Requisito de desbloqueio (base). Subclasses: SurviveRequirement,
## KillsRequirement, LevelRequirement, BossRequirement, AchievementRequirement.
## Cada um olha o progresso salvo (ProfileData) e diz se foi cumprido.


func is_met(_profile: ProfileData) -> bool:
	return true


## Texto curto para a tela de bloqueado (ex.: "Sobreviva 30 min no Rio de Janeiro").
func describe() -> String:
	return ""


## Progresso de 0 a 1 (barra na tela de bloqueado).
func progress(profile: ProfileData) -> float:
	return 1.0 if is_met(profile) else 0.0
