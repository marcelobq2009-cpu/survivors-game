class_name EnemyManager
extends Node2D
## Dono de todos os inimigos vivos. A cada frame:
## 1) reconstroi a SpatialGrid; 2) move cada inimigo em direcao ao jogador com
## separacao simples; 3) checa contato com o jogador.
## Armas e projeteis usam `grid` para achar alvos.

const ENEMY_SCENE: PackedScene = preload("res://game/enemies/enemy.tscn")
const GROUP := &"enemy_manager"
## Maior raio de inimigo esperado (usado para margem nas buscas).
const MAX_ENEMY_RADIUS := 40.0
const SEPARATION_STRENGTH := 0.6

var grid: SpatialGrid = SpatialGrid.new(64.0)
var enemies: Array[Enemy] = []

var _neighbors: Array[Node2D] = []
var _frame_parity: int = 0


func _enter_tree() -> void:
	add_to_group(GROUP)


## Atalho para outros sistemas acharem o manager pela arvore de cenas.
static func find(tree: SceneTree) -> EnemyManager:
	return tree.get_first_node_in_group(GROUP) as EnemyManager


func count() -> int:
	return enemies.size()


func spawn(data: EnemyData, pos: Vector2, health_mult: float = 1.0) -> Enemy:
	var enemy := Pool.acquire(ENEMY_SCENE, self) as Enemy
	enemy.setup(data, pos, health_mult, self)
	enemy.manager_index = enemies.size()
	enemies.append(enemy)
	return enemy


## Remove do array em O(1) trocando com o ultimo, e devolve ao Pool.
func remove(enemy: Enemy) -> void:
	var i := enemy.manager_index
	if i < 0 or i >= enemies.size() or enemies[i] != enemy:
		return
	var last: Enemy = enemies[enemies.size() - 1]
	enemies[i] = last
	last.manager_index = i
	enemies.pop_back()
	enemy.manager_index = -1
	Pool.release(enemy)


func _physics_process(delta: float) -> void:
	# Obs.: usamos `position` (e nao global_position, mais caro) porque o
	# EnemyManager fica na origem do mundo — as duas sao iguais aqui.
	grid.clear()
	for e: Enemy in enemies:
		grid.insert(e)

	var player_pos := GameState.player_position
	var player_radius := GameState.player_radius
	var recycle_dist := EnemySpawner.offscreen_radius(get_viewport()) * 1.6
	var contact_damage := 0.0
	# Separacao e o calculo mais caro: cada inimigo faz em frames alternados.
	_frame_parity = 1 - _frame_parity
	var i := 0

	for e: Enemy in enemies:
		i += 1
		var pos := e.position
		var to_player := player_pos - pos
		var dist := to_player.length()

		# Inimigo muito longe (ficou para tras): reaparece do outro lado.
		if dist > recycle_dist:
			e.position = player_pos + EnemySpawner.ring_offset(get_viewport())
			continue

		var dir := to_player / dist if dist > 0.001 else Vector2.ZERO
		var step := (dir * e.speed + e.knockback) * delta

		# Separacao: empurra para longe dos vizinhos encostados.
		if i % 2 == _frame_parity:
			grid.query_radius(pos, e.radius * 2.0, _neighbors)
			var push := Vector2.ZERO
			for n: Node2D in _neighbors:
				if n == e:
					continue
				var away := pos - n.position
				var d := away.length()
				var min_d := e.radius + (n as Enemy).radius
				if d < min_d and d > 0.001:
					push += away / d * (min_d - d)
			# Correcao parcial da sobreposicao (fica suave em poucos frames).
			step += push * SEPARATION_STRENGTH

		e.position = pos + step
		if dir.x != 0.0:
			e.sprite.flip_h = dir.x < 0.0
		e.tick(delta)

		if dist < e.radius + player_radius:
			contact_damage = maxf(contact_damage, e.data.contact_damage)

	if contact_damage > 0.0:
		Events.player_contact.emit(contact_damage)
