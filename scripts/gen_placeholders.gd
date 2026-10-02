extends SceneTree
## Gera as formas placeholder (PNGs brancos 64x64) em assets/sprites/placeholder/.
## A cor vem do .tres (modulate), por isso as formas sao brancas.
## Rodar: .\scripts\godot.ps1 --headless -s res://scripts/gen_placeholders.gd

const SIZE := 64
const SS := 4  # Supersampling para bordas suaves.
const OUT := "res://assets/sprites/placeholder/"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_save("circle", func(p: Vector2) -> float: return 1.0 if p.length() <= 1.0 else 0.0)
	_save("square", func(p: Vector2) -> float: return 1.0 if absf(p.x) <= 0.9 and absf(p.y) <= 0.9 else 0.0)
	_save("triangle", _triangle)
	_save("diamond", func(p: Vector2) -> float: return 1.0 if absf(p.x) + absf(p.y) <= 1.0 else 0.0)
	_save("ring", func(p: Vector2) -> float: return 1.0 if p.length() <= 1.0 and p.length() >= 0.82 else 0.0)
	_save("soft_circle", func(p: Vector2) -> float: return clampf(1.0 - p.length(), 0.0, 1.0))
	print("Placeholders gerados em ", OUT)
	quit()


## Triangulo apontando para a DIREITA (rotacao 0 no Godot = direita).
func _triangle(p: Vector2) -> float:
	var a := Vector2(1.0, 0.0)
	var b := Vector2(-0.8, -0.85)
	var c := Vector2(-0.8, 0.85)
	var d1 := _edge(p, a, b)
	var d2 := _edge(p, b, c)
	var d3 := _edge(p, c, a)
	var has_neg := d1 < 0 or d2 < 0 or d3 < 0
	var has_pos := d1 > 0 or d2 > 0 or d3 > 0
	return 0.0 if has_neg and has_pos else 1.0


func _edge(p: Vector2, a: Vector2, b: Vector2) -> float:
	return (p.x - b.x) * (a.y - b.y) - (a.x - b.x) * (p.y - b.y)


## `shape` recebe um ponto em [-1, 1] e devolve a cobertura (0..1).
func _save(file_name: String, shape: Callable) -> void:
	var img := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		for x: int in SIZE:
			var sum := 0.0
			for sy: int in SS:
				for sx: int in SS:
					var px := (x + (sx + 0.5) / SS) / SIZE * 2.0 - 1.0
					var py := (y + (sy + 0.5) / SS) / SIZE * 2.0 - 1.0
					sum += float(shape.call(Vector2(px, py)))
			img.set_pixel(x, y, Color(1, 1, 1, sum / (SS * SS)))
	img.save_png(OUT + file_name + ".png")
