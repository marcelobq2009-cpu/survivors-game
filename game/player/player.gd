class_name Player
extends CharacterBody3D
## Jogador 3D: anda (teclado ou joystick) relativo a camera, colide com
## predios/carros, carrega as armas, leva dano (Events.player_contact) e aplica
## upgrades (Events.upgrade_chosen). O personagem vem de GameState.setup.

const GROUP := &"player"
const TURN_SPEED := 14.0
const HEALTH_SIGNAL_INTERVAL := 0.25

var character: CharacterData
var stats: PlayerStats
var health: Health
var weapons: Dictionary[StringName, Weapon] = {}
var facing: Vector2 = Vector2(0, 1)

var _model: Node3D
var _rig: CameraRig
var _walk_time: float = 0.0
var _health_signal_left: float = 0.0
var _last_health: float = -1.0

@onready var model_root: Node3D = $Model
@onready var weapon_holder: Node3D = $Weapons


func _enter_tree() -> void:
	add_to_group(GROUP)


static func find(tree: SceneTree) -> Player:
	return tree.get_first_node_in_group(GROUP) as Player


func _ready() -> void:
	if character == null:
		character = GameState.setup.character
	if character == null:
		character = CharacterData.new()
	stats = PlayerStats.from_character(character)
	for u: UpgradeData in character.passive_bonuses:
		stats.apply(u.stat, u.value, u.is_multiplier)
	health = Health.new(stats.max_health, character.invincibility_time)
	health.armor = stats.armor
	health.regen = stats.regen
	_build_model()
	GameState.player_radius = character.radius
	_sync_state()
	Events.player_contact.connect(_on_player_contact)
	Events.upgrade_chosen.connect(_on_upgrade_chosen)
	Events.player_healed.connect(func(amount: float) -> void:
		health.heal(amount)
		Events.player_health_changed.emit(health.current, health.max_value))
	if character.starting_weapon:
		add_weapon(character.starting_weapon, false)
	Events.player_health_changed.emit(health.current, health.max_value)


func _build_model() -> void:
	if character.model_scene:
		_model = character.model_scene.instantiate() as Node3D
	else:
		var mi := MeshInstance3D.new()
		mi.mesh = PlaceholderMeshes.human(character.color)
		_model = mi
	model_root.add_child(_model)


func _physics_process(delta: float) -> void:
	if health.is_dead():
		return
	if _rig == null:
		_rig = CameraRig.find(get_tree())
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var dir := _rig.screen_to_ground(input) if _rig else input
	velocity = GroundPlane.to_3d(dir * stats.move_speed)
	move_and_slide()
	position.y = 0.0
	if dir.length() > 0.1:
		facing = dir.normalized()
		_walk_time += delta
	# Gira o modelo suavemente para onde anda e balanca ao andar.
	model_root.rotation.y = lerp_angle(model_root.rotation.y, GroundPlane.heading(facing),
			minf(1.0, TURN_SPEED * delta))
	model_root.position.y = absf(sin(_walk_time * 10.0)) * 0.08 if dir.length() > 0.1 else 0.0
	health.update(delta)
	# Pisca enquanto esta invulneravel (feedback de dano).
	model_root.visible = not health.is_invincible() or fmod(Time.get_ticks_msec() / 80.0, 2.0) < 1.0
	_health_signal_left -= delta
	if _health_signal_left <= 0.0 and not is_equal_approx(_last_health, health.current):
		_health_signal_left = HEALTH_SIGNAL_INTERVAL
		_last_health = health.current
		Events.player_health_changed.emit(health.current, health.max_value)
	_sync_state()


func add_weapon(weapon_data: WeaponData, announce: bool = true) -> void:
	if weapons.has(weapon_data.id) or weapon_data.scene == null:
		return
	var weapon := weapon_data.scene.instantiate() as Weapon
	weapon_holder.add_child(weapon)
	weapon.setup(weapon_data, stats)
	weapons[weapon_data.id] = weapon
	GameState.owned_weapons.append(weapon_data.id)
	GameState.weapon_levels[weapon_data.id] = 1
	Events.weapons_changed.emit()
	if announce:
		Events.announcement.emit("NOVA ARMA: %s" % weapon_data.display_name.to_upper(), Color(0.55, 1, 0.5))


## Troca uma arma pela evolucao dela (mantem os bonus de stats ja ganhos).
func evolve_weapon(from: WeaponData, to: WeaponData) -> void:
	var old: Weapon = weapons.get(from.id)
	if old == null:
		return
	var level := GameState.weapon_level(from.id)
	weapons.erase(from.id)
	GameState.owned_weapons.erase(from.id)
	old.queue_free()
	add_weapon(to, false)
	GameState.weapon_levels[to.id] = level + 1
	Events.announcement.emit("ARMA EVOLUIU: %s" % to.display_name.to_upper(), Color(1, 0.85, 0.3))


func teleport(pos: Vector2) -> void:
	global_position = GroundPlane.to_3d(pos)
	_sync_state()


func _sync_state() -> void:
	GameState.player_position = GroundPlane.to_2d(global_position)
	GameState.pickup_radius = stats.pickup_radius
	GameState.xp_mult = stats.xp_mult
	GameState.gold_mult = stats.gold_mult


func _on_player_contact(damage: float) -> void:
	var applied := health.take_damage(damage)
	if applied <= 0.0:
		return
	Audio.play(&"player_hurt")
	Audio.vibrate(40)
	Events.player_damaged.emit(applied)
	Events.camera_shake_requested.emit(6.0)
	_last_health = health.current
	Events.player_health_changed.emit(health.current, health.max_value)
	if health.is_dead():
		model_root.visible = true
		model_root.rotation.x = -PI * 0.5  # "cai" no chao
		Events.player_died.emit()


func _on_upgrade_chosen(u: UpgradeData) -> void:
	match u.kind:
		UpgradeData.Kind.NEW_WEAPON:
			add_weapon(u.weapon)
		UpgradeData.Kind.WEAPON_STAT:
			for w: Weapon in weapons.values():
				if u.weapon == null or w.data.id == u.weapon.id:
					w.apply_upgrade(u.stat, u.value, u.is_multiplier)
					GameState.weapon_levels[w.data.id] = GameState.weapon_level(w.data.id) + 1
			Events.weapons_changed.emit()
		UpgradeData.Kind.PLAYER_STAT:
			stats.apply(u.stat, u.value, u.is_multiplier)
			health.set_max(stats.max_health)
			health.armor = stats.armor
			health.regen = stats.regen
		UpgradeData.Kind.HEAL:
			health.heal(u.value)
		UpgradeData.Kind.EVOLVE:
			evolve_weapon(u.weapon, u.evolves_to)
		UpgradeData.Kind.GOLD:
			Events.gold_collected.emit(roundi(u.value))
	Events.player_health_changed.emit(health.current, health.max_value)
