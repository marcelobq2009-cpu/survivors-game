class_name Player
extends Node2D
## Jogador: anda (teclado ou joystick virtual), carrega as armas, leva dano
## (via Events.player_contact) e aplica upgrades (via Events.upgrade_chosen).
## Nao usa fisica: so precisa andar livre num mapa aberto.

const FLASH_TIME := 0.12
const FLASH_COLOR := Color(3.0, 3.0, 3.0)

@export var data: PlayerData

var stats: PlayerStats
var health: Health
var weapons: Dictionary[StringName, Weapon] = {}

var _flash_left: float = 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var weapon_holder: Node2D = $Weapons


func _ready() -> void:
	stats = PlayerStats.from_data(data)
	health = Health.new(stats.max_health, data.invincibility_time)
	sprite.texture = data.texture
	sprite.modulate = data.color
	var tex_size := data.texture.get_size().x if data.texture else 64.0
	sprite.scale = Vector2.ONE * (data.radius * 2.0 / tex_size)
	GameState.player_radius = data.radius
	_sync_state()
	Events.player_contact.connect(_on_player_contact)
	Events.upgrade_chosen.connect(_on_upgrade_chosen)
	if data.starting_weapon:
		add_weapon(data.starting_weapon)
	Events.player_health_changed.emit(health.current, health.max_value)


func _physics_process(delta: float) -> void:
	if health.is_dead():
		return
	# O joystick virtual "aperta" as mesmas acoes, entao isto cobre os dois.
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	global_position += input * stats.move_speed * delta
	if input.x != 0.0:
		sprite.flip_h = input.x < 0.0
	health.update(delta)
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			sprite.modulate = data.color
	_sync_state()


func add_weapon(weapon_data: WeaponData) -> void:
	if weapons.has(weapon_data.id) or weapon_data.scene == null:
		return
	var weapon := weapon_data.scene.instantiate() as Weapon
	weapon_holder.add_child(weapon)
	weapon.setup(weapon_data, stats)
	weapons[weapon_data.id] = weapon
	GameState.owned_weapons.append(weapon_data.id)


func _sync_state() -> void:
	GameState.player_position = global_position
	GameState.pickup_radius = stats.pickup_radius


func _on_player_contact(damage: float) -> void:
	var applied := health.take_damage(damage)
	if applied <= 0.0:
		return
	_flash_left = FLASH_TIME
	sprite.modulate = FLASH_COLOR
	Audio.play(&"player_hurt")
	Events.player_damaged.emit(applied)
	Events.camera_shake_requested.emit(8.0)
	Events.player_health_changed.emit(health.current, health.max_value)
	if health.is_dead():
		Events.player_died.emit()


func _on_upgrade_chosen(u: UpgradeData) -> void:
	match u.kind:
		UpgradeData.Kind.NEW_WEAPON:
			add_weapon(u.weapon)
		UpgradeData.Kind.WEAPON_STAT:
			for w: Weapon in weapons.values():
				if u.weapon == null or w.data.id == u.weapon.id:
					w.apply_upgrade(u.stat, u.value, u.is_multiplier)
		UpgradeData.Kind.PLAYER_STAT:
			stats.apply(u.stat, u.value, u.is_multiplier)
			if u.stat == &"max_health":
				health.set_max(stats.max_health)
		UpgradeData.Kind.HEAL:
			health.heal(u.value)
	Events.player_health_changed.emit(health.current, health.max_value)
