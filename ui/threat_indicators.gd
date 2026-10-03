class_name ThreatIndicators
extends Control
## Setas na borda da tela apontando ameacas que estao FORA da tela:
## chefes (vermelho), elites (dourado) e Inchados prestes a explodir (laranja).
## Acessibilidade: o jogador nao depende so do som para saber de onde vem o perigo.

const MARGIN := 46.0
const REFRESH := 0.1

var _arrows: Array[Array] = []  # [posicao na tela, angulo, cor]
var _timer: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = REFRESH
	_arrows.clear()
	if Save.profile.settings.threat_indicators:
		_collect()
	queue_redraw()


func _collect() -> void:
	var tree := get_tree()
	var rig := CameraRig.find(tree)
	var m := EnemyManager.find(tree)
	if rig == null or m == null or rig.camera == null:
		return
	var rect := get_viewport_rect()
	var center := rect.size * 0.5
	var inner := rect.grow(-MARGIN)
	var count := 0
	for a: EnemyAgent in m.agents:
		var color := Color.TRANSPARENT
		if a.data.is_boss:
			color = Color(1, 0.25, 0.2)
		elif a.elite:
			color = Color(1, 0.82, 0.3)
		elif a.state == EnemyManager.State.FUSE:
			color = Color(1, 0.5, 0.1)
		else:
			continue
		var screen := rig.camera.unproject_position(GroundPlane.to_3d(a.pos, 1.0))
		if inner.has_point(screen):
			continue  # visivel: nao precisa de seta
		var dir := (screen - center).normalized()
		var edge := _clamp_to_rect(center, dir, inner)
		_arrows.append([edge, dir.angle(), color])
		count += 1
		if count >= 8:
			break
	# Baus (suprimentos) fora da tela: seta verde.
	var pickups := PickupManager.find(tree)
	if pickups:
		for pos: Vector2 in pickups.chest_positions():
			var s := rig.camera.unproject_position(GroundPlane.to_3d(pos, 0.5))
			if inner.has_point(s):
				continue
			var d := (s - center).normalized()
			_arrows.append([_clamp_to_rect(center, d, inner), d.angle(), Color(0.45, 1.0, 0.4)])


func _clamp_to_rect(center: Vector2, dir: Vector2, r: Rect2) -> Vector2:
	var tx := INF if is_zero_approx(dir.x) else ((r.end.x if dir.x > 0 else r.position.x) - center.x) / dir.x
	var ty := INF if is_zero_approx(dir.y) else ((r.end.y if dir.y > 0 else r.position.y) - center.y) / dir.y
	return center + dir * minf(tx, ty)


func _draw() -> void:
	for a: Array in _arrows:
		var p: Vector2 = a[0]
		var ang: float = a[1]
		var c: Color = a[2]
		var pts := PackedVector2Array([Vector2(26, 0), Vector2(-14, -18), Vector2(-6, 0), Vector2(-14, 18)])
		var xf := Transform2D(ang, p)
		var poly := xf * pts
		draw_colored_polygon(poly, Color(0, 0, 0, 0.6))
		draw_colored_polygon(Transform2D(ang, p) * PackedVector2Array([Vector2(20, 0),
				Vector2(-10, -13), Vector2(-4, 0), Vector2(-10, 13)]), c)
