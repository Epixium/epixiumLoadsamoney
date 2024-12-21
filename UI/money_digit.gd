@tool
extends TextureRect

var tween

@export_range(0, 9) var number : int = 0:
	set(new_number):
		if number == new_number: return
		number = new_number
		set_digit(number)

func set_digit(digit : int):
	if !(digit in range(0, 10)): push_error(str(digit) + " is not a valid money digit!"); return
	texture.region = Rect2(80*digit, 0, 80, 96)
	position.y = min(position.y, -10)
	position.y -= randi_range(10, 5)/(abs(position.y)**2)
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position:y", 0, 0.1)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.play()
