extends Mob


onready var weapon: Weapon
onready var nametag: Label3D = $'%Nametag'



func _ready() -> void:
	._ready()


func set_nametag(string: String) -> void:
	if nametag == null:
		push_error('Attempted to set nametag for online player before it was ready.')
	else:
		nametag.text = string
		nickname = string


func _on_Global_mob_damaged(data: Array) -> int:
