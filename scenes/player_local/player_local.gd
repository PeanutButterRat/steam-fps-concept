extends KinematicBody

signal died
signal state_changed(state)

onready var camera: Camera = $'%Camera'
onready var healthbar: ProgressBar = $'%ProgressBar'
onready var hud: Control = $"%HUD"
onready var current_weapon: Weapon = $'%Revolver'

const ACCELERATION_DEFAULT: = 10
const ACCELERATION_AIR_ACTIVE: = 5
const ACCELERATION_AIR_IDLE: = 1
const SLIDE_TIME: float = 0.2
const WALL_COLLISION_INDEX: int = 0

enum State {
	IDLE,
	SPRINTING,
	WALKING,
	SLIDING,
	WALLRUNNING,
	CROUCHED,
	FALLING,
	JUMPING,
	WALLRUN_JUMPING,
}

var max_health: float = 100.0
var health: float = max_health

var crouchwalk_speed: float = 5.0
var walk_speed: float = 10.0
var sprint_speed: float = 20.0
var wallrun_speed: float = 15.0

var speed: float = 10
var acceleration: = ACCELERATION_DEFAULT
var previous_state: int = State.IDLE

var mouse_sensitivity: float = 0.1
var movement_acceleration: float = 5
var wallrun_rotation: float = 5
var slide_timer: float = SLIDE_TIME
var slide_force: float = 100

var velocity: Vector3
var snap: Vector3

var jump_force := 10
var able_to_wallrun: bool = false
var horizontal_walljump_force: float = 10.0
var vertical_walljump_force: float = jump_force

var wallrun_speed_threshold: float = 8.0
var gravity_force := 30
var vector: Vector3 = Vector3.ZERO
var input: Vector3

var weapons: Array = []

onready var debug_timer: Timer = $"%DebugTimer"

var time_to_wallrun: float = 0.5
var wallrun_timer: float = time_to_wallrun

var sprinting: bool = false
var wallrunning: bool = false

func _ready() -> void:
	current_weapon.connect('ammo_changed', self, '_on_Weapon_ammo_changed')
	current_weapon.connect('damaged_mob', self, '_on_Weapon_damaged_mob')
	Global.connect('player_console_enabled', self, '_on_Global_player_console_enabled')
	Global.connect('player_teleported', self, '_on_Global_player_teleported')
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	healthbar.value = health


func _physics_process(delta: float) -> void:
	var horiziontal_rotation = global_transform.basis.get_euler().y  # Direction the player is looking in.
	input = Vector3(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			0,  # No vertical motion calculated here.
			Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	).rotated(Vector3.UP, horiziontal_rotation).normalized()  # Vector representing the horizontal input.
	
	var intended_motion: Vector3  # Horizontal velocity vector.
	var state: int = _get_player_state(delta)
	
	match state:
		State.IDLE:
			intended_motion = input * crouchwalk_speed
			snap = Vector3.DOWN
		State.CROUCHED:
			intended_motion = input * crouchwalk_speed
			snap = Vector3.DOWN
		State.SLIDING:
			intended_motion = input * crouchwalk_speed
			snap = Vector3.DOWN
		State.WALKING:
			intended_motion = input * walk_speed
			snap = Vector3.DOWN
		State.SPRINTING:
			intended_motion = input * sprint_speed
			snap = Vector3.DOWN
		State.JUMPING:
			intended_motion = input * sprint_speed
			velocity.y = jump_force
			snap = Vector3.ZERO
		State.FALLING:
			intended_motion = input * velocity.length()
			velocity.y -= gravity_force * delta
			intended_motion.y = velocity.y
			snap = Vector3.DOWN
		State.WALLRUNNING:
			var wall_normal: Vector3 = get_slide_collision(WALL_COLLISION_INDEX).normal
			snap = -wall_normal
			velocity.y = 0
			
			var orthogonal_direction: Vector3 = wall_normal.cross(Vector3.UP)
			if orthogonal_direction.angle_to(velocity) > 90:
				orthogonal_direction = -orthogonal_direction
			
			velocity = velocity.project(orthogonal_direction).normalized() * wallrun_speed
			velocity += -wall_normal
			intended_motion = velocity
			
		State.WALLRUN_JUMPING:
			var wall_normal: Vector3 = get_slide_collision(WALL_COLLISION_INDEX).normal
			snap = -wall_normal
			velocity += wall_normal.normalized() * horizontal_walljump_force
			velocity.y = vertical_walljump_force
			intended_motion = velocity
	
	velocity = velocity.linear_interpolate(intended_motion, acceleration * delta)
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP)
	
	if state != previous_state:
		emit_signal('state_changed', state)
	previous_state = state
	
	var data: Array = [transform]
	Global.send_signal(Global.SignalConstants.PLAYER_MOVED, data, Global.Recipient.ALL_MINUS_CLIENT)



func _get_player_state(delta: float) -> int:
	var sprinting: bool = Input.is_action_pressed('sprint') and Input.get_action_strength('move_forward') == 1
	var jumped: bool = Input.is_action_just_pressed('jump')
	var crouching: bool = Input.is_action_just_pressed('crouch')
	
	if Console.focused:
		input = Vector3.ZERO
		sprinting = false
		jumped = false
		crouching = false
	
	if is_on_floor():
		wallrun_timer = time_to_wallrun
		
	if is_on_floor() and crouching:
		return State.CROUCHED
	elif is_on_floor() and sprinting:
		return State.JUMPING if jumped else State.SPRINTING
	elif is_on_floor() and input:
		return State.JUMPING if jumped else State.WALKING
	elif is_on_floor():
		return State.JUMPING if jumped else State.IDLE
	
	wallrun_timer -= delta
	if wallrun_timer <= 0 and is_on_wall() and velocity.length() > wallrun_speed_threshold:
		return State.WALLRUN_JUMPING if jumped else State.WALLRUNNING
	else:
		return State.FALLING


func damage(amount: float) -> void:
	health -= amount
	healthbar.value = health


func _on_Self_state_changed(state: int) -> void:
	var data: Array = [state]
	Global.send_signal(Global.SignalConstants.PLAYER_STATE_CHANGED, data, Global.Recipient.ALL_MINUS_CLIENT)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:  # User is rotating their screen.
		self.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))  # Horizontal rotation.
		camera.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))  # Vertical rotation.
		camera.rotation.x = clamp(camera.rotation.x, deg2rad(-89), deg2rad(89))


func _on_Global_player_damaged(data: Array, _sender: int) -> void:
	var id: int = data[0]
	if id == Global.STEAM_ID:
		var amount: float = data[1]
		damage(amount)


func _on_Global_player_teleported(data: Array, _sender: int) -> void:
	var id: int = data[0]
	if id == Global.STEAM_ID:
		var position: Vector3 = data[1]
		translation = position


func _on_Global_player_console_enabled(data: Array, _sender: int) -> void:
	var id: int = data[0]
	if id != Global.STEAM_ID:  # Do not de-op oneself.
		Console.enabled = not Console.enabled


func _on_Weapon_damaged_mob(part: MobHitbox) -> void:
	var mob: Mob = Mob.get_mob_from_part(part)
	
	if mob != null:
		var hitmarker_name: String = Hitmarker.NORMAL_ANIMATION_NAME
		if mob.is_dead():
			hitmarker_name = Hitmarker.KILL_ANIMATION_NAME
			mob.kill()
		elif part.is_critical():
			hitmarker_name = Hitmarker.CRITICAL_ANIMATION_NAME
		
		hud.play_hitmarker(hitmarker_name)


func _on_Weapon_ammo_changed(current_ammo: int, magazine_capacity: int, reserve_capacity: int) -> void:
	hud.set_ammo_count(current_ammo, magazine_capacity, reserve_capacity)


func add_weapon(weapon: Weapon) -> void:
	weapons.append(weapon)


func remove_weapon(weapon: Weapon) -> void:
	weapons.erase(weapon)


func _on_DebugTimer_timeout():
	$"%Position".text = str(translation)
	$"%InputLabel".text = str(input)
	$"%VelocityLabel".text = str(velocity.length())
	$"%StateLabel".text = str(State.keys()[previous_state])
