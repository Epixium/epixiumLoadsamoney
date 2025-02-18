extends Node

var gravity : float = 1200.0
var debug : bool = true
var tileSet : TileMapLayer = null
var breakTileSet : TileMapLayer = null
var collectibles := 0
var total_collectibles := 0
var max_health := 3
var health : int = max_health
var extra_health : int = 0

signal num_collectibles_changed(num_collectibles)
signal health_changed(health_amount)
signal player_died
signal level_loaded
signal debug_toggled(on)

func _ready() -> void:
	pass
	#grav_dir = grav_dir.normalized()
	#up_dir = up_dir.normalized()

func give_collectibles(num_collects_given = 1):
	collectibles += num_collects_given
	total_collectibles += num_collects_given
	num_collectibles_changed.emit(num_collects_given)

func change_health(changed_health = 0, is_extra = false):
	health += changed_health
	if is_extra: extra_health += changed_health
	health_changed.emit(health)
	if (health == 0):
		handle_player_death()

func handle_player_death():
	player_died.emit()

func toggle_debug(on):
	debug = on
	debug_toggled.emit(on)
