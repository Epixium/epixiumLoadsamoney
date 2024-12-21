extends Area2D

class_name Breakable

var tilePos = Vector2i(0,0)
var broken = false

func _ready():
	tilePos = GameState.breakTileSet.local_to_map(global_position)
	$Break.pitch_scale = randf_range(0.8, 1.2)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerHitbox") and !broken:
		$Break.play()
		$Part.restart()
		GameState.tileSet.erase_cell(tilePos)
		broken = true
		await get_tree().create_timer($Part.lifetime,false).timeout
		GameState.breakTileSet.erase_cell(tilePos)
		queue_free()
