extends Node2D

# emitted with two parameters; the previous state and the new state
signal state_changed

enum State{
	IDLE,
	HUNGRY,
	EATING,
	SLEEPY,
	ASLEEP,
	BORED,
	PLAYING,
}

const SPRITE_FRAME = {
	State.IDLE: 0,
	State.HUNGRY: 0,
	State.EATING: 1,
	State.SLEEPY: 0,
	State.ASLEEP: 2,
	State.BORED: 0,
	State.PLAYING: 0,
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
	State.BORED: 6,
	State.PLAYING: 0,
}

onready var debug_state_label = $DebugLabel

var hunger = 10
export var hunger_speed = 1
var hunger_max = 10
var energy = 1
export var energy_speed = 1
var energy_max = 10
var happiness = 10
export var happiness_speed = 1
var happiness_max = 10
var current_state = State.IDLE
var target_node = null
var target_zone = null
var bed_offset = null
var bouncing = false

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	if connect("state_changed", self, "_on_state_changed"):
		push_error("failed to connect state changed signal")
	debug_print_state()

func _process(delta):
	var direction = Vector2(0, 0)
	
	match current_state:
		State.IDLE: direction = idle()
		State.HUNGRY: direction = hungry()
		State.EATING: direction = eating()
		State.SLEEPY: direction = sleepy()
		State.ASLEEP: direction = asleep()
		State.BORED: direction = bored()
		State.PLAYING: direction = playing()
	
	sprite.frame = SPRITE_FRAME[current_state]
	
	thoughtbubble.frame = THOUGHT_FRAME[current_state]
	thoughtbubble.visible = thoughtbubble.frame != 0
	
	reaction.global_position.x = sprite.get_node("Position2D").global_position.x
	
	if bouncing == true and not tween.is_active():
		tween.interpolate_property(
			sprite, "position",
			Vector2(0, 0), Vector2(0, BOUNCE_OFFSET),
			BOUNCE_DURATION / 0.5,
			Tween.TRANS_BACK, Tween.EASE_OUT
		)
		tween.interpolate_property(
			sprite, "position",
			Vector2(0, BOUNCE_OFFSET), Vector2(0, 0),
			BOUNCE_DURATION / 0.5,
			Tween.TRANS_BACK, Tween.EASE_IN,
			BOUNCE_DURATION / 0.5
		)
		tween.start()
	
	dino_move(delta, direction)

func state_name(state: int) -> String:
	return State.keys()[state]

func change_state(new_state: int) -> void:
	# do nothing if we're trying to change to a state we're already in.
	if new_state == current_state:
		return
	
	# Trigger the '_on_state_Changed' function
	emit_signal("state_changed", current_state, new_state)
	current_state = new_state

func _on_state_changed(old_state: int, new_state: int) -> void:
	print(name, " changing state from ", state_name(old_state), " to ", state_name(new_state))
	debug_state_label.text = "State: " + state_name(new_state)
	
	if new_state == State.IDLE:
		emit_particles(null)
		if old_state == State.PLAYING:
			target_node.stop()
			bouncing = false
	
	if new_state == State.EATING:
		emit_particles("Heart")
		target_node.eat()
		
	if new_state == State.SLEEPY:
		bed_offset = rand_vector() * 15
	
	if new_state == State.ASLEEP:
		emit_particles("Z")
	
	if new_state == State.PLAYING:
		emit_particles("Smile")

func debug_print_state() -> void:
	print("%17s" % [name], " | Hunger: ", hunger, ", Energy: ", energy, ", Happiness: ", happiness)

func _on_Timer_timeout():
	if current_state == State.EATING:
		hunger = min(hunger + hunger_max / 2, hunger_max)
	else:
		hunger = max(hunger - hunger_speed, 0)
		
	if current_state == State.ASLEEP:
		energy = min(energy + energy_max / 2, energy_max)
	else:
		energy = max(energy - energy_speed, 0)
		
	if current_state == State.PLAYING:
		happiness = min(happiness + happiness_max / 2, happiness_max)
	else:
		happiness = max(happiness - happiness_speed, 0)
	debug_print_state()

func idle() -> Vector2:
	if hunger <= 0:
		change_state(State.HUNGRY)
		return Vector2(0, 0)
		
	if energy <= 0:
		change_state(State.SLEEPY)
		return Vector2(0, 0)
	
	if happiness <= 0:
		change_state(State.BORED)
		return Vector2(0, 0)
	
	var target_pos := Vector2(250, 250)
	var vec_to_target := target_pos - position
	if vec_to_target.length() > 80:
		var direction := vec_to_target.normalized()
		return direction
	else:
		return Vector2(0, 0)

func hungry() -> Vector2:
	#Pick a random food zone to travel to
	if target_zone == null:
		var food_zones = get_tree().get_nodes_in_group(FoodType.keys()[food_type])
		if not food_zones:
			return Vector2(0, 0)
		var rand_food_zone = food_zones[randi()%food_zones.size()]
		if rand_food_zone.is_occupied() or rand_food_zone.get_parent().serving_amount == 0:
			return Vector2(0, 0)
		target_zone = rand_food_zone
		target_zone.set_occupied(true)
	var food_pos: Vector2 = target_zone.global_position
	var vec_to_food := food_pos - position
	
	#Flip sprite to face food bowl
	if vec_to_food.length() < 10:
		target_node = target_zone.get_parent()
		if target_node.position.x - position.x > 0:
			sprite.scale.x = -8
		else:
			sprite.scale.x = 8
	
		if target_node.serving_amount > 0:
			change_state(State.EATING)
		return Vector2(0, 0)
	
	var direction := vec_to_food.normalized()
	return direction
	
func eating() -> Vector2:
	if hunger >= hunger_max:
		print("HE DO BE FULL")
		target_zone.set_occupied(false)
		target_zone = null
		change_state(State.IDLE)
	
	return Vector2(0, 0)

func sleepy() -> Vector2:
	#Pick a random sleep zone to travel to
	if target_zone == null:
		var sleep_zones = get_tree().get_nodes_in_group("BED")
		if not sleep_zones:
			return Vector2(0, 0)
		var rand_sleep_zone = sleep_zones[randi()%sleep_zones.size()]
		if rand_sleep_zone.is_occupied():
			return Vector2(0, 0)
		target_zone = rand_sleep_zone
		target_zone.set_occupied(true)
	var bed_pos: Vector2 = target_zone.global_position + bed_offset
	var vec_to_bed := bed_pos - position
	
	#Flip sprite to face food bowl
	if vec_to_bed.length() < 5:
		target_node = target_zone.get_parent()
		if target_node.position.x - position.x > 0:
			sprite.scale.x = -8
		else:
			sprite.scale.x = 8
		
		change_state(State.ASLEEP)

		return Vector2(0, 0)
	
	var direction := vec_to_bed.normalized()
	return direction
	
func asleep() -> Vector2:
	if energy >= energy_max:
		print("HE DO BE RESTED")
		target_zone.set_occupied(false)
		target_zone = null
		change_state(State.IDLE)
	
	return Vector2(0, 0)
	
func bored() -> Vector2:
	#Pick a random play zone to travel to
	if target_zone == null:
		var play_zones = get_tree().get_nodes_in_group("TOY")
		if not play_zones:
			return Vector2(0, 0)
		var rand_play_zone = play_zones[randi()%play_zones.size()]
		if rand_play_zone.is_occupied():
			return Vector2(0, 0)
		target_zone = rand_play_zone
		target_zone.set_occupied(true)
	var toy_pos: Vector2 = target_zone.global_position
	var vec_to_toy := toy_pos - position
	
	#Flip sprite to face food bowl
	if vec_to_toy.length() < 5:
		target_node = target_zone.get_parent()
		if target_node.position.x - position.x > 0:
			sprite.scale.x = -8
		else:
			sprite.scale.x = 8
		
		change_state(State.PLAYING)

		return Vector2(0, 0)
	
	var direction := vec_to_toy.normalized()
	return direction
	
func playing() -> Vector2:
	target_node.play()
	match target_node.play_type:
		target_node.PlayType.NONE: pass
		target_node.PlayType.BOUNCE: bouncing = true
	
	if happiness >= happiness_max:
		print("HE DO BE PLAYING")
		target_zone.set_occupied(false)
		target_zone = null
		change_state(State.IDLE)
	
	return Vector2(0, 0)
	
func rand_vector() -> Vector2:
  var vec = Vector2(
	rand_range(-1, 1),
	rand_range(-1, 1)
  )
  return vec.normalized()

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
