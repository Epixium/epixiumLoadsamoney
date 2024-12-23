extends CharacterBody2D

class_name Player

const SPEED := 450.0
const SPEED_THRESHOLD := 550.0
const JUMP_POWER := 550.0
const AIR_DASH_SPEED := 700.0
const SLIDE_KICK_SPEED := 800.0
const DRILL_SPEED := 1500.0

const GRAVITY := 1200.0
const WALL_SLIDE_GRAV := 800.0
const WALL_SLIDE_MAX := 100.0
const ACCEL := 1000.0
const AIR_ACCEL := 900.0
const FRICTION := 400.0
const AIR_RESIST := 400.0

const MAX_JUMPS := 2
var jumps := MAX_JUMPS
var can_air_dash := true

@export var BASE_OUTLINE := Color(1.0, 0.0, 0.0, 1.0)
var current_outline : Color
@export var BASE_FILL := Color(1.0, 1.0, 1.0, 1.0)
var current_fill : Color

@onready var CollisionCast = $CollisionHitbox
@onready var SafeCastA = $SafeCastA
@onready var SafeCastB = $SafeCastB
@onready var FaceCast = $FaceCast
@onready var EpixSprite = $EpixSprite
@onready var XStateText = $StateContainer/XState
@onready var YStateText = $StateContainer/YState
@onready var HeightState = 0
@onready var CollisionHitbox = [$Collision, $CollisionShort]
@onready var JumpHitbox = [$JumpHitbox/Collision, $JumpHitbox/CollisionShort]
@onready var DashHitbox = [$DashHitbox/Collision, $DashHitbox/CollisionShort]
@onready var DrillHitbox = [$DrillHitbox/Collision, $DrillHitbox/Collision]
@onready var AnimPlayer = $EpixSprite/EpixAnim
@onready var AnimTree = $EpixSprite/EpixTree
@onready var playback = AnimTree["parameters/playback"]
@onready var AirTimer = $Timers/AirTimer
@onready var sfx_run = $Run
@onready var sfx_jump = $Jump
@onready var sfx_wallkick = $WallKick
@onready var sfx_dash = $Dash
@onready var sfx = $TempoSFX
@onready var vfx_run_dust = $RunDust
@onready var stream = sfx.stream
@onready var soundstream = stream as AudioStreamSynchronized
var ghost_scene = preload("res://Player/Scenes/dash_ghost.tscn")

enum X_STATES {IDLE, CROUCHING, WALKING, CRAWLING, TURNING, AIRDASHING, SLIDEKICKING}
var x_state = X_STATES.IDLE
enum Y_STATES {FLOORED, FALLING, WALLSLIDING, JUMPING, WALLJUMPING, DRILLING}
var y_state = Y_STATES.FLOORED
enum SPECIAL_STATES {NONE, ZIPLINING}
var special_state = SPECIAL_STATES.NONE

var input_axis
var dir_faced := 1
var floor_normal
var wall_normal
var buffer_frames = 60
var speed_scale := 1.0
var just_on_wall := false
var still_on_wall := false

var velocity_locked := false
var gravity_applied := true
var acceleration_applied := true
var friction_applied := true
var x_state_locked := false
var y_state_locked := false
var special_state_locked := false
var anim_locked := false
var sprite_dir_locked := false
var can_turn := true
var above_threshold := false
var saved_velocity := Vector2(0, 0)

func _ready() -> void:
	change_colors(BASE_OUTLINE, BASE_FILL)
	AnimTree.active = true
	sfx.play()
	playback.travel("idle")

func _physics_process(delta):
	floor_normal = get_floor_normal()
	wall_normal = get_wall_normal()
	above_threshold = abs(velocity.x) >= SPEED_THRESHOLD
	
	if is_on_floor(): EpixSprite.rotation = get_floor_angle(Vector2(0, -1))
	else: EpixSprite.rotation = 0
	
	if is_on_wall():
		if just_on_wall: still_on_wall = true
		just_on_wall = true
	else:
		just_on_wall = false
		still_on_wall = false
	
	if get_x_state(X_STATES.CRAWLING) and get_special_state(SPECIAL_STATES.NONE):
		AnimPlayer.speed_scale = speed_scale * dir_faced * (-1 if EpixSprite.flip_h else 1)
	else:
		AnimPlayer.speed_scale = speed_scale
	
	if get_x_state(X_STATES.AIRDASHING) and is_on_wall():
		AirTimer.stop()
		velocity_locked = false
		x_state_locked = false
		y_state_locked = false
		can_turn = true
		velocity.x = AIR_DASH_SPEED * dir_faced
		set_x_state(X_STATES.IDLE)
	
	if get_y_state(Y_STATES.DRILLING) and is_on_floor():
		var add_drill = DRILL_SPEED * pow(floor_normal.x, 0.9)
		velocity.x += add_drill
		velocity.x = clamp(velocity.x, -1000, 1000)
	
	if velocity.x != 0:
		saved_velocity = velocity
	
	if can_turn:
		input_axis = Input.get_axis("move_left", "move_right")
		if input_axis != 0:
			dir_faced = input_axis
			FaceCast.scale.x = dir_faced
			vfx_run_dust.process_material.direction = Vector3(-dir_faced, 0, 0)

	if !x_state_locked: take_x_inputs()
	if !y_state_locked: take_y_inputs()
	
	if !anim_locked: handle_animations()
	handle_effects()
	handle_sounds(delta)
	
	if !velocity_locked:
		if get_y_state(Y_STATES.WALLSLIDING):
			if velocity.y < 0: apply_gravity(delta)
			else: wall_slide(delta)
		elif gravity_applied:
			apply_gravity(delta)
		if acceleration_applied:
			apply_acceleration(delta)
			apply_air_acceleration(delta)
		if friction_applied:
			apply_friction(delta)
			apply_air_resistance(delta)
	
	if abs(velocity.x) > SPEED_THRESHOLD:
		disable_collision(DashHitbox, false)
		if is_on_floor() and (get_x_state(X_STATES.WALKING) or get_x_state(X_STATES.CRAWLING)) and get_special_state(SPECIAL_STATES.NONE):
			if !sfx_run.playing: sfx_run.play()
			if !vfx_run_dust.emitting: vfx_run_dust.set_emitting(true)
		else:
			if sfx_run.playing: sfx_run.stop()
			if vfx_run_dust.emitting: vfx_run_dust.set_emitting(false)
	else:
		speed_scale = 1
		disable_collision(DashHitbox, true)
		if sfx_run.playing: sfx_run.stop()
		if vfx_run_dust.emitting: vfx_run_dust.set_emitting(false)
	
	if abs(velocity.x) > 900:
		$DashHitbox.scale.x = velocity.x/900
	else:
		$DashHitbox.scale.x = 1
	
	if get_x_state(X_STATES.SLIDEKICKING) and abs(velocity.x) < SPEED_THRESHOLD and get_special_state(SPECIAL_STATES.NONE):
		acceleration_applied = true
		can_turn = true
		anim_locked = false
		sprite_dir_locked = false
		x_state_locked = false
		if get_one_way(SafeCastA) and get_one_way(SafeCastB): change_height(0)
		disable_collision(CollisionHitbox, false)
	
	move_and_slide()

func take_x_inputs():
	if Input.is_action_just_pressed("dash") and !is_on_floor() and can_air_dash:
		set_x_state(X_STATES.AIRDASHING)
		set_y_state(Y_STATES.FALLING)
		air_dash()
		return
	elif Input.is_action_just_pressed("dash") and is_on_floor():
		set_x_state(X_STATES.SLIDEKICKING)
		slide_kick()
		return
	elif input_axis != 0:
		if (!is_on_floor() or !Input.is_action_pressed("move_down")) and (get_one_way(SafeCastA) and get_one_way(SafeCastB)):
			if abs(velocity.x) > SPEED_THRESHOLD:
				AnimTree.set("parameters/run/blend_position", 1)
			else:
				AnimTree.set("parameters/run/blend_position", 0)
			sprite_dir_locked = false
			change_height(0)
			set_x_state(X_STATES.WALKING)
		else:
			if abs(velocity.x) > SPEED_THRESHOLD:
				AnimTree.set("parameters/run/blend_position", -2)
			else:
				AnimTree.set("parameters/run/blend_position", -1)
			sprite_dir_locked = true
			change_height(1)
			set_x_state(X_STATES.CRAWLING)
		return
	else:
		if !Input.is_action_pressed("move_down") and (get_one_way(SafeCastA) and get_one_way(SafeCastB)):
			sprite_dir_locked = false
			AnimTree.set("parameters/idle/blend_position", 0)
			change_height(0)
			set_x_state(X_STATES.IDLE)
		else:
			sprite_dir_locked = true
			AnimTree.set("parameters/idle/blend_position", -1)
			change_height(1)
			set_x_state(X_STATES.CROUCHING)
		return

func take_y_inputs():
	if (Input.is_action_pressed("move_down") or get_y_state(Y_STATES.DRILLING)) and !is_on_floor() and get_one_way(SafeCastA) and get_one_way(SafeCastB):
		set_y_state(Y_STATES.DRILLING)
		drill()
		return
	elif Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("move_up"):
		if is_on_wall():
			set_y_state(Y_STATES.WALLJUMPING)
			wall_jump()
			return
		if jumps > 0:
			set_y_state(Y_STATES.JUMPING)
			jump()
			return
	elif Input.is_action_just_released("jump") or Input.is_action_just_released("move_up"):
		cut_jump()
	elif is_on_wall() and (abs(saved_velocity.x) > SPEED_THRESHOLD) and !still_on_wall and !get_y_state(Y_STATES.DRILLING):
		set_y_state(Y_STATES.WALLJUMPING)
		wall_kick()
		return
	elif is_on_wall() and !is_on_floor() and input_axis * wall_normal.x < 0:
		set_y_state(Y_STATES.WALLSLIDING)
		anim_locked = false
		sprite_dir_locked = false
		disable_collision(JumpHitbox, true)
		return
	elif velocity.y > 0:
		set_y_state(Y_STATES.FALLING)
		disable_collision(JumpHitbox, true)
		return
	elif is_on_floor() or get_special_state(SPECIAL_STATES.ZIPLINING):
		jumps = MAX_JUMPS
		can_air_dash = true
		AnimTree.set("parameters/jump_start/blend_position", 0)
		AnimTree.set("parameters/jump/blend_position", 0)
		anim_locked = false
		disable_collision(JumpHitbox, true)
		disable_collision(DrillHitbox, true)
		set_y_state(Y_STATES.FLOORED)
		return

func jump():
	play_sound_in_range(sfx_jump, 0.8, 1.2)
	jumps -= 1
	disable_collision(JumpHitbox, false)
	velocity.y = -JUMP_POWER

func cut_jump():
	velocity.y = max(velocity.y, -200)

func wall_jump():
	AnimTree.set("parameters/jump_start/blend_position", 0)
	AnimTree.set("parameters/jump/blend_position", 0)
	anim_locked = false
	sprite_dir_locked = false
	disable_collision(JumpHitbox, false)
	play_sound_in_range(sfx_jump, 0.8, 1.2)
	velocity.x += JUMP_POWER * wall_normal.x * 0.9
	velocity.y = -JUMP_POWER

func wall_kick():
	play_sound_in_range(sfx_wallkick, 0.8, 1.2)
	velocity.x = -saved_velocity.x * 0.975
	velocity.y = -JUMP_POWER
	dir_faced *= -1
	if !(get_one_way(SafeCastA) and get_one_way(SafeCastB)): return
	change_height(0)
	disable_collision(CollisionHitbox, false)
	disable_collision(JumpHitbox, false)
	AnimTree.set("parameters/jump_start/blend_position", 1)
	AnimTree.set("parameters/jump/blend_position", 1)
	move_to_anim("jump")
	acceleration_applied = true
	can_turn = true
	x_state_locked = false
	y_state_locked = false
	anim_locked = true
	sprite_dir_locked = true

func wall_slide(delta):
	velocity.y += WALL_SLIDE_GRAV * delta
	velocity.y = min(WALL_SLIDE_MAX, velocity.y)

func air_dash():
	change_height(0)
	disable_collision(DashHitbox, false)
	disable_collision(DrillHitbox, true)
	sfx_dash.play()
	velocity_locked = true
	anim_locked = false
	sprite_dir_locked = false
	can_turn = false
	x_state_locked = true
	y_state_locked = true
	can_air_dash = false
	velocity.x = max(AIR_DASH_SPEED, abs(velocity.x)) * dir_faced
	velocity.y = 0
	AirTimer.start()

func _on_air_timer_timeout() -> void:
	velocity_locked = false
	x_state_locked = false
	y_state_locked = false
	can_turn = true
	set_x_state(X_STATES.IDLE)

func slide_kick():
	change_height(1)
	disable_collision(DashHitbox, false)
	disable_collision(CollisionHitbox, false)
	sfx_dash.play()
	acceleration_applied = false
	can_turn = false
	anim_locked = false
	sprite_dir_locked = false
	x_state_locked = true
	velocity.x = max(SLIDE_KICK_SPEED, abs(velocity.x)) * dir_faced
	saved_velocity = velocity
	if is_on_wall() and FaceCast.is_colliding():
		wall_kick()

func drill():
	change_height(0)
	disable_collision(CollisionHitbox, false)
	disable_collision(DrillHitbox, false)
	acceleration_applied = true
	can_turn = true
	anim_locked = false
	sprite_dir_locked = true
	x_state_locked = false
	velocity.y = DRILL_SPEED

func zipline():
	set_x_state(X_STATES.IDLE)
	set_y_state(Y_STATES.FLOORED)
	set_special_state(SPECIAL_STATES.ZIPLINING)
	velocity = Vector2(0, 0)
	velocity_locked = true
	gravity_applied = false
	acceleration_applied = false
	friction_applied = false
	x_state_locked = true
	y_state_locked = false
	special_state_locked = false
	anim_locked = false
	sprite_dir_locked = false
	can_turn = false

func stop_ziplining():
	set_special_state(SPECIAL_STATES.NONE)
	velocity_locked = false
	gravity_applied = true
	acceleration_applied = true
	friction_applied = true
	x_state_locked = false
	can_turn = true

# boring stuff that gets run every frame boooo BOOOOO

func apply_gravity(delta):
	if !is_on_floor():
		velocity.y += GRAVITY * delta

func apply_acceleration(delta):
	if is_on_floor():
		if abs(velocity.x) <= SPEED_THRESHOLD:
			velocity.x = move_toward(velocity.x, max(SPEED, abs(velocity.x)) * input_axis, ACCEL * delta)
		elif velocity.x * input_axis < 0:
			velocity.x = move_toward(velocity.x, max(SPEED, abs(velocity.x)) * input_axis, ACCEL * 0.5 * delta)
		else:
			velocity.x = move_toward(velocity.x, max(SPEED, abs(velocity.x)) * input_axis, ACCEL * 0.2 * delta)

func apply_air_acceleration(delta):
	if !is_on_floor():
		if abs(velocity.x) <= SPEED_THRESHOLD:
			velocity.x = move_toward(velocity.x, max(SPEED, abs(velocity.x)) * input_axis, AIR_ACCEL * delta)
		else:
			velocity.x = move_toward(velocity.x, max(SPEED, abs(velocity.x)) * input_axis, AIR_ACCEL * 0.2 * delta)

func apply_friction(delta):
	if is_on_floor() and abs(velocity.x) <= SPEED_THRESHOLD:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

func apply_air_resistance(delta):
	if !is_on_floor() and abs(velocity.x) <= SPEED:
		velocity.x = move_toward(velocity.x, 0, AIR_RESIST * delta)

func set_x_state(state):
	x_state = state
	XStateText.text = "[center]" + X_STATES.keys()[state]

func set_y_state(state):
	y_state = state
	YStateText.text = "[center]" + Y_STATES.keys()[state]

func set_special_state(state):
	special_state = state

func get_x_state(state):
	var is_state := false
	if x_state == state: is_state = true
	return is_state

func get_y_state(state):
	var is_state := false
	if y_state == state: is_state = true
	return is_state

func get_special_state(state):
	var is_state := false
	if special_state == state: is_state = true
	return is_state

func handle_animations():
	if !sprite_dir_locked: match dir_faced:
		-1: EpixSprite.flip_h = true
		1: EpixSprite.flip_h = false
	if get_special_state(SPECIAL_STATES.ZIPLINING):
		move_to_anim("slidekick")
	elif get_x_state(X_STATES.AIRDASHING):
		move_to_anim("airdash")
		add_ghost(Color(0.0, 1.0, 1.0, 1.0), Color(0.0, 0.0, 1.0, 0.0))
	elif get_x_state(X_STATES.SLIDEKICKING):
		move_to_anim("slidekick")
		add_ghost(Color(0.0, 1.0, 1.0, 1.0), Color(0.0, 0.0, 1.0, 0.0))
	elif get_y_state(Y_STATES.DRILLING):
		move_to_anim("drill")
	elif get_x_state(X_STATES.CRAWLING):
		move_to_anim("run")
	elif get_x_state(X_STATES.CROUCHING):
		move_to_anim("idle")
	elif get_y_state(Y_STATES.JUMPING) or get_y_state(Y_STATES.WALLJUMPING):
		move_to_anim("jump")
	elif get_y_state(Y_STATES.WALLSLIDING):
		move_to_anim("wallslide")
	elif get_y_state(Y_STATES.FALLING):
		move_to_anim("fall")
	elif get_x_state(X_STATES.WALKING):
		move_to_anim("run")
	elif get_x_state(X_STATES.IDLE):
		move_to_anim("idle")

func change_height(state):
	var old_state = HeightState
	HeightState = state
	disable_collision(CollisionHitbox, CollisionHitbox[old_state].disabled)
	disable_collision(JumpHitbox, JumpHitbox[old_state].disabled)
	disable_collision(DashHitbox, DashHitbox[old_state].disabled)
	disable_collision(DrillHitbox, DrillHitbox[old_state].disabled)

func disable_collision(collision, disable):
	collision[HeightState].disabled = disable
	for collider in collision:
		if collider == collision[HeightState]: continue
		collider.disabled = true

func handle_effects():
	if abs(velocity.x) >= SPEED_THRESHOLD and !get_x_state(X_STATES.AIRDASHING) and !get_x_state(X_STATES.SLIDEKICKING):
		add_ghost(Color(1.0, 1.0, 1.0, 0.5), Color(0.8, 0.8, 0.8, 0.0))

func handle_sounds(delta):
	change_sound_volume(abs(velocity.x) >= SPEED_THRESHOLD, 0, delta)
	change_sound_volume(velocity.y > GRAVITY, 1, delta)

func play_sound_in_range(sound, minimum, maximum):
	sound.pitch_scale = randf_range(minimum, maximum)
	sound.play()

func change_sound_volume(unmute, channel, delta):
	if unmute:
		stream.set_sync_stream_volume(channel, move_toward(stream.get_sync_stream_volume(channel), -20, 240*delta))
	else:
		stream.set_sync_stream_volume(channel, move_toward(stream.get_sync_stream_volume(channel), -60, 60*delta))

func move_to_anim(anim):
	if AnimPlayer.current_animation == anim: return
	playback.travel(anim)

func change_colors(outline_color : Color, fill_color : Color):
	EpixSprite.material.set("shader_parameter/outline_color", outline_color)
	current_outline = outline_color
	EpixSprite.material.set("shader_parameter/fill_color", fill_color)
	current_fill = fill_color

func add_ghost(start_color : Color, end_color : Color):
	var ghost : Sprite2D = ghost_scene.instantiate()
	ghost.global_position = global_position
	ghost.texture = EpixSprite.texture
	ghost.hframes = EpixSprite.hframes
	ghost.frame = EpixSprite.frame
	ghost.flip_h = EpixSprite.flip_h
	ghost.start_color = start_color
	ghost.end_color = end_color
	ghost.material.set("shader_parameter/outline_color", BASE_OUTLINE)
	ghost.material.set("shader_parameter/fill_color", BASE_FILL)
	ghost.z_index = 1
	get_parent().add_child(ghost)

func get_one_way(cast):
	if !cast.is_colliding(): return true
	var collider = cast.get_collider()
	var cell = collider.local_to_map(cast.get_collision_point())
	cell.y -= 1
	var data = collider.get_cell_tile_data(cell)
	if data != null: return data.is_collision_polygon_one_way(0, 0)
	else: return true

func snap_down():
	var wagoogus = Vector2(0, 0)
	if SafeCastA.is_colliding() and SafeCastB.is_colliding():
		if get_one_way(SafeCastA) and get_one_way(SafeCastB): return true
		wagoogus = (SafeCastA.get_collision_point()-self.global_position)
		self.global_position.y -= wagoogus.y
	SafeCastA.force_raycast_update()
	SafeCastB.force_raycast_update()
	if (!get_one_way(SafeCastA) or !get_one_way(SafeCastB)) and wagoogus != Vector2(0, 0): self.global_position.y += wagoogus.y; return false
	else: return true
