extends Node
## Registro de conteudo (autoload "Content").
## Carrega todos os .tres das pastas de data/ uma vez. Para adicionar um
## personagem/mapa/conquista basta criar o .tres na pasta certa.

const CHARACTERS_DIR := "res://data/characters/"
const MAPS_DIR := "res://data/maps/"
const ACHIEVEMENTS_DIR := "res://data/achievements/"

var characters: Array[CharacterData] = []
var maps: Array[MapData] = []
var achievements: Array[AchievementData] = []


func _ready() -> void:
	reload()


func reload() -> void:
	characters.assign(_load_dir(CHARACTERS_DIR))
	maps.assign(_load_dir(MAPS_DIR))
	achievements.assign(_load_dir(ACHIEVEMENTS_DIR))


func find_character(id: StringName) -> CharacterData:
	for c: CharacterData in characters:
		if c.id == id:
			return c
	return null


func find_map(id: StringName) -> MapData:
	for m: MapData in maps:
		if m.id == id:
			return m
	return null


func find_achievement(id: StringName) -> AchievementData:
	for a: AchievementData in achievements:
		if a.id == id:
			return a
	return null


## Tudo que pode ser desbloqueado (personagens + mapas).
func unlockables() -> Array[ContentData]:
	var all: Array[ContentData] = []
	all.append_array(characters)
	all.append_array(maps)
	return all


func _load_dir(dir: String) -> Array[ContentData]:
	var out: Array[ContentData] = []
	for file_name: String in ResourceLoader.list_directory(dir):
		if file_name.ends_with(".tres"):
			var res := load(dir.path_join(file_name)) as ContentData
			if res:
				out.append(res)
	out.sort_custom(func(a: ContentData, b: ContentData) -> bool:
		return a.sort_order < b.sort_order if a.sort_order != b.sort_order else String(a.id) < String(b.id))
	return out
