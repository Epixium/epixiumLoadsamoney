extends Camera2D

var limits = [-10000000, -10000000, 10000000, 10000000]
var limit_sources = [null, null, null, null]

@onready var FullColor = $CanvasLayer/FullColor
@onready var PauseScreen = $CanvasLayer/Pause
@onready var MoneyCounter = $CanvasLayer/MoneyCounter

var collected_objects = []

func _ready():
	GameState.num_collectibles_changed.connect(on_collect_given)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = !get_tree().paused
		PauseScreen.visible = !PauseScreen.visible
	if len(collected_objects) > 0: for object in collected_objects:
		object.offset = offset
	$CanvasLayer/FPS.text = str(round(Engine.get_frames_per_second()))

func _physics_process(_delta: float) -> void:
	force_update_limits()

func force_update_limits():
	offset.y = clamp(global_position.y, limits[1]+get_viewport_rect().size.y/2, limits[3]-get_viewport_rect().size.y/2) - global_position.y
	offset.x = clamp(global_position.x, limits[0]+get_viewport_rect().size.x/2, limits[2]-get_viewport_rect().size.x/2) - global_position.x

## direction: (left, top, right, bottom)
func limit(direction, amount, source = null):
	limits[direction] = amount
	limit_sources[direction] = source

func fade_out():
	var tween = get_tree().create_tween()
	tween.tween_property(FullColor, "modulate", Color(0, 0, 0, 1), 0.15)
	tween.play()
	await tween.finished
	return true

func fade_in():
	var tween = get_tree().create_tween()
	tween.tween_property(FullColor, "modulate", Color(0, 0, 0, 0), 0.15)
	tween.play()
	await tween.finished
	return true

func play_collect_animation(object, add):
	object.position -= offset
	collected_objects.append(object)
	var tween = create_tween()
	tween.tween_property(object, "position", MoneyCounter.position + MoneyCounter.size/2 - get_viewport_rect().size/2, 0.5)
	tween.play()
	await tween.finished
	collected_objects.erase(object)
	object.queue_free()
	MoneyCounter.update_count(MoneyCounter.amount+add)

func on_collect_given(_num_collects_given):
	pass #$CanvasLayer/money.text = str(GameState.collectibles)
