extends KinematicBody


const MAX_HEALTH: float = 100.0

onready var nametag: Label3D = $'%Nametag'
onready var steam_id: int

var velocity: Vector3 = Vector3.ZERO
var gravity_force: float = 30
var health = MAX_HEALTH


func _ready() -> void:
	Global.connect('event_occurred', self, '_on_Global_event_occurred')
	nametag.text = 'Timmy'
	add_to_group(Global.GROUPS.Timmy)


func set_nametag(string: String) -> void:
	nametag.text = string


func _on_Global_event_occurred(event: int, packet: Dictionary) -> void:
	if event == Global.Events.TIMMY_DAMAGED:
		var player: int = packet[Global.PACKET_SENDER_KEY]
		var id: int = packet[Global.EVENT_DATA][0]
		var damage: float = packet[Global.EVENT_DATA][1]
		
		if id == get_instance_id():
			health -= damage
			if health <= 0 and player == Global.STEAM_ID:  # Only the one who kills Timmy sends the message.
				Global.emit_event(Global.Events.TIMMY_DIED, [get_instance_id()], Global.Recipient.ALL_MEMBERS)


func _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y -= gravity_force * delta
	
	move_and_slide(velocity)

