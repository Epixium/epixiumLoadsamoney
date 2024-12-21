extends HBoxContainer

var UIHeart = preload("res://UI/health_heart.tscn")
var amount = 0
const MIN_HEART_COUNT = 3
var heart_count = 0

func _ready():
	alter_hp_count(GameState.health)
	GameState.health_changed.connect(_on_health_added)

func _int_to_array(temp):
	var arr = []
	for c in str(temp):
		arr.append(int(c))
	return arr

func update_count(num : int):
	heart_count = num
	var children = get_children()
	if len(children) != heart_count: alter_hp_count(heart_count)
	children = get_children()
	children.reverse()
	for child in get_children():
		if !child.is_in_group("HealthHeart") or !child.heartActive: children.erase(child); continue
	for i in range(GameState.health):
		if i < GameState.health-GameState.extra_health: children[i].type = 1
		elif i < GameState.max_health: children[i].type = 0
		else: children[i].type = 2

func alter_hp_count(count : int):
	heart_count = count
	for child in get_children():
		if !child.is_in_group("HealthHeart"): continue
		child.heartActive = false
		child.hide()
		child.queue_free()
	for num in max(count, MIN_HEART_COUNT):
		var uih = UIHeart.instantiate()
		add_child(uih)

func _on_health_added(_health):
	update_count(GameState.health)
