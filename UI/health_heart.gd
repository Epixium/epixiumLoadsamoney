@tool
extends TextureRect

var heartActive := true
var tween

@export_enum("Broken", "Normal", "Crystal") var type: int = 0:
	set(new_type):
		if type == new_type: return
		type = new_type
		set_type(type)

func set_type(type_to : int):
	texture.region = Rect2(64*type_to, 0, 64, 64)
	size = Vector2(1.5, 1.5)
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(self, "size", Vector2(1, 1), 0.2)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.play()
