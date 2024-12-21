extends HBoxContainer

var UINumber = preload("res://UI/money_digit.tscn")
var amount = 0
const MIN_NUM_COUNT = 3
var num_count = 0
@export var num_decimals = 2
@onready var Decimal = $Point

func _ready():
	alter_num_count(3)

func _int_to_array(temp):
	var arr = []
	for c in str(temp):
		arr.append(int(c))
	return arr

func update_count(num : int):
	amount = num
	var num_array = _int_to_array(num)
	var children = get_children()
	for child in get_children():
		if !child.is_in_group("MoneyDigit"): children.erase(child)
	if len(num_array) != num_count: alter_num_count(len(num_array))
	for i in range(len(num_array)-1, -1, -1):
		children[i+(len(children)-len(num_array))].number = num_array[i]

func alter_num_count(count : int):
	num_count = count
	for child in get_children():
		if !child.is_in_group("MoneyDigit"): continue
		child.hide()
		child.queue_free()
	for num in max(count, MIN_NUM_COUNT):
		var uin = UINumber.instantiate()
		add_child(uin)
	move_child($Point, -(num_decimals+1))
