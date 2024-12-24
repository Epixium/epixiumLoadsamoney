extends CharacterBody2D

class_name Enemy

const SPEED = 100.0
var direction = 1

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += GameState.gravity * delta
	if is_on_wall(): direction *= -1
	velocity.x = SPEED * direction
	move_and_slide()

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if body is Player: hurt(body)

func hurt(body):
	body.velocity = Vector2(400 * -direction, -400)
	GameState.change_health(-1)
	queue_free()
