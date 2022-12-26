extends Node2D


onready var animation_player: AnimationPlayer = $"%AnimationPlayer"

const NORMAL: Color = Color.white
const CRITICAL: Color = Color.orangered
const KILL: Color = Color.red

const NORMAL_ANIMATION_NAME: String = 'hit'
const CRITICAL_ANIMATION_NAME: String = 'crit'
const KILL_ANIMATION_NAME: String = 'kill'


func _ready():
	var pairs: Dictionary = {
		CRITICAL_ANIMATION_NAME: CRITICAL,
		KILL_ANIMATION_NAME: KILL
	}
	for key in pairs:
		var color: Color = pairs[key]
		var animation: Animation = animation_player.get_animation('hit').duplicate()
		var transparent: Color = color
		transparent.a = 0
		animation.track_set_key_value(0, 0, color)
		animation.track_set_key_value(0, 1, transparent)
		animation_player.add_animation(key, animation)


func _play(animation: String) -> void:
	animation_player.stop()
	animation_player.play(animation)
	
	
func hit() -> void:
	_play(NORMAL_ANIMATION_NAME)


func crit() -> void:
	_play(CRITICAL_ANIMATION_NAME)


func kill() -> void:
	_play(KILL_ANIMATION_NAME)
