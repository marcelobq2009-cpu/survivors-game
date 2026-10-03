class_name GroundPlane
extends RefCounted
## Conversao entre o "plano do chao" da simulacao (Vector2) e o mundo 3D.
## A logica do jogo (zumbis, projeteis, gemas) roda em 2D no chao, que e
## barato e simples; so a apresentacao e 3D.
##   Vector2(x, y)  <->  Vector3(x, altura, y)      (1 unidade = 1 metro)


static func to_3d(p: Vector2, height: float = 0.0) -> Vector3:
	return Vector3(p.x, height, p.y)


static func to_2d(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)


## Angulo (em torno de Y) para um modelo que olha para +Z encarar `dir`.
static func heading(dir: Vector2) -> float:
	return atan2(dir.x, dir.y)
