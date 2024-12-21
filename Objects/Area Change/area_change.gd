@tool

extends Area2D

class_name AreaChange

@export var size = Vector2():
	set(new_size):
		size = new_size
		$Collision.shape.size = size

@export var silent := false

var changing := false

@export var send_to : Marker2D

func _on_body_entered(body: Node2D) -> void:
	if body is Player and !changing:
		changing = true
		if !silent: $Sound.play()
		var cam = body.get_node("Camera")
		if !silent: await cam.fade_out()
		if send_to != null: body.global_position = send_to.global_position; cam.global_position = send_to.global_position
		else: body.global_position = Vector2(0, 0); cam.global_position = Vector2(0, 0)
		if !silent: await get_tree().create_timer(0.2).timeout
		if !silent: await body.get_node("Camera").fade_in()
		changing = false
