class_name DeathBurst
extends CPUParticles2D
## Explosao de particulas quando um inimigo morre (vem do Pool).
## CPUParticles2D funciona na web e em celular fraco.


func burst(pos: Vector2, tint: Color) -> void:
	global_position = pos
	color = tint
	restart()
	get_tree().create_timer(lifetime + 0.05, false).timeout.connect(Pool.release.bind(self))
