extends Position2D

var available := true

#func set_occupied(value: bool):
#	occupied = value
#	if occupied:
#		$DebugLabel.text = "Occupied"
#	else:
#		$DebugLabel.text = "Vacant"
#
#func is_occupied() -> bool:
#	return occupied
	
func set_available(value: bool):
	available = value
	if not available:
		$DebugLabel.text = "Not available"
	else:
		$DebugLabel.text = "Available"

func is_available() -> bool:
	return available
