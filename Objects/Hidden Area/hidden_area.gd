@tool
extends Area2D

@export var tilemap : TileMapLayer = null:
	set(new_tilemap):
		if tilemap: tilemap.collision_enabled = true
		if !new_tilemap: return
		tilemap = new_tilemap
		tilemap.collision_enabled = false
		global_position = tilemap.get_used_rect().position*tilemap.tile_set.tile_size+Vector2i(2,2)
		$Collision.shape.size = tilemap.get_used_rect().size*tilemap.tile_set.tile_size-Vector2i(4, 4)
		$Collision.position = $Collision.shape.size/2

var tween

func _on_body_entered(body: Node2D) -> void:
	if tilemap == null: return
	if body is not Player: return
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(tilemap, "modulate:a", 0.25, 0.2)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.play()

func _on_body_exited(body: Node2D) -> void:
	if tilemap == null: return
	if body is not Player: return
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(tilemap, "modulate:a", 1, 0.2)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.play()
