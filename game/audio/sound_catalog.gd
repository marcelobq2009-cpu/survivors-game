class_name SoundCatalog
extends RefCounted
## Catalogo central de TODOS os efeitos sonoros (um lugar so).
## Cada entrada: canal (bus), prioridade, variacoes, volume, variacao de tom,
## intervalo minimo entre repeticoes, limite de copias simultaneas, se e
## posicional (3D), se e loop, a receita que gera o som e a legenda (acessibilidade).
##
## SUBSTITUIR POR ARQUIVOS REAIS: coloque em assets/audio/<pasta>/<id>_01.ogg,
## <id>_02.ogg ... (ou .wav/.mp3). Ex.: assets/audio/sfx/weapons/weapon_pistol_fire_01.ogg
## Os arquivos encontrados substituem as variacoes geradas por codigo.
##
## Prioridade (0-100): quanto maior, mais dificil de ser cortado quando ha
## muitos sons ao mesmo tempo (morte/chefe/explosivo > armas > ambiente).


const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const BUS_AMBIENCE := &"Ambience"
const BUS_ZOMBIES := &"Zombies"
const BUS_UI := &"UI"
const BUS_BOSSES := &"Bosses"
const BUS_ALERTS := &"Alerts"

## Pasta (dentro de assets/audio/) onde procurar arquivos para cada canal.
const FOLDERS: Dictionary = {
	BUS_SFX: "sfx", BUS_AMBIENCE: "ambient", BUS_ZOMBIES: "sfx/zombies", BUS_UI: "sfx/ui",
	BUS_BOSSES: "sfx/bosses", BUS_ALERTS: "sfx/alerts", BUS_MUSIC: "music",
}


class Def:
	extends RefCounted
	var id: StringName
	var bus: StringName = &"SFX"
	var priority: int = 50
	var variations: int = 1
	var volume_db: float = 0.0
	var pitch_var: float = 0.05
	var cooldown_ms: int = 40
	var max_instances: int = 4
	var spatial: bool = false
	var loop: bool = false
	var recipe: Callable
	var caption: String = ""


static func build() -> Dictionary:
	var c := {}
	# --- Armas (cada uma com timbre proprio e variacoes) ---
	_add(c, &"weapon_pistol_fire", BUS_SFX, 55, 4, -6.0, SfxRecipes.pistol, 0.06, 50, 3)
	_add(c, &"weapon_shotgun_fire", BUS_SFX, 60, 3, -3.0, SfxRecipes.shotgun, 0.05, 100, 2)
	_add(c, &"weapon_smg_fire", BUS_SFX, 45, 4, -11.0, SfxRecipes.smg, 0.08, 60, 2)
	_add(c, &"weapon_machete_swing", BUS_SFX, 50, 3, -6.0, SfxRecipes.machete_swing, 0.1, 80, 2)
	_add(c, &"weapon_machete_hit", BUS_SFX, 50, 3, -7.0, SfxRecipes.machete_hit, 0.08, 70, 2)
	_add(c, &"weapon_molotov_throw", BUS_SFX, 50, 2, -6.0, SfxRecipes.molotov_throw, 0.08, 120, 2)
	_add(c, &"weapon_molotov_burst", BUS_SFX, 65, 3, -3.0, SfxRecipes.molotov_burst, 0.06, 120, 3, true)
	_add(c, &"weapon_fire_loop", BUS_AMBIENCE, 30, 1, -10.0, SfxRecipes.fire_loop, 0.0, 0, 1, true, true)
	_add(c, &"weapon_gas_start", BUS_SFX, 55, 1, -6.0, SfxRecipes.gas_start)
	_add(c, &"weapon_gas_loop", BUS_SFX, 30, 1, -16.0, SfxRecipes.gas_loop, 0.0, 0, 1, false, true)
	_add(c, &"weapon_evolve", BUS_ALERTS, 92, 1, -2.0, SfxRecipes.evolve, 0.0, 500, 1)
	# --- Impactos ---
	_add(c, &"hit_flesh", BUS_SFX, 35, 4, -12.0, SfxRecipes.impact, 0.12, 45, 4, true)
	_add(c, &"hit_crit", BUS_SFX, 70, 3, -6.0, SfxRecipes.crit, 0.06, 90, 2, true)
	_add(c, &"explosion", BUS_SFX, 85, 3, -1.0, SfxRecipes.explosion, 0.08, 80, 3, true)
	# --- Zumbis (cada tipo reconhecivel pelo som) ---
	_add(c, &"zombie_common_groan", BUS_ZOMBIES, 25, 6, -10.0, SfxRecipes.zombie_groan, 0.1, 150, 3, true)
	_add(c, &"zombie_runner_screech", BUS_ZOMBIES, 45, 3, -7.0, SfxRecipes.runner_screech, 0.08, 400, 2, true)
	_add(c, &"zombie_brute_growl", BUS_ZOMBIES, 45, 3, -5.0, SfxRecipes.brute_growl, 0.06, 600, 2, true)
	_add(c, &"zombie_bloater_gurgle", BUS_ZOMBIES, 50, 3, -6.0, SfxRecipes.bloater_gurgle, 0.06, 700, 2, true)
	_add(c, &"zombie_bloater_fuse", BUS_ALERTS, 90, 1, -2.0, SfxRecipes.bloater_fuse, 0.0, 120, 3, true,
			false, "Inchado vai explodir!")
	_add(c, &"zombie_hit", BUS_ZOMBIES, 30, 3, -14.0, SfxRecipes.zombie_hit, 0.12, 70, 2, true)
	_add(c, &"zombie_death", BUS_ZOMBIES, 35, 4, -11.0, SfxRecipes.zombie_death, 0.12, 60, 3, true)
	_add(c, &"zombie_horde_loop", BUS_ZOMBIES, 20, 1, -12.0, SfxRecipes.horde_loop, 0.0, 0, 1, false, true)
	_add(c, &"elite_appear", BUS_ALERTS, 80, 1, -3.0, SfxRecipes.elite_appear, 0.0, 1500, 1, true, false,
			"Zumbi de elite apareceu!")
	_add(c, &"elite_death", BUS_SFX, 75, 2, -3.0, SfxRecipes.elite_death, 0.05, 100, 2, true)
	# --- Chefes (identidades diferentes) ---
	_add(c, &"boss_colossus_roar", BUS_BOSSES, 95, 2, 0.0, SfxRecipes.boss_roar.bind(false), 0.04, 800, 1, true,
			false, "Rugido do Colosso")
	_add(c, &"boss_mutant_roar", BUS_BOSSES, 95, 2, 0.0, SfxRecipes.boss_roar.bind(true), 0.04, 800, 1, true,
			false, "Grito do Mutante")
	_add(c, &"boss_charge", BUS_ALERTS, 94, 2, -1.0, SfxRecipes.boss_charge, 0.05, 300, 1, true, false,
			"Investida do chefe!")
	_add(c, &"boss_death", BUS_BOSSES, 96, 1, 0.0, SfxRecipes.boss_death, 0.0, 500, 1, true)
	# --- Jogador ---
	_add(c, &"player_hurt", BUS_SFX, 97, 3, -3.0, SfxRecipes.player_hurt, 0.06, 150, 1)
	_add(c, &"player_heartbeat", BUS_ALERTS, 88, 1, -4.0, SfxRecipes.heartbeat, 0.0, 0, 1, false, true,
			"Vida baixa!")
	_add(c, &"player_heal", BUS_SFX, 70, 1, -5.0, SfxRecipes.heal)
	# --- Coleta e progressao ---
	_add(c, &"pickup_xp", BUS_SFX, 30, 2, -15.0, SfxRecipes.xp, 0.0, 35, 3)
	_add(c, &"pickup_gold", BUS_SFX, 40, 3, -10.0, SfxRecipes.coin, 0.04, 60, 2)
	_add(c, &"reward_chest", BUS_SFX, 80, 1, -3.0, SfxRecipes.chest)
	_add(c, &"level_up", BUS_ALERTS, 90, 1, -2.0, SfxRecipes.level_up, 0.0, 200, 1)
	_add(c, &"reward_unlock_character", BUS_UI, 85, 1, -2.0, SfxRecipes.fanfare.bind(2))
	_add(c, &"reward_unlock_map", BUS_UI, 85, 1, -2.0, SfxRecipes.fanfare.bind(1))
	_add(c, &"reward_achievement", BUS_UI, 80, 1, -3.0, SfxRecipes.fanfare.bind(0))
	_add(c, &"reward_new_record", BUS_UI, 85, 1, -2.0, SfxRecipes.fanfare.bind(3))
	# --- Cartas ---
	_add(c, &"ui_card_open", BUS_UI, 80, 1, -5.0, SfxRecipes.whoosh)
	_add(c, &"ui_card_pick_common", BUS_UI, 80, 1, -5.0, SfxRecipes.card_pick.bind(0))
	_add(c, &"ui_card_pick_rare", BUS_UI, 80, 1, -4.0, SfxRecipes.card_pick.bind(1))
	_add(c, &"ui_card_pick_epic", BUS_UI, 80, 1, -3.0, SfxRecipes.card_pick.bind(2))
	_add(c, &"ui_card_pick_legendary", BUS_UI, 85, 1, -2.0, SfxRecipes.card_pick.bind(3))
	# --- Interface ---
	_add(c, &"ui_click", BUS_UI, 60, 3, -9.0, SfxRecipes.ui_click, 0.04, 30, 2)
	_add(c, &"ui_select", BUS_UI, 60, 1, -7.0, SfxRecipes.ui_select, 0.02, 40, 2)
	_add(c, &"ui_back", BUS_UI, 60, 1, -7.0, SfxRecipes.ui_back, 0.02, 40, 2)
	_add(c, &"ui_transition", BUS_UI, 60, 2, -9.0, SfxRecipes.whoosh, 0.05, 150, 1)
	_add(c, &"ui_pause_on", BUS_UI, 70, 1, -6.0, SfxRecipes.pause_on)
	_add(c, &"ui_pause_off", BUS_UI, 70, 1, -6.0, SfxRecipes.pause_off)
	# --- Alertas de eventos ---
	_add(c, &"alert_horde", BUS_ALERTS, 88, 1, -3.0, SfxRecipes.alarm_horn, 0.0, 2000, 1, false, false,
			"Horda se aproximando!")
	_add(c, &"alert_supply", BUS_ALERTS, 80, 1, -4.0, SfxRecipes.supply_drop, 0.0, 2000, 1, false, false,
			"Suprimentos chegando!")
	_add(c, &"alert_toxic", BUS_ALERTS, 85, 1, -4.0, SfxRecipes.toxic, 0.0, 1000, 1, true, false,
			"Área contaminada!")
	# --- Ambiente do Rio (loops e sons ocasionais) ---
	_add(c, &"amb_city", BUS_AMBIENCE, 10, 1, -14.0, SfxRecipes.amb_city, 0.0, 0, 1, false, true)
	_add(c, &"amb_beach", BUS_AMBIENCE, 10, 1, -12.0, SfxRecipes.amb_beach, 0.0, 0, 1, false, true)
	_add(c, &"amb_hills", BUS_AMBIENCE, 10, 1, -13.0, SfxRecipes.amb_hills, 0.0, 0, 1, false, true)
	_add(c, &"amb_siren", BUS_AMBIENCE, 15, 2, -16.0, SfxRecipes.siren, 0.05, 6000, 1, true)
	_add(c, &"amb_gull", BUS_AMBIENCE, 15, 3, -15.0, SfxRecipes.gull, 0.08, 2000, 1, true)
	_add(c, &"amb_clank", BUS_AMBIENCE, 15, 3, -16.0, SfxRecipes.metal_clank, 0.08, 2000, 1, true)
	_add(c, &"amb_dog", BUS_AMBIENCE, 15, 2, -18.0, SfxRecipes.dog_bark, 0.06, 4000, 1, true)
	_add(c, &"amb_bell", BUS_AMBIENCE, 20, 1, -14.0, SfxRecipes.bell, 0.0, 8000, 1, true)
	_add(c, &"amb_creak", BUS_AMBIENCE, 15, 2, -16.0, SfxRecipes.creak, 0.05, 5000, 1, true)
	return c


static func _add(c: Dictionary, id: StringName, bus: StringName, priority: int, variations: int,
		volume_db: float, recipe: Callable, pitch_var: float = 0.05, cooldown_ms: int = 40,
		max_instances: int = 4, spatial: bool = false, loop: bool = false, caption: String = "") -> void:
	var d := Def.new()
	d.id = id
	d.bus = bus
	d.priority = priority
	d.variations = variations
	d.volume_db = volume_db
	d.recipe = recipe
	d.pitch_var = pitch_var
	d.cooldown_ms = cooldown_ms
	d.max_instances = max_instances
	d.spatial = spatial
	d.loop = loop
	d.caption = caption
	c[id] = d
