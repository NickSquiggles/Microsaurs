extends Node2D

onready var tween := $Tween
onready var sprite := $Sprite
onready var particles := $Particles2D
const BOUNCE_OFFSET = -30
const BOUNCE_DURATION = 0.8
var bouncing = false

enum PlayType{
	NONE,
	BOUNCE,
}

export(PlayType) var play_type = PlayType.NONE

func play():
	match play_type:
		PlayType.NONE: particles.emitting = true
		PlayType.BOUNCE: bouncing = true

func stop():
	match play_type:
		PlayType.NONE: particles.emitting = false
		PlayType.BOUNCE: bouncing = false
	
func _process(delta):	
	if bouncing == true and not tween.is_active():
		tween.interpolate_property(
			sprite, "position",
			Vector2(0, 0), Vector2(0, BOUNCE_OFFSET),
			BOUNCE_DURATION / 4.0,
			Tween.TRANS_QUAD, Tween.EASE_OUT
		)
		tween.interpolate_property(
			sprite, "position",
			Vector2(0, BOUNCE_OFFSET), Vector2(0, 0),
			(BOUNCE_DURATION / 4.0) * 3.0,
			Tween.TRANS_BOUNCE, Tween.EASE_OUT,
			BOUNCE_DURATION / 4.0
		)
		tween.start()
