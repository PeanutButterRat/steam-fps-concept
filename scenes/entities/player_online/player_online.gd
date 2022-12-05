extends KinematicBody


onready var nametag: Label3D = $'%Nametag'
onready var steam_id: int


func set_nametag(string: String) -> void:
	nametag.text = string


func set_steam_id(id: int) -> void:
	steam_id = id
