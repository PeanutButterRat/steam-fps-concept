extends KinematicBody


signal died

onready var camera: Camera = $'%Camera'
onready var raycast_label: Label = $'%RaycastLabel'
onready var healthbar: ProgressBar = $'%ProgressBar'
onready var current_weapon: Spatial = $'%Rifle'
onready var raycast: RayCast = $'%RayCast'
onready var ammo_label: Label = $'%AmmoCount'
onready var position_label: Label = $'%Position'
onready var animations: AnimationPlayer = $'%AnimationPlayer'
onready var hud: Control = $"%HUD"

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

var health: float = MAX_HEALTH setget set_health


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Global.connect('event_occurred', self, '_on_Global_event_occurred')
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
		
		if Input.is_action_just_pressed("jump") and not Console.focused:
			snap = Vector3.ZERO
			velocity.y =  jump_force
		
	else:  # Player is in the air: normal gravity simulation.
		snap = Vector3.DOWN
		velocity.y -= gravity_force * delta
		acceleration = ACCELERATION_AIR_ACTIVE if input else ACCELERATION_AIR_IDLE
	
	if Console.focused:
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
	raycast_label.text = raycast.get_collider().name if raycast.is_colliding() else 'Nothing'
	
	var data: Array = [transform]
	Global.emit_event(Global.Events.PLAYER_MOVED, data, Global.Recipient.ALL_MINUS_CLIENT)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:  # User is rotating their screen.
		self.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))  # Horizontal rotation.
		camera.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))  # Vertical rotation.
		camera.rotation.x = clamp(camera.rotation.x, deg2rad(-89), deg2rad(89))
	elif event.is_action_pressed('shoot'):
		current_weapon.shoot()
	elif event.is_action_pressed('reload'):
		current_weapon.reload()


func _on_Rifle_fired_weapon(weapon) -> void:
	Global.emit_event(Global.Events.WEAPON_FIRED, [Global.STEAM_ID], Global.Recipient.ALL_MINUS_CLIENT)
	
	if raycast.is_colliding() and raycast.get_collider() is Node:
		var collider: Node = raycast.get_collider()
		var data: Array
		var recipient: int
		var root: Node = collider.owner
		
		print(collider, ' ', root)
		
		if collider.has_method('damage'):
			var killed: bool = collider.damage()
			
			if killed:
				hud.kill_hitmarker()
			elif collider.is_in_group('CriticalHitbox'):
				hud.critical_hitmarker()
			else:
				hud.normal_hitmarker()


func _on_Rifle_ammo_count_changed() -> void:
	hud.update_ammo_count(current_weapon.ammo_count, current_weapon.mag_capacity)


func damage(damage: float) -> bool:
	set_health(health - damage)
	if health <= 0:
		kill()
		return true
	
	return false


func kill() -> void:
	set_health(MAX_HEALTH)
	emit_signal('died')


func _on_Global_event_occurred(event: int, packet: Dictionary) -> void:
	if event == Global.Events.PLAYER_DAMAGED:
		var amount: float = packet[Global.EVENT_DATA][0]
		damage(amount)
	elif event == Global.Events.PLAYER_TELEPORTED:
		var position: Vector3 = packet[Global.EVENT_DATA][0]
		translation = position
	elif event == Global.Events.PLAYER_OP:
		Console.enabled = not Console.enabled


func set_health(amount: float) -> void:
	health = amount
	healthbar.value = amount
