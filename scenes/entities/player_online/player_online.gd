extends KinematicBody


const MAX_HEALTH: float = 100.0

onready var nametag: Label3D = $'%Nametag'
onready var steam_id: int
onready var weapon: Spatial = $'%Rifle'


var health: float = MAX_HEALTH


func _ready() -> void:
	Global.connect('event_occurred', self, '_on_Global_event_occurred')


func set_nametag(string: String) -> void:
	nametag.text = string


func _on_Global_event_occurred(event: int, packet: Dictionary) -> void:
	var player: int = packet[Global.PACKET_SENDER_KEY]
	if player != steam_id:
		return
	
	if event == Global.Events.PLAYER_MOVED:
		var update: Transform = packet[Global.EVENT_DATA][0]
		transform = update
	elif event == Global.Events.WEAPON_FIRED:
		weapon.shoot()
	elif event == Global.Events.WEAPON_RELOADED:
		weapon.reload()


func damage(damage: float) -> bool:
	health -= damage
	var killed: bool = false
	
	if health <= 0:
		Global.emit_event(Global.Events.PLAYER_DIED, [steam_id], Global.Recipient.ALL_MEMBERS)
		killed = true
	else:
		Global.emit_event(Global.Events.PLAYER_DAMAGED, [health], Global.Recipient.ALL_MEMBERS)
	
	return killed


func kill() -> void:
	Global.emit_event(Global.Events.PLAYER_DIED, [steam_id], Global.Recipient.ALL_MEMBERS)
