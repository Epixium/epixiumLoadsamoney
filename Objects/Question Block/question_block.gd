extends StaticBody2D

var tilePos = Vector2i(0,0)
var broken = false

@export var object_inside : PackedScene

func _ready():
	$Breakable/Break.pitch_scale = randf_range(0.8, 1.2)
	$Sprite/Animation.play("flash")

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerHitbox") and !broken:
		$Breakable/Break.play()
		$Breakable/Part.restart()
		$Sprite.hide()
		$Collision.set_deferred("disabled", true)
		broken = true
		var tween
		if object_inside:
			var object = object_inside.instantiate()
			object.global_position = global_position
			get_tree().root.call_deferred("add_child", object)
			tween = create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_BACK)
			tween.tween_property(object, "global_position:y", self.global_position.y - 32, 0.3)
			tween.play()
		await get_tree().create_timer($Breakable/Part.lifetime,false).timeout
		if object_inside: await tween.finished
		queue_free()
