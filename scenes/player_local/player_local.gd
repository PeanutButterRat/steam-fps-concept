extends Mob


signal respawned

onready var camera: Camera = $'%Camera'
onready var healthbar: ProgressBar = $'%ProgressBar'
onready var hud: Control = $"%HUD"
onready var current_weapon: Weapon = $'%Revolver'
onready var debug_timer: Timer = $"%DebugTimer"

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

var crouchwalk_speed: float = 5.0
var walk_speed: float = 10.0
var sprint_speed: float = 20.0
var wallrun_speed: float = 15.0
var last_attacking_mob: String

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

var jump_force: float = 10.0
var able_to_wallrun: bool = false
var horizontal_walljump_force: float = 10.0
var vertical_walljump_force: float = jump_force

var wallrun_speed_threshold: float = 8.0
var gravity_force := 30
var vector: Vector3 = Vector3.ZERO
var input: Vector3

var weapons: Array = []
var time_to_wallrun: float = 0.4
var wallrun_timer: float = time_to_wallrun

var wallrunning: bool = false


func _ready() -> void:
	current_weapon.connect('ammo_changed', self, '_on_Weapon_ammo_changed')
	Global.connect('player_console_enabled', self, '_on_Global_player_console_enabled')
	Global.connect('player_teleported', self, '_on_Global_player_teleported')
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	healthbar.value = health
	camera.current = true


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
	
	previous_state = state
	
	var data: Array = [id, transform]
	Global.send_signal(Global.Signals.MOB_MOVED, data)


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


func set_health(amount: float) -> void:
	health -= amount
	healthbar.value = health


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:  # User is rotating their screen.
		self.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))  # Horizontal rotation.
		camera.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))  # Vertical rotation.
		camera.rotation.x = clamp(camera.rotation.x, deg2rad(-89), deg2rad(89))


func damage(amount: float, attacker: int) -> void:
	.damage(amount, attacker)
	healthbar.value = health


func _on_Global_player_teleported(data: Array) -> void:
	var id: int = data[0]
	var position: Vector3 = data[1]
	if id == Global.STEAM_ID:
		translation = position


func _on_Global_player_console_enabled(data: Array) -> void:
	var id: int = data[0]
	if id == Global.STEAM_ID:  # Do not de-op oneself.
		Console.enabled = true


func _on_Weapon_ammo_changed(current_ammo: int, magazine_capacity: int, reserve_capacity: int) -> void:
	hud.set_ammo_count(current_ammo, magazine_capacity, reserve_capacity)


func add_weapon(weapon: Weapon) -> void:
	weapons.append(weapon)


func remove_weapon(weapon: Weapon) -> void:
	weapons.erase(weapon)


func _on_DebugTimer_timeout():
	$"%Position".text = str(translation)
	$"%VelocityLabel".text = str(velocity.length())
	$"%StateLabel".text = str(State.keys()[previous_state])
	$'%Raycast'.text = current_weapon._raycast.get_collider().name if current_weapon._raycast.get_collider() else 'Nothing'
