extends Sprite2D

var lifetime: float = 0.15
var timer: float = 0.0

func setup(tex: Texture2D, col: Color, life: float) -> void :
	texture = tex
	modulate = col
	modulate.a *= 0.3
	lifetime = life
	timer = lifetime

func _process(delta: float) -> void :
	timer -= delta
	modulate.a = lerp(0.0, 0.3, timer / lifetime)
	if timer <= 0:
		queue_free()
