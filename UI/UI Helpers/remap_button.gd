@tool

extends Button
class_name RemapButton

@export var coolname: String:
	set(new_name):
		coolname = new_name
		$Name.text = "[center]" + coolname + "[/center]"
@export var action: String

func _init():
	toggle_mode = true
	theme_type_variation = "RemapButton"

func _ready():
	set_process_unhandled_input(false)
	update_key_text()

func _toggled(button_pressed):
	if Engine.is_editor_hint(): return
	set_process_unhandled_input(button_pressed)
	if button_pressed:
		text = "..."
		release_focus()
	else:
		update_key_text()
		grab_focus()

func _unhandled_input(event):
	if Engine.is_editor_hint(): return
	if event.pressed:
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)
		button_pressed = false

func update_key_text():
	if Engine.is_editor_hint(): return
	text = "%s" % InputMap.action_get_events(action)[0].as_text()
	text = text.replace(" (Physical)", "")
