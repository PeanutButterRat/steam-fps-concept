extends Spatial


signal reloaded
signal ammo_count_changed
signal aimed_down_sights
signal fired_weapon(weapon)

const RELOAD_ANIMATION: String = 'reload'
const FIRE_ANIMATION: String = 'shoot'
const MAX_FIRE_RATE: float = 5.0  # Measured in shots per second.
const MINIMUM_TIMER_LENGTH: float = 0.05

export var mag_capacity: int = 30  # Max rounds per mag.
export var fire_rate: float = 0  # Measured in shots per second.
export var damage: float = 25
export var full_auto: bool = false

onready var animation_player: AnimationPlayer = $'%AnimationPlayer'
onready var shot_timer: Timer = Timer.new()

var ammo_count: int = mag_capacity setget set_ammo_count  # Number of rounds in current mag.
var ready_to_fire: bool = true


func _ready() -> void:
	animation_player.connect('animation_finished', self, '_on_AnimationPlayer_animation_finished')
	
	fire_rate = clamp(fire_rate, 0, MAX_FIRE_RATE)
	var seconds_per_shot: float = MINIMUM_TIMER_LENGTH
	if fire_rate > 0:  # Fire rate of zero means fire rate is unlocked.
		seconds_per_shot = 1.0 / fire_rate
	
	add_child(shot_timer)
	shot_timer.one_shot = true
	shot_timer.set_wait_time(seconds_per_shot)


func shoot() -> void:
	if ammo_count <= 0:
		reload()
	elif shot_timer.is_stopped():
		animation_player.stop()
		set_ammo_count(ammo_count - 1)
		shot_timer.start()
		animation_player.play(FIRE_ANIMATION)
		emit_signal('fired_weapon', self)


func reload() -> void:
	if ammo_count < mag_capacity:
		animation_player.play(RELOAD_ANIMATION)


func ads() -> void:
	pass  # Animate ads.


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == RELOAD_ANIMATION:
		set_ammo_count(mag_capacity)
		emit_signal('reloaded')


func set_ammo_count(count: int) -> void:
	ammo_count = count
	emit_signal('ammo_count_changed')
