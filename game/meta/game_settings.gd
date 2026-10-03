class_name GameSettings
extends RefCounted
## Preferencias do jogador (salvas junto com o perfil).

enum Quality { LOW, MEDIUM, HIGH }

var master_volume: float = 0.8
var music_volume: float = 0.6
var sfx_volume: float = 0.8
var music_on: bool = true
var sfx_on: bool = true
var language: String = "pt_BR"
var quality: int = Quality.MEDIUM
var vibration: bool = true
var notifications: bool = true
## Debug: partidas normais curtas (Config.game.debug_match_duration).
var debug_short_match: bool = false


func to_dict() -> Dictionary:
	return {
		"master_volume": master_volume, "music_volume": music_volume, "sfx_volume": sfx_volume,
		"music_on": music_on, "sfx_on": sfx_on, "language": language, "quality": quality,
		"vibration": vibration, "notifications": notifications, "debug_short_match": debug_short_match,
	}


static func from_dict(d: Dictionary) -> GameSettings:
	var s := GameSettings.new()
	s.master_volume = clampf(float(d.get("master_volume", s.master_volume)), 0.0, 1.0)
	s.music_volume = clampf(float(d.get("music_volume", s.music_volume)), 0.0, 1.0)
	s.sfx_volume = clampf(float(d.get("sfx_volume", s.sfx_volume)), 0.0, 1.0)
	s.music_on = bool(d.get("music_on", s.music_on))
	s.sfx_on = bool(d.get("sfx_on", s.sfx_on))
	s.language = str(d.get("language", s.language))
	s.quality = clampi(int(d.get("quality", s.quality)), 0, 2)
	s.vibration = bool(d.get("vibration", s.vibration))
	s.notifications = bool(d.get("notifications", s.notifications))
	s.debug_short_match = bool(d.get("debug_short_match", false))
	return s
