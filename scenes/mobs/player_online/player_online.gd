extends Mob


onready var weapon: Weapon
onready var nametag: Label3D = $'%Nametag'



func _ready() -> void:
	._ready()
	Global.connect('mob_moved', self, '_on_Global_mob_moved')
	set_nametag(Steam.getFriendPersonaName(id))


func set_nametag(string: String) -> void:
	if nametag == null:
		push_error('Attempted to set nametag for online player before it was ready.')
	else:
		nametag.text = string
		nickname = string


func _on_Global_mob_moved(data: Array) -> void:
	var mob_id: int = data[0]
	var mob_transform: Transform = data[1]
	
	if mob_id == id:
		transform = mob_transform
