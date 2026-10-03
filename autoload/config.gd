extends Node
## Configuracao central (autoload "Config").
## Carrega data/config/game_config.tres. Usamos uma COPIA, para o painel de
## debug poder mudar valores durante o jogo sem alterar o arquivo.

const CONFIG_PATH := "res://data/config/game_config.tres"

var game: GameConfig


func _init() -> void:
	var base := load(CONFIG_PATH) as GameConfig
	game = base.duplicate() as GameConfig if base else GameConfig.new()
