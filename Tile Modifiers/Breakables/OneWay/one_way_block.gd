extends StaticBody2D

@export_enum("Left", "Right") var direction : String
var tilePos = Vector2i(0,0)
var broken = false

func _ready():
	tilePos = GameState.breakTileSet.local_to_map(global_position)
	match direction:
		"Left":
			$Sprite.flip_h = true
			$Breakable/Collision.position.x = -58
		"Right":
			pass
	$Breakable/Break.pitch_scale = randf_range(0.8, 1.2)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerHitbox") and !broken:
		GameState.tileSet.erase_cell(tilePos)
		GameState.tileSet.erase_cell(Vector2(tilePos.x-1, tilePos.y))
		GameState.tileSet.erase_cell(Vector2(tilePos.x, tilePos.y-1))
		GameState.tileSet.erase_cell(Vector2(tilePos.x-1, tilePos.y-1))
		$Breakable/Break.play()
		$Breakable/Part.restart()
		$Sprite.hide()
		$Collision.set_deferred("disabled", true)
		broken = true
		await get_tree().create_timer($Breakable/Part.lifetime,false).timeout
		queue_free()
