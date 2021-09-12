extends Camera2D


func _unhandled_input(event):
	if event is InputEventScreenDrag:
		position.x -= event.relative.x
