extends KinematicBody


onready var nametag: Label3D = $'%Nametag'
onready var steam_id: int
onready var weapon: Spatial = $'%Rifle'


func _ready() -> void:
	Global.connect('event_occurred', self, '_on_Global_event_occurred')
	add_to_group(Global.GROUPS.OnlinePlayers)


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
