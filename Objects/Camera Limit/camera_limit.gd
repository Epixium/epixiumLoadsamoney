@tool

extends Node2D

class_name CameraLimit
@onready var lock = $Lock
@onready var ls = $Lock/Shape
@onready var lockrange = $Range
@onready var rs = $Range/Shape
var players = []
var tl
var br

@export var top_left = Vector2i(-100, -100):
	set(new_position):
		top_left = new_position
		if lock == null: return
		refresh()
		
@export var bottom_right = Vector2i(100, 100):
	set(new_position):
		bottom_right = new_position
		if lock == null: return
		refresh()

@export var top_left_range = Vector2i(-200, -200):
	set(new_position):
		top_left_range = new_position
		if lockrange == null: return
		refresh()

@export var bottom_right_range = Vector2i(200, 200):
	set(new_position):
		bottom_right_range = new_position
		if lockrange == null: return
		refresh()

func refresh():
	lock.position = top_left
	lockrange.position = top_left_range
	ls.shape.size = bottom_right - top_left
	ls.position = ls.shape.size/2
	rs.shape.size = bottom_right_range - top_left_range
	rs.position = rs.shape.size/2

func remove():
	for body in players:
		var cam = body.get_node("Camera")
		if cam.limit_sources[Side.SIDE_LEFT] == self: cam.limit(Side.SIDE_LEFT, -10000000, null)
		if cam.limit_sources[Side.SIDE_TOP] == self: cam.limit(Side.SIDE_TOP, -10000000, null)
		if cam.limit_sources[Side.SIDE_RIGHT] == self: cam.limit(Side.SIDE_RIGHT, 10000000, null)
		if cam.limit_sources[Side.SIDE_BOTTOM] == self: cam.limit(Side.SIDE_BOTTOM, 10000000, null)

func _ready() -> void:
	refresh()
	tl = lock.global_position
	br = lock.global_position+Vector2(bottom_right-top_left)

func align_camera(body: Node2D):
	var cam = body.get_node("Camera")
	if -10000000 >= cam.get_limit(Side.SIDE_LEFT) or cam.get_limit(Side.SIDE_LEFT) > tl.x: cam.limit(Side.SIDE_LEFT, tl.x, self)
	if -10000000 >= cam.get_limit(Side.SIDE_LEFT) or cam.get_limit(Side.SIDE_TOP) > tl.y: cam.limit(Side.SIDE_TOP, tl.y, self)
	if 10000000 <= cam.get_limit(Side.SIDE_LEFT) or cam.get_limit(Side.SIDE_RIGHT) > br.x: cam.limit(Side.SIDE_RIGHT, br.x, self)
	if 10000000 <= cam.get_limit(Side.SIDE_LEFT) or cam.get_limit(Side.SIDE_BOTTOM) > br.y: cam.limit(Side.SIDE_BOTTOM, br.y, self)
	cam.force_update_limits()

func force_align(body: Node2D):
	var cam = body.get_node("Camera")
	cam.limit(Side.SIDE_LEFT, tl.x, self)
	cam.limit(Side.SIDE_TOP, tl.y, self)
	cam.limit(Side.SIDE_RIGHT, br.x, self)
	cam.limit(Side.SIDE_BOTTOM, br.y, self)
	cam.force_update_limits()

func _on_ref_body_entered(body: Node2D) -> void:
	if body is Player:
		if body not in players: players.push_back(body)
		align_camera(body)

func _on_ref_body_exited(body: Node2D) -> void:
	if body is Player:
		if body in players: players.erase(body)
		#print(body.name, " exited ", name)
		var cam = body.get_node("Camera")
		if cam.limit_sources[Side.SIDE_LEFT] == self: cam.limit(Side.SIDE_LEFT, -10000000, null)
		if cam.limit_sources[Side.SIDE_TOP] == self: cam.limit(Side.SIDE_TOP, -10000000, null)
		if cam.limit_sources[Side.SIDE_RIGHT] == self: cam.limit(Side.SIDE_RIGHT, 10000000, null)
		if cam.limit_sources[Side.SIDE_BOTTOM] == self: cam.limit(Side.SIDE_BOTTOM, 10000000, null)
