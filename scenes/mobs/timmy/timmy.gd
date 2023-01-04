extends Mob


onready var nametag: Label3D = $'%Nametag'

export var gravity_force: float = 30

var _velocity: Vector3 = Vector3.ZERO
var id: int


func _ready() -> void:
	seed(OS.get_unix_time())
	connect('died', self, '_on_Self_died')
	nametag.text = 'Timmy'


func _physics_process(delta: float) -> void:
	if is_on_floor():
		_velocity.y = 0
	else:
		_velocity.y -= gravity_force * delta
	
	move_and_slide(_velocity)


func _on_Self_died(_self) -> void:
	var data: Array = [id, randi()] # The random integer is for choosing a killstring for the killfeed.
	Global.send_signal(Global.SignalConstants.TIMMY_DIED, data, Global.Recipient.ALL_MEMBERS)
