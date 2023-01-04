class_name HitscanWeapon extends Weapon


const FIRE_ANIMATION_NAME: String = 'fire'
const RELOAD_ANIMATION_NAME: String = 'reload'
const AIM_ANIMATION_NAME: String = 'aim'

export var _automatic: bool = false
export var _critical_multiplier: float = 1.3
export var _buffered_shots: bool = false
export var _buffered_time: float = 1.0
export var _effective_range: float = 100.0
export var _shots_per_second: float = 3.0

onready var _shot_timer: Timer = $"%ShotTimer"
onready var _animations: AnimationPlayer = $'%AnimationPlayer'
onready var _raycast: RayCast = $'%RayCast'


var _buffered: bool = false


func _ready() -> void:
	connect('attacked', self, '_on_Self_attacked')
	_shot_timer.wait_time = 1 / clamp(_shots_per_second, MIN_ATTACKS_PER_SECOND, MAX_ATTACKS_PER_SECOND)
	_current_ammo = _magazine_capacity


func swap_weapon() -> void:
	_animations.play(SWAP_ANIMATION_NAME)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('attack'):
		attack()
		get_tree().set_input_as_handled()
	
	elif event.is_action_pressed('reload'):
		reload()
		get_tree().set_input_as_handled()


func aim() -> void:
	pass


func attack() -> void:
	if _current_ammo <= 0:
		reload()
	elif _shot_timer.is_stopped():
		_animations.stop()
		_animations.play(FIRE_ANIMATION_NAME)
		_shot_timer.start()
		_current_ammo -= 1
		emit_signal('ammo_changed', _current_ammo, _magazine_capacity, _reserve_capacity)
		emit_signal('attacked')
	elif _buffered_shots and _shot_timer.time_left <= _buffered_time:
		_buffered = true


func reload() -> void:
	if _animations.current_animation != RELOAD_ANIMATION_NAME and _current_ammo < _magazine_capacity:
		_animations.stop()
		_animations.play(RELOAD_ANIMATION_NAME)
		emit_signal('reloaded')


func _on_ShotTimer_timeout() -> void:
	if _automatic and Input.is_action_pressed('shoot'):
		attack()
	elif _buffered:
		attack()
		_buffered = false


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == SWAP_ANIMATION_NAME:
		emit_signal('swapped')
	elif anim_name == RELOAD_ANIMATION_NAME:
		_current_ammo = _magazine_capacity
		emit_signal('ammo_changed', _current_ammo, _magazine_capacity, _reserve_capacity)


func _on_Self_attacked():
	if _raycast.get_collider() is MobHitbox:
		var part: MobHitbox = _raycast.get_collider()
		part.damage(_damage)
		emit_signal('damaged_mob', part)
