class_name GameSettings
extends RefCounted
## Preferencias do jogador (salvas junto com o perfil). Valores de volume: 0..1.

enum Quality { LOW, MEDIUM, HIGH }

# --- Audio (um volume por categoria) ---
var master_volume: float = 0.85
var music_volume: float = 0.55
var sfx_volume: float = 0.8
var ambience_volume: float = 0.6
var zombies_volume: float = 0.75
var ui_volume: float = 0.7
var bosses_volume: float = 0.9
var alerts_volume: float = 0.9
var music_on: bool = true
var sfx_on: bool = true
var mute_all: bool = false

# --- Acessibilidade ---
## Legendas para alertas importantes ("Inchado vai explodir!").
var captions: bool = true
var mono_audio: bool = false
var reduce_intense: bool = false
var boost_alerts: bool = false
var reduce_music_in_combat: bool = false
## Setas na borda da tela apontando ameacas fora da tela.
var threat_indicators: bool = true

# --- Jogo e graficos ---
var language: String = "pt_BR"
var quality: int = Quality.MEDIUM
var vibration: bool = true
var notifications: bool = true
## 30 ou 60 (economiza bateria em 30).
var fps_limit: int = 60
## Particulas reduzidas (celular fraco).
var reduced_particles: bool = false
## Multiplica o limite de zumbis vivos (0.6 = celular fraco, 1.0 = normal).
var enemy_density: float = 1.0
## Zoom da camera (1 = padrao; maior = ve mais cidade).
var camera_zoom: float = 1.0
## Debug: partidas normais curtas (Config.game.debug_match_duration).
var debug_short_match: bool = false
## Debug liberado pelo codigo secreto (7 toques na versao do menu).
var debug_unlocked: bool = false

const FLOATS: PackedStringArray = ["master_volume", "music_volume", "sfx_volume", "ambience_volume",
	"zombies_volume", "ui_volume", "bosses_volume", "alerts_volume"]
const BOOLS: PackedStringArray = ["music_on", "sfx_on", "mute_all", "captions", "mono_audio",
	"reduce_intense", "boost_alerts", "reduce_music_in_combat", "threat_indicators", "vibration",
	"notifications", "reduced_particles", "debug_short_match", "debug_unlocked"]


func to_dict() -> Dictionary:
	var d := {"language": language, "quality": quality, "fps_limit": fps_limit,
		"enemy_density": enemy_density, "camera_zoom": camera_zoom}
	for k: String in FLOATS:
		d[k] = get(k)
	for k: String in BOOLS:
		d[k] = get(k)
	return d


static func from_dict(d: Dictionary) -> GameSettings:
	var s := GameSettings.new()
	for k: String in FLOATS:
		s.set(k, clampf(float(d.get(k, s.get(k))), 0.0, 1.0))
	for k: String in BOOLS:
		s.set(k, bool(d.get(k, s.get(k))))
	s.language = str(d.get("language", s.language))
	s.quality = clampi(int(d.get("quality", s.quality)), 0, 2)
	s.fps_limit = 30 if int(d.get("fps_limit", 60)) == 30 else 60
	s.enemy_density = clampf(float(d.get("enemy_density", 1.0)), 0.5, 1.0)
	s.camera_zoom = clampf(float(d.get("camera_zoom", 1.0)), 0.8, 1.3)
	return s
