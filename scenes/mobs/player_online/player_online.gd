extends Mob


onready var weapon: Weapon
onready var nametag: Label3D = $'%Nametag'

var steam_id: int


func _ready() -> void:
	seed(OS.get_unix_time())
	Global.connect('player_moved', self, '_on_Global_player_moved')
	Global.connect('weapon_fired', self, '_on_Global_weapon_fired')
	Global.connect('weapon_reloaded', self, '_on_Global_weapon_reloaded')
	Global.connect('player_damaged', self, '_on_Global_player_damaged')
	connect('damaged', self, '_on_Self_damaged')


func set_nametag(string: String) -> void:
	if nametag == null:
		push_error('Attempted to set nametag for online player before it was ready.')
	else:
		nametag.text = string


func _on_Global_player_moved(data: Array, sender: int) -> void:
	if sender == steam_id:
		var new_transform: Transform = data[0]
		transform = new_transform


func _on_Global_player_damaged(data: Array, sender: int) -> void:
	health -= data[1]


func _on_Self_damaged(_entity: Mob, amount: float, attacker: String) -> void:
	var data: Array = [steam_id, amount]
	Global.send_signal(Global.SignalConstants.PLAYER_DAMAGED, data, Global.Recipient.ALL_MINUS_CLIENT)
