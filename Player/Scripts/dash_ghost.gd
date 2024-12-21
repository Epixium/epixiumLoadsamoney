extends Sprite2D

var start_color := Color(0.0, 0.0, 0.0, 1.0)
var end_color := Color(0.0, 0.0, 0.0, 0.0)

func _ready():
	self.modulate = start_color
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUART) 
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", end_color, 0.5)
	await tween.finished
	queue_free()
