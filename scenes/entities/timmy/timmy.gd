extends KinematicBody


const MAX_HEALTH: float = 100.0

onready var nametag: Label3D = $'%Nametag'
onready var steam_id: int

var velocity: Vector3 = Vector3.ZERO
var gravity_force: float = 30
var health: float
var id: int


func _ready() -> void:
	nametag.text = 'Timmy'
	health = MAX_HEALTH
	id = Global.generate_unique_id()


func _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y -= gravity_force * delta
	
	move_and_slide(velocity)


func damage(damage: float) -> bool:
	health -= damage
	var killed: bool = false
	
	if health <= 0:
		Global.emit_event(Global.Events.TIMMY_DIED, [id], Global.Recipient.ALL_MEMBERS)
		killed = true
	else:
		Global.emit_event(Global.Events.TIMMY_DAMAGED, [health], Global.Recipient.ALL_MEMBERS)
	
	return killed
