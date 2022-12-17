extends KinematicBody


onready var nametag: Label3D = $'%Nametag'
onready var steam_id: int
onready var rifle: Spatial = $'%Rifle'


func _ready() -> void:
	Global.connect('event_occurred', self, '_on_Global_event_occurred')
	add_to_group(Global.GROUPS.OnlinePlayers)


func set_nametag(string: String) -> void:
	nametag.text = string


func _on_Global_event_occurred(event: int, packet: Dictionary) -> void:
	var player: int = packet[Global.PACKET_SENDER_KEY]
	if player != Global.STEAM_ID:
		return
	
	if event == Global.Events.PLAYER_MOVED:
		var position: Vector3 = packet[Global.EVENT_DATA][0]
		translation = position
	elif event == Global.Events.WEAPON_FIRED:
		rifle.shoot()
	elif event == Global.Events.WEAPON_RELOADED:
		rifle.reload()
