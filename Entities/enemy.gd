extends CharacterBody2D

class_name Enemy

@export var ITimer : Timer
const MAX_BUFFER = 4
var buffer = MAX_BUFFER
const SPEED = 100.0
var direction = 1
var can_damage = true

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += GameState.gravity * delta
	if not can_damage:
		buffer -= 1
		if buffer == 0:
			buffer = MAX_BUFFER
			$PivotPoint/Sprite.visible = !$PivotPoint/Sprite.visible
	if is_on_wall(): direction *= -1
	velocity.x = SPEED * direction
	move_and_slide()

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if body is Player: hurt(body)

func hurt(body):
	body.velocity = Vector2(500 * direction, -400)
	GameState.change_health(-1)

func _on_damage_area_body_entered(body: Node2D) -> void:
	if body is Player and !body.get_y_state(body.Y_STATES.FLOORED) and can_damage: on_damaged(body)

func on_damaged(body):
	body.velocity = Vector2(0, -600)
	queue_free()

func start_i_timer():
	ITimer.play()

func _on_i_timer_timeout() -> void:
	can_damage = true
