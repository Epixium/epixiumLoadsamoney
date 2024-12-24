extends Path2D

class_name Zipline

var speed := 0.5

@export_group("Stats")
@export var gravity : float = 600.0
@export var friction : float = 20.0
@export_group("Setup")
@export var point_total: int = 40
@export var looping : bool = false
@export_group("Nodes")
@export var Area : Area2D
@export var TextureLine : Line2D
@export var TextureStart : Sprite2D
@export var TextureEnd : Sprite2D

var followers = {}
var snap_points = []
var hasSpawnedPoints = true

func _ready() -> void:
	set_physics_process(false)
	populate_rail()
	update_line()
	if !looping: 
		TextureStart.position = curve.get_baked_points()[0]
		TextureStart.rotation = randi_range(0, 3) * PI/2
		TextureStart.show()
		TextureEnd.position = curve.get_baked_points()[-1]
		TextureEnd.rotation = randi_range(0, 3) * PI/2
		TextureEnd.show()

func _physics_process(delta):
	for player in followers.keys():
		if !player.get_special_state(player.SPECIAL_STATES.ZIPLINING): continue
		var follower = followers[player]
		var base_angle = follower.rotation
		follower.rotation = get_opposite(follower.rotation)
		var vec_angle = Vector2.from_angle(follower.rotation) * gravity
		speed = move_toward(speed, 0, friction * delta)
		speed += abs(vec_angle.y) * delta * sign(base_angle)
		follower.progress += speed * delta
		player.global_position = follower.global_position
		player.PivotPoint.rotation = get_opposite(follower.rotation)
		
		if (!looping and (follower.progress_ratio == 0 or follower.progress_ratio == 1)) or player.get_y_state(player.Y_STATES.JUMPING) or player.get_y_state(player.Y_STATES.WALLJUMPING) or player.get_y_state(player.Y_STATES.DRILLING) or player.is_on_wall():
			var fungus = Vector2.from_angle(follower.rotation) * speed
			player.velocity.x = fungus.x
			if !looping and (follower.progress_ratio == 0 or follower.progress_ratio == 1):
				player.velocity.y = fungus.y
			else:
				player.velocity.y = min(player.velocity.y, fungus.y)
			end_zipline(player)
			player.stop_ziplining()

func get_opposite(x):
	if abs(x) <= PI/2: return x
	else: return -sign(x)*(PI-abs(x))

func populate_rail():
	var path_length = curve.get_baked_length()
	for i in range(point_total):
		var new_follow = PathFollow2D.new()
		add_child(new_follow)
		snap_points.append(new_follow)
		new_follow.progress_ratio = float(i)/(point_total-1)
		if i == point_total:
			hasSpawnedPoints = true

func start_zipline(player):
	set_physics_process(true)

func end_zipline(player):
	await get_tree().create_timer(0.1).timeout
	followers.erase(player)
	if len(followers) == 0: set_physics_process(false)

func update_line():
	var points = curve.get_baked_points()
	TextureLine.points = points
	for i in range(len(points)-1):
		var new_shape = CollisionShape2D.new()
		Area.add_child(new_shape)
		var segment = SegmentShape2D.new()
		segment.set_local_to_scene(true)
		segment.a = points[i]
		segment.b = points[i + 1]
		new_shape.shape = segment

func find_nearest_rail_follower(player_position):
	var nearest_node = null
	var min_distance = INF
	for node in snap_points:
		var distance = player_position.distance_to(node.global_transform.origin)
		if distance < min_distance:
			min_distance = distance
			nearest_node = node
	return nearest_node

func setup_follower(player, progress):
	var follower = PathFollow2D.new()
	follower.loop = looping
	add_child(follower)
	followers.get_or_add(player, follower)
	follower.progress = progress

func _on_area_body_entered(body: Node2D) -> void:
	if body is not Player: return
	var player : Player = body
	if player in followers.keys(): return
	if player.get_special_state(player.SPECIAL_STATES.ZIPLINING): return
	
	var snap_to = find_nearest_rail_follower(player.global_position)
	setup_follower(player, snap_to.progress)
	
	var mult = 1
	if abs(followers[player].rotation) > PI/2: mult = -1
	var thing = (player.velocity * Vector2.from_angle(get_opposite(followers[player].rotation))) * mult
	speed = thing.x + thing.y
	player.zipline()
	#print("FART!")
	set_physics_process(true)
