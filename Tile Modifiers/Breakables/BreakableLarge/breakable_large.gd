extends Breakable

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerHitbox") and !broken:
		$Break.play()
		$Part.restart()
		GameState.tileSet.erase_cell(tilePos)
		GameState.tileSet.erase_cell(Vector2(tilePos.x+1, tilePos.y))
		GameState.tileSet.erase_cell(Vector2(tilePos.x, tilePos.y+1))
		GameState.tileSet.erase_cell(Vector2(tilePos.x+1, tilePos.y+1))
		broken = true
		await get_tree().create_timer($Part.lifetime,false).timeout
		GameState.breakTileSet.erase_cell(tilePos)
		queue_free()
