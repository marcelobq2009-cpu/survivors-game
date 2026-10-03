extends Node
## Save local (autoload "Save"). Guarda o ProfileData em user://save.json
## (no navegador vai para o armazenamento do site).
## Seguranca: grava num arquivo temporario e so depois troca (nao corrompe se
## o jogo fechar no meio), e mantem uma copia .bak da versao anterior.

signal profile_changed

const DEFAULT_PATH := "user://save.json"
const VERSION := 2

var profile: ProfileData = ProfileData.new()
var _path: String = DEFAULT_PATH


func _ready() -> void:
	load_data()


## Troca o arquivo de save (os testes usam um arquivo separado para nao
## mexer no seu progresso real). Recarrega o perfil do novo arquivo.
func set_storage_path(path: String) -> void:
	_path = path
	load_data()


func save_data() -> void:
	var payload := JSON.stringify({"version": VERSION, "profile": profile.to_dict()}, "\t")
	var file := FileAccess.open(_path + ".tmp", FileAccess.WRITE)
	if file == null:
		push_warning("Save: nao foi possivel gravar (%s)" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(payload)
	file.close()
	if FileAccess.file_exists(_path):
		DirAccess.copy_absolute(_path, _path + ".bak")
	DirAccess.rename_absolute(_path + ".tmp", _path)
	profile_changed.emit()


func load_data() -> void:
	var data := _read(_path)
	if data.is_empty():
		data = _read(_path + ".bak")  # Arquivo principal ausente/corrompido.
	profile = _migrate(data)
	apply_runtime_settings()
	profile_changed.emit()


## Aplica preferencias que mudam regras em tempo de execucao (debug).
func apply_runtime_settings() -> void:
	Config.game.use_debug_match_duration = profile.settings.debug_short_match \
			and Config.game.debug_tools_enabled()


## Apaga todo o progresso (usado pelo debug / "restaurar").
func reset_progress() -> void:
	var settings := profile.settings
	profile = ProfileData.new()
	profile.settings = settings
	save_data()


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Converte saves antigos para o formato atual.
func _migrate(data: Dictionary) -> ProfileData:
	if data.is_empty():
		return ProfileData.new()
	var version := int(data.get("version", 1))
	if version >= 2:
		var p: Variant = data.get("profile", {})
		return ProfileData.from_dict(p if p is Dictionary else {})
	# Versao 1 (prototipo): so tinha best_time e best_kills.
	var migrated := ProfileData.new()
	migrated.total_kills = int(data.get("best_kills", 0))
	return migrated
