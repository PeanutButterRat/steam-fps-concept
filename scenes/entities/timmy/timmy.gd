extends "res://scenes/entities/player_online/player_online.gd"


var velocity: Vector3 = Vector3.ZERO
var gravity_force: float = 30

func _ready() -> void:
	set_nametag('Timmy')



func _physics_process(delta: float) -> void:
	if is_on_floor(): velocity.y = 0
	else: velocity.y -= gravity_force * delta
	
	move_and_slide(velocity)
