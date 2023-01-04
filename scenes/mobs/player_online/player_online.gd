extends Mob


onready var weapon: Weapon
onready var nametag: Label3D = $'%Nametag'

var steam_id: int


func _ready() -> void:
	seed(OS.get_unix_time())
	Global.connect('player_moved', self, '_on_Global_player_moved')
	Global.connect('weapon_fired', self, '_on_Global_weapon_fired')
	Global.connect('weapon_reloaded', self, '_on_Global_weapon_reloaded')


func set_nametag(string: String) -> void:
	nametag.text = string


func _on_Global_player_moved(data: Array, sender: int) -> void:
	var new_transform: Transform = data[1]
	if sender == steam_id:
		transform = new_transform


func _on_Global_weapon_attacked(_data: Array, sender: int) -> void:
	if sender == steam_id:
		weapon.attack()


func _on_Global_weapon_reloaded(_data: Array, sender: int) -> void:
	if sender == steam_id:
		weapon.reload()


func kill() -> void:
	var data: Array = [steam_id, randi()] # The random integer is for choosing a killstring for the killfeed.
	Global.send_signal(Global.SignalConstants.PLAYER_DIED, data, Global.Recipient.ALL_MEMBERS)