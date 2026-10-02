class_name UiFormat
extends RefCounted
## Pequenas funcoes de formatacao de texto da UI.


## 75.4 -> "01:15"
static func time(seconds: float) -> String:
	var s := floori(seconds)
	return "%02d:%02d" % [floori(s / 60.0), s % 60]
