extends Node2D

onready var sprite := $Sprite
var serving_amount = 5

#This function needs to happen in the transitional state between eating & idle:
func eat():
	serving_amount = max(serving_amount - 1, 0)
	sprite.frame = serving_amount
	if serving_amount <= 0:
		for child in get_children():
			if child.has_method("set_available"):
				child.set_available(false)
