extends KinematicBody


signal died

onready var camera: Camera = $'%Camera'
onready var position_label: Label = $'%Position'
onready var healthbar: ProgressBar = $'%ProgressBar'
onready var ammo_label: Label = $'%AmmoCount'
onready var current_weapon: Spatial = $'%Rifle'
onready var raycast: RayCast = $'%RayCast'

const ACCELERATION_DEFAULT: = 10
const ACCELERATION_AIR_ACTIVE: = 5
const ACCELERATION_AIR_IDLE: = 1
const SLIDE_TIME: float = 0.2
const MAX_HEALTH: float = 100.0

var acceleration: = ACCELERATION_DEFAULT
var mouse_sensitivity: float = 0.1
var movement_speed: = 10
var walk_speed: = 10
var run_speed: = 20
var movement_acceleration: = 5
var wallrun_rotation: float = 5
var slide_timer: float = SLIDE_TIME
var slide_force: float = 100

var input: Vector3
var velocity: Vector3
var snap: Vector3

var gravity_force := 30
var jump_force := 10
var sprinting: bool = false
var vector: Vector3 = Vector3.ZERO

var health: float = MAX_HEALTH


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	healthbar.value = health

func _physics_process(delta: float) -> void:
	var horiziontal_rotation = global_transform.basis.get_euler().y  # Direction the player is looking in.
	
	input = Vector3(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			0,  # No vertical motion calculated here.
			Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	).rotated(Vector3.UP, horiziontal_rotation).normalized()  # Global vector representing the horizontal input.
	
	sprinting = Input.is_action_pressed("sprint") and Input.get_action_strength("move_forward") > 0
	movement_speed = run_speed if sprinting else walk_speed  # Sprinting (player must be moving forward).
	
	if is_on_floor():
		velocity.y = 0
		snap = -get_floor_normal() * 5
		acceleration = ACCELERATION_DEFAULT
		
		if Input.is_action_just_pressed("jump"):
			snap = Vector3.ZERO
			velocity.y =  jump_force
		
	else:  # Player is in the air: normal gravity simulation.
		snap = Vector3.DOWN
		velocity.y -= gravity_force * delta
		acceleration = ACCELERATION_AIR_ACTIVE if input else ACCELERATION_AIR_IDLE
	
	if Console.is_focused():
		input = Vector3.ZERO
	
	var movement: Vector3 = input * movement_speed  # Horizontal velocity vector.
	movement.y = velocity.y  # Match the y velocity components so that when the velocity is interpolated, gravity is unaffected.
	
	if vector:
		snap = Vector3.ZERO
		velocity += vector
		vector = Vector3.ZERO
	
	velocity = velocity.linear_interpolate(movement, acceleration * delta)  # Apply acceleration
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true, 5, 1, true)
	
	
	position_label.text = str(translation)
	
	var data: Array = [transform]
	Global.emit_event(Global.Events.PLAYER_MOVED, data, Global.Recipient.ALL_MINUS_HOST)
	
	if Input.is_action_just_pressed('shoot'):
		current_weapon.shoot()
	elif Input.is_action_just_pressed('reload'):
		current_weapon.reload()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:  # User is rotating their screen.
		self.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))  # Horizontal rotation.
		camera.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))  # Vertical rotation.
		camera.rotation.x = clamp(camera.rotation.x, deg2rad(-89), deg2rad(89))


func _on_Rifle_fired_weapon(weapon) -> void:
	if raycast.is_colliding() and raycast.get_collider() is Node:
		var collider: Node = raycast.get_collider()
		var data: Array
		var recipient: int
		
		if collider.is_in_group('online_players'):
			data = [weapon.damage]
			recipient = collider.steam_id
			Global.emit_event(Global.Events.PLAYER_DAMAGED, data, recipient)
		
		if collider.is_in_group('world'):
			data = [raycast.get_collision_point()]
			Global.emit_event(Global.Events.SHOT_ENVIRONMENT, data, Global.Recipient.ALL_MEMBERS)


func _on_Rifle_ammo_count_changed() -> void:
	ammo_label.text = '%d / %d' % [current_weapon.ammo_count, current_weapon.mag_capacity]


func damage(damage: float) -> void:
	health -= damage
	if health <= 0:
		kill()
		
	healthbar.value = health


func kill() -> void:
	health = MAX_HEALTH
	emit_signal('died')
