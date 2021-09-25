extends Node2D

enum State{
	IDLE,
	HUNGRY,
	EATING,
	SLEEPY,
	ASLEEP,
}

const SPRITE_FRAME = {
	State.IDLE: 0,
	State.HUNGRY: 0,
	State.EATING: 1,
	State.SLEEPY: 0,
	State.ASLEEP: 2,
}

enum FoodType{
	VEG,
	MEAT,
	TALL,
}

export(FoodType) var food_type = FoodType.VEG
export var move_speed = 100
const BOUNCE_OFFSET = -12
const BOUNCE_DURATION = 0.2
onready var tween := $Tween
onready var sprite := $Sprite
onready var reaction := $Reactions
onready var thoughtbubble := get_node("Reactions/ThoughtBubble")

onready var THOUGHT_FRAME = {
	State.IDLE: 0,
	State.HUNGRY: 2 if food_type == FoodType.MEAT else 1,
	State.EATING: 0,
	State.SLEEPY: 3,
	State.ASLEEP: 0,
}

onready var debug_state_label = $DebugLabel

var hunger = 1
export var hunger_speed = 1
var hunger_max = 10
var energy = 10
export var energy_speed = 1
var current_state = State.IDLE
var target_zone = null

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	print("Hunger = ", hunger)
	print("Energy = ", energy)
	print(THOUGHT_FRAME)

func _process(delta):
	debug_state_label.text = "State: " + State.keys()[current_state]
	var direction = Vector2(0, 0)
	if current_state == State.IDLE:
		direction = idle()
	if current_state == State.HUNGRY:
		direction = hungry()
	elif current_state == State.EATING:
		direction = eating()
	sprite.frame = SPRITE_FRAME[current_state]
	thoughtbubble.frame = THOUGHT_FRAME[current_state]
	thoughtbubble.visible = thoughtbubble.frame != 0
	reaction.global_position.x = sprite.get_node("Position2D").global_position.x
	dino_move(delta, direction)

func _on_Timer_timeout():
	if current_state == State.EATING:
		hunger = min(hunger + hunger_max / 2, hunger_max)
	else:
		hunger = max(hunger - hunger_speed, 0)
	energy -= energy_speed
	print("Hunger = ", hunger)
	print("Energy = ", energy)

func idle():
	emit_particles(null)
	if hunger <= 0:
		current_state = State.HUNGRY
		
	var target_pos := Vector2(250, 250)
	var vec_to_target := target_pos - position
	if vec_to_target.length() > 80:
		var direction := vec_to_target.normalized()
		return direction
	else:
		return Vector2(0, 0)

func hungry() -> Vector2:
	thoughtbubble.visible = true
	#Pick a random food zone to travel to
	if target_zone == null:
		var food_zones = get_tree().get_nodes_in_group(FoodType.keys()[food_type])
		if not food_zones:
			return Vector2(0, 0)
		var rand_food_zone = food_zones[randi()%food_zones.size()]
		if rand_food_zone.is_occupied():
			return Vector2(0, 0)
		target_zone = rand_food_zone
		target_zone.set_occupied(true)
	var food_pos: Vector2 = target_zone.global_position
	var vec_to_food := food_pos - position
	
	#Flip sprite to face food bowl
	if vec_to_food.length() < 10:
		var food_bowl = target_zone.get_parent()
		if food_bowl.position.x - position.x > 0:
			sprite.scale.x = -8
		else:
			sprite.scale.x = 8

		current_state = State.EATING
		return Vector2(0, 0)
	
	var direction := vec_to_food.normalized()
	return direction
	
func eating():
	emit_particles("Heart")
	if hunger >= hunger_max:
		print("HE DO BE FULL")
		current_state = State.IDLE
		target_zone.set_occupied(false)
		target_zone = null
	return Vector2(0, 0)
	
	
func dino_move(delta, direction: Vector2):
	#Move + flip sprite to face travel dirction
	if direction.x > 0:
		sprite.scale.x = -8
		#sprite.set_flip_h(true)
	elif direction.x < 0:
		sprite.scale.x = 8
		#sprite.set_flip_h(false)
	position += direction * move_speed * delta
	
	#Bounce animation
	if direction.length_squared() > 0 and not tween.is_active():
		tween.interpolate_property(
			sprite, "position",
			Vector2(0, 0), Vector2(0, BOUNCE_OFFSET),
			BOUNCE_DURATION / 2.0,
			Tween.TRANS_QUAD, Tween.EASE_OUT
		)
		tween.interpolate_property(
			sprite, "position",
			Vector2(0, BOUNCE_OFFSET), Vector2(0, 0),
			BOUNCE_DURATION / 2.0,
			Tween.TRANS_QUAD, Tween.EASE_IN,
			BOUNCE_DURATION / 2.0
		)
		tween.start()
		
func emit_particles(effect):
	for n in reaction.get_children():
		if n is Particles2D:
			if n.name == effect:
				n.emitting = true
			else:
				n.emitting = false
