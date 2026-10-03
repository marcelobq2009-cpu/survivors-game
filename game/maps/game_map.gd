class_name GameMap
extends Node3D
## Base de todo mapa jogavel. A cena do mapa (MapData.scene) tem como raiz um
## GameMap (ou subclasse). Depois de build(), os outros sistemas usam:
##   grid          obstaculos (zumbis/spawner)
##   bounds        area jogavel
##   player_spawn  onde o jogador comeca

const GROUP := &"game_map"

var grid: MapGrid
var bounds: Rect2
var player_spawn: Vector2 = Vector2.ZERO


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	build()


## Subclasses constroem o mapa aqui e preenchem grid/bounds/player_spawn.
func build() -> void:
	bounds = Rect2(-50, -50, 100, 100)
	grid = MapGrid.new(bounds)


static func find(tree: SceneTree) -> GameMap:
	return tree.get_first_node_in_group(GROUP) as GameMap


## Ponto aleatorio livre dentro do mapa a `distance` de `center` (ou o centro se falhar).
func random_free_point_around(center: Vector2, distance: float, rng: RandomNumberGenerator,
		attempts: int = 10) -> Vector2:
	for i: int in attempts:
		var p := center + Vector2.from_angle(rng.randf() * TAU) * distance
		if grid.is_free(p):
			return p
	return Vector2.INF
