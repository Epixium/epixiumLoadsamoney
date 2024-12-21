extends Area2D

class_name Collectible

@export var collect_value : int = 1
var broken = false
@onready var sprite = $Sprite

func _ready():
	sprite.get_node("Animation").play("spin")
	sprite.region_rect = Rect2(0, randi_range(0, 4)*20, 100, 20)
	$Collect.pitch_scale *= randf_range(0.8, 1.2)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and !broken:
		var cam = body.get_node("Camera")
		#$Collect.play()
		sprite.reparent(cam)
		cam.play_collect_animation(sprite, collect_value)
		broken = true
		add_to_total(collect_value)
		#await $Collect.finished
		queue_free()

func add_to_total(value):
	GameState.give_collectibles(value)
