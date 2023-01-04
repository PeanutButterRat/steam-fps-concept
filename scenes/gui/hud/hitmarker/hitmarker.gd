class_name Hitmarker extends Node2D


onready var animation_player: AnimationPlayer = $"%AnimationPlayer"

const NORMAL_COLOR: Color = Color.white
const CRITICAL_COLOR: Color = Color.orangered
const KILL_COLOR: Color = Color.red

const NORMAL_ANIMATION_NAME: String = 'hit'
const CRITICAL_ANIMATION_NAME: String = 'crit'
const KILL_ANIMATION_NAME: String = 'kill'


func _ready():
	var pairs: Dictionary = {
		CRITICAL_ANIMATION_NAME: CRITICAL_COLOR,
		KILL_ANIMATION_NAME: KILL_COLOR
	}
	
	for key in pairs:
		var color: Color = pairs[key]
		var animation: Animation = animation_player.get_animation('hit').duplicate()
		var transparent: Color = color
		transparent.a = 0
		animation.track_set_key_value(0, 0, color)
		animation.track_set_key_value(0, 1, transparent)
		animation_player.add_animation(key, animation)


func play(animation: String) -> void:
	animation_player.stop()
	animation_player.play(animation)
