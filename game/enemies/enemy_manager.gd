class_name EnemyManager
extends Node3D
## Dono de todos os zumbis vivos (EnemyAgent). A cada frame:
## 1) reconstroi a SpatialGrid; 2) move cada zumbi em direcao ao jogador,
## contornando obstaculos pela grade do mapa e se afastando dos vizinhos;
## 3) roda comportamentos especiais (explodir, investida); 4) checa contato;
## 5) desenha todos de uma vez (um InstanceRenderer por tipo de zumbi).
## Armas e projeteis usam `grid` para achar alvos e `damage_agent` para ferir.

const GROUP := &"enemy_manager"
const ZOMBIE_SHADER: Shader = preload("res://game/enemies/zombie.gdshader")
## Maior raio de inimigo esperado (margem nas buscas da grade).
const MAX_ENEMY_RADIUS := 1.6
const SEPARATION := 0.5
const PROBE := 0.9
const FLASH_TIME := 0.1
const KNOCKBACK_DECAY := 7.0

enum State { NORMAL, FUSE, WINDUP, CHARGE }

var grid: SpatialGrid = SpatialGrid.new(2.0)
var agents: Array[EnemyAgent] = []

var _free: Array[EnemyAgent] = []
var _renderers: Dictionary = {}  # EnemyData -> InstanceRenderer
var _material: ShaderMaterial
var _neighbors: Array[EnemyAgent] = []
var _map: GameMap
var _parity: int = 0
var _next_uid: int = 1
var _time: float = 0.0
var _rng := RandomNumberGenerator.new()


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = ZOMBIE_SHADER
	_rng.randomize()


static func find(tree: SceneTree) -> EnemyManager:
	return tree.get_first_node_in_group(GROUP) as EnemyManager


func count() -> int:
	return agents.size()


## Cria um zumbi. Multiplicadores vem do DifficultyDirector.
func spawn(data: EnemyData, pos: Vector2, health_mult: float = 1.0, damage_mult: float = 1.0,
		speed_mult: float = 1.0, elite: bool = false, elite_profile: DifficultyProfile = null) -> EnemyAgent:
	var a: EnemyAgent = _free.pop_back() if not _free.is_empty() else EnemyAgent.new()
	a.uid = _next_uid
	_next_uid += 1
	a.data = data
	a.pos = pos
	a.elite = elite
	var hp_mult := health_mult * Config.game.enemy_health_multiplier
	var dmg_mult := damage_mult * Config.game.enemy_damage_multiplier
	a.scale = 1.0
	a.xp = data.xp_value
	if elite and elite_profile:
		hp_mult *= elite_profile.elite_health_mult
		dmg_mult *= elite_profile.elite_damage_mult
		a.scale = elite_profile.elite_scale
		a.xp *= elite_profile.elite_xp_mult
	a.max_hp = data.max_health * hp_mult
	a.hp = a.max_hp
	a.damage = data.contact_damage * dmg_mult
	a.speed = data.speed * speed_mult * _rng.randf_range(0.9, 1.1)
	a.radius = data.radius * a.scale
	a.alive = true
	a.knockback = Vector2.ZERO
	a.flash = 0.0
	a.anim_phase = _rng.randf() * TAU
	a.state = State.NORMAL
	a.state_timer = data.charge_interval * _rng.randf_range(0.5, 1.0)
	a.index = agents.size()
	agents.append(a)
	if not _renderers.has(data):
		_create_renderer(data)
	return a


## Fere um zumbi. `source_id` = arma (para estatisticas); vazio = nao conta.
func damage_agent(a: EnemyAgent, amount: float, crit: bool, push: Vector2, source_id: StringName) -> void:
	if not a.alive or amount <= 0.0:
		return
	var applied := minf(amount, a.hp)
	a.hp -= amount
	a.flash = 1.0
	a.knockback += push * (1.0 - a.data.knockback_resistance)
	if source_id != &"":
		GameState.add_damage(source_id, applied)
	Events.damage_dealt.emit(a.pos, amount, crit)
	if a.hp <= 0.0:
		kill(a)


func kill(a: EnemyAgent) -> void:
	if not a.alive:
		return
	a.alive = false
	Events.enemy_killed.emit(a)
	if a.data.is_boss:
		Events.boss_killed.emit(a.data)
	_remove(a)


## Debug: mata todos (conta abates e solta XP normalmente).
func kill_all() -> void:
	for a: EnemyAgent in agents.duplicate():
		kill(a)


## Chefe vivo (para a barra de vida do HUD), ou null.
func current_boss() -> EnemyAgent:
	for a: EnemyAgent in agents:
		if a.data.is_boss:
			return a
	return null


func _remove(a: EnemyAgent) -> void:
	var i := a.index
	if i < 0 or i >= agents.size() or agents[i] != a:
		return
	var last: EnemyAgent = agents[agents.size() - 1]
	agents[i] = last
	last.index = i
	agents.pop_back()
	a.index = -1
	_free.append(a)


func _physics_process(delta: float) -> void:
	if _map == null:
		_map = GameMap.find(get_tree())
	_time += delta
	grid.clear()
	for a: EnemyAgent in agents:
		grid.insert(a)

	var player_pos := GameState.player_position
	var player_radius := GameState.player_radius
	var rig := CameraRig.find(get_tree())
	var recycle_dist := (rig.visible_ground_radius() if rig else 30.0) * 1.8
	var contact := 0.0
	_parity = 1 - _parity
	var i := 0

	# Iteramos de tras para frente: explosoes podem remover zumbis no meio.
	for idx: int in range(agents.size() - 1, -1, -1):
		if idx >= agents.size():
			continue
		var a: EnemyAgent = agents[idx]
		i += 1
		var to_player := player_pos - a.pos
		var dist := to_player.length()

		if dist > recycle_dist and not a.data.is_boss:
			_relocate(a, player_pos, rig)
			continue

		var dir := to_player / dist if dist > 0.001 else Vector2.ZERO
		var speed := a.speed
		match a.data.behavior:
			EnemyData.Behavior.EXPLODER:
				if a.state == State.NORMAL and dist < a.data.explode_trigger_distance:
					a.state = State.FUSE
					a.state_timer = a.data.explode_fuse
				if a.state == State.FUSE:
					speed = 0.0
					a.flash = 0.5 + 0.5 * sin(_time * 30.0)
					a.state_timer -= delta
					if a.state_timer <= 0.0:
						_explode(a, player_pos)
						continue
			EnemyData.Behavior.CHARGER:
				speed = _update_charger(a, dir, dist, delta)
				if a.state == State.CHARGE:
					dir = a.charge_dir

		_move(a, dir, speed, delta, i, dist < 1.5)
		a.heading = lerp_angle(a.heading, GroundPlane.heading(dir), minf(1.0, 10.0 * delta)) \
				if dir != Vector2.ZERO else a.heading
		a.flash = maxf(0.0, a.flash - delta / FLASH_TIME) if a.state != State.FUSE else a.flash
		a.knockback = a.knockback.lerp(Vector2.ZERO, minf(1.0, KNOCKBACK_DECAY * delta))

		if dist < a.radius + player_radius:
			contact = maxf(contact, a.damage)

	if contact > 0.0:
		Events.player_contact.emit(contact)


func _process(_delta: float) -> void:
	for r: InstanceRenderer in _renderers.values():
		r.begin()
	for a: EnemyAgent in agents:
		var r: InstanceRenderer = _renderers[a.data]
		var bob := absf(sin(_time * a.speed * 4.0 + a.anim_phase)) * 0.07
		var shade := 0.82 + 0.18 * fposmod(a.uid * 0.618, 1.0)
		var s := a.data.model_scale * a.scale
		r.add(Vector3(a.pos.x, bob * s, a.pos.y), a.heading, s, Color(shade, shade, shade),
				Color(clampf(a.flash, 0.0, 1.0), 1.0 if a.elite else 0.0, 0.0, 0.0))
	for r: InstanceRenderer in _renderers.values():
		r.finish()


# --- Movimento ----------------------------------------------------------------

func _move(a: EnemyAgent, dir: Vector2, speed: float, delta: float, i: int,
		near_player: bool = false) -> void:
	# Colado no jogador: vai direto (um canto apertado nunca vira esconderijo).
	var blocked := _map != null and not near_player
	# Contorna paredes: se a frente esta bloqueada, tenta girar para um lado.
	if blocked and dir != Vector2.ZERO and _map.grid.is_blocked(a.pos + dir * PROBE):
		var side := 1.0 if (a.uid & 1) == 0 else -1.0
		var found := false
		for ang: float in [0.7, 1.3, 2.0]:
			for s: float in [side, -side]:
				var d2 := dir.rotated(ang * s)
				if _map.grid.is_free(a.pos + d2 * PROBE):
					dir = d2
					found = true
					break
			if found:
				break
	var step := (dir * speed + a.knockback) * delta

	# Separacao (metade dos zumbis por frame; e o calculo mais caro).
	if i % 2 == _parity:
		grid.query_radius(a.pos, a.radius * 2.0, _neighbors)
		var push := Vector2.ZERO
		for n: EnemyAgent in _neighbors:
			if n == a:
				continue
			var away := a.pos - n.pos
			var d := away.length()
			var min_d := a.radius + n.radius
			if d < min_d and d > 0.001:
				push += away / d * (min_d - d)
		step += push * SEPARATION

	var next := a.pos + step
	if blocked and _map.grid.is_blocked(next):
		# Desliza ao longo da parede (tenta so X ou so Y).
		if _map.grid.is_free(Vector2(next.x, a.pos.y)):
			next = Vector2(next.x, a.pos.y)
		elif _map.grid.is_free(Vector2(a.pos.x, next.y)):
			next = Vector2(a.pos.x, next.y)
		else:
			next = a.pos
	a.pos = next


func _relocate(a: EnemyAgent, player_pos: Vector2, rig: CameraRig) -> void:
	if _map == null:
		return
	var r := (rig.visible_ground_radius() if rig else 25.0) + 3.0
	var p := _map.random_free_point_around(player_pos, r, _rng, 6)
	if p != Vector2.INF:
		a.pos = p


# --- Comportamentos especiais -------------------------------------------------

func _explode(a: EnemyAgent, player_pos: Vector2) -> void:
	var radius := a.data.explode_radius * a.scale
	if a.pos.distance_to(player_pos) <= radius + GameState.player_radius:
		Events.player_contact.emit(a.data.explode_damage * (a.damage / maxf(0.01, a.data.contact_damage)))
	# Tambem fere os zumbis em volta (reacao em cadeia).
	var hit: Array[EnemyAgent] = []
	grid.query_radius(a.pos, radius, hit)
	for n: EnemyAgent in hit:
		if n != a and n.alive:
			damage_agent(n, a.data.explode_damage, false, (n.pos - a.pos).normalized() * 4.0, &"")
	Events.explosion.emit(a.pos, radius)
	Events.camera_shake_requested.emit(4.0)
	Audio.play(&"explosion", -4.0)
	kill(a)


## Investida (chefes): espera, para e pisca (aviso), depois corre em linha reta.
func _update_charger(a: EnemyAgent, dir: Vector2, dist: float, delta: float) -> float:
	a.state_timer -= delta
	match a.state:
		State.NORMAL:
			if a.state_timer <= 0.0 and dist < 16.0:
				a.state = State.WINDUP
				a.state_timer = 0.6
			return a.speed
		State.WINDUP:
			a.flash = 0.6
			if a.state_timer <= 0.0:
				a.state = State.CHARGE
				a.state_timer = a.data.charge_duration
				a.charge_dir = dir
				Events.camera_shake_requested.emit(2.0)
			return 0.0
		State.CHARGE:
			if a.state_timer <= 0.0:
				a.state = State.NORMAL
				a.state_timer = a.data.charge_interval
			return a.data.charge_speed
	return a.speed


func _create_renderer(data: EnemyData) -> void:
	var r := InstanceRenderer.new()
	r.name = "Render_%s" % data.id
	var mesh := data.mesh if data.mesh else PlaceholderMeshes.zombie(data.body_color, data.skin_color)
	r.setup(mesh, _material, 64, false)
	add_child(r)
	_renderers[data] = r
