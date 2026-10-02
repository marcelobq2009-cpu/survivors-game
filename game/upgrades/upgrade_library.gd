class_name UpgradeLibrary
extends RefCounted
## Carrega todos os UpgradeData de uma pasta (padrao: data/upgrades/).
## Assim, novo upgrade = novo .tres, sem mexer em codigo.

const DEFAULT_DIR := "res://data/upgrades/"


static func load_all(dir: String = DEFAULT_DIR) -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	# list_directory funciona tambem no jogo exportado (web/celular).
	for file_name: String in ResourceLoader.list_directory(dir):
		if not file_name.ends_with(".tres"):
			continue
		var res := load(dir.path_join(file_name)) as UpgradeData
		if res:
			result.append(res)
	return result
