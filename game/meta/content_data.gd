class_name ContentData
extends Resource
## Base de todo conteudo que aparece em telas de selecao e pode ser
## bloqueado/desbloqueado (personagens, mapas, conquistas...).

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
## Cor de destaque nas telas (cards, bordas).
@export var color: Color = Color.WHITE
## Ordem nas listas (menor aparece primeiro).
@export var sort_order: int = 0
## Todos precisam ser cumpridos. Vazio = desbloqueado desde o inicio.
@export var unlock_requirements: Array[UnlockRequirement] = []
## Aparece na lista mesmo bloqueado, mas como "em breve" (sem como jogar ainda).
@export var coming_soon: bool = false


func requirements_text() -> String:
	var parts: PackedStringArray = []
	for r: UnlockRequirement in unlock_requirements:
		parts.append(r.describe())
	return "\n".join(parts)
