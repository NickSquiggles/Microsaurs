extends Position2D

var occupied := false

func set_occupied(value: bool):
	occupied = value
	if occupied:
		$DebugLabel.text = "Occupied"
	else:
		$DebugLabel.text = "Vacant"

func is_occupied() -> bool:
	return occupied
