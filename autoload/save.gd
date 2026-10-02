extends Node
## Salvamento simples em JSON (autoload "Save").
## Por enquanto guarda so os recordes. Fica em user://save.json
## (no navegador, vai para o armazenamento local do site).

const PATH := "user://save.json"

var best_time: float = 0.0
var best_kills: int = 0


func _ready() -> void:
	load_data()


## Registra o resultado de uma partida; retorna true se bateu algum recorde.
func submit_run(time: float, kills: int) -> bool:
	var improved := false
	if time > best_time:
		best_time = time
		improved = true
	if kills > best_kills:
		best_kills = kills
		improved = true
	if improved:
		save_data()
	return improved


func save_data() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Save: nao foi possivel gravar %s" % PATH)
		return
	file.store_string(JSON.stringify({"best_time": best_time, "best_kills": best_kills}))


func load_data() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary:
		var data: Dictionary = parsed
		best_time = float(data.get("best_time", 0.0))
		best_kills = int(data.get("best_kills", 0))
