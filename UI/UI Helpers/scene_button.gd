extends Button

@export_file("*.tscn") var scene

func _on_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene)
