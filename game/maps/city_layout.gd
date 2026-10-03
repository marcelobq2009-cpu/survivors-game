class_name CityLayout
extends Resource
## Parametros de uma cidade gerada pelo CityBuilder (data/maps/layouts/*.tres).
## Mudar estes numeros muda o mapa inteiro (outra cidade = outro .tres).

@export var seed: int = 1
## Metade do tamanho da area jogavel (x, z) em metros.
@export var half_extents: Vector2 = Vector2(110, 90)

@export_group("Quarteiroes")
@export var block_size: float = 24.0
@export var street_width: float = 11.0
@export var floor_height: float = 3.0
@export var min_floors: int = 2
@export var max_floors: int = 9
## Cores das fachadas (sorteadas).
@export var palette: Array[Color] = []
@export_range(0.0, 1.0) var destroyed_ratio: float = 0.15
@export_range(0.0, 1.0) var plaza_ratio: float = 0.12

@export_group("Objetos")
## Carros abandonados por trecho de rua (media).
@export var cars_per_street: float = 0.8
@export_range(0.0, 1.0) var barricade_chance: float = 0.15
@export var rubble_per_block: float = 1.0
@export var bus_color: Color = Color(0.95, 0.75, 0.1)

@export_group("Cores do chao")
@export var asphalt_color: Color = Color(0.2, 0.2, 0.22)
@export var sidewalk_color: Color = Color(0.55, 0.53, 0.5)
@export var grass_color: Color = Color(0.25, 0.42, 0.22)
@export var lane_color: Color = Color(0.85, 0.75, 0.3)

@export_group("Rio de Janeiro")
## Praia ao sul: avenida + calcadao de ondas + areia + mar.
@export var beach_south: bool = false
@export var beach_depth: float = 30.0
@export var sand_color: Color = Color(0.86, 0.78, 0.58)
@export var sea_color: Color = Color(0.1, 0.38, 0.5)
## Morro com comunidade ao norte (fora da area jogavel, cenario).
@export var morro_north: bool = false
@export var morro_houses: int = 260
@export var cristo: bool = false
@export var sugarloaf: bool = false
