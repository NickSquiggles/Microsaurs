extends Node2D

enum State{
	IDLE,
	HUNGRY,
	SLEEPY
}

var hunger = 3
var energy = 10
var current_state = State.IDLE

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Hunger = ", hunger)
	print("Energy = ", energy)


func _process(delta):
	if hunger <= 0 and current_state != State.HUNGRY:
		current_state = State.HUNGRY
	if current_state == State.HUNGRY:
		hungry()

func _on_Timer_timeout():
	hunger -= 1
	energy -= 1
	print("Hunger = ", hunger)
	print("Energy = ", energy)

func hungry():
	print("Looking for noms")
