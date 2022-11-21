extends KinematicBody


onready var nametag: Label3D = $'%Nametag'


func set_nametag(string: String) -> void:
	nametag.text = string
