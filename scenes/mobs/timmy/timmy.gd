extends Mob


onready var nametag: Label3D = $'%Nametag'

export var _gravity_force: float = 30

var _velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	nametag.text = 'Timmy'
	nickname = 'Timmy'


func _physics_process(delta: float) -> void:
	if is_on_floor():
		_velocity.y = 0
	else:
		_velocity.y -= _gravity_force * delta
	
	move_and_slide(_velocity)
