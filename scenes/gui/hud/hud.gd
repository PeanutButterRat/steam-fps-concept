extends Control


onready var hitmarker: Hitmarker = $"%Hitmarker"
onready var ammo_label: Label = $"%AmmoCount"


func _ready() -> void:
	Global.connect('mob_damaged', self, '_on_Global_mob_damaged')
	Global.connect('mob_killed', self, '_on_Global_mob_killed')


func play_hitmarker(hitmarker_name: String) -> void:
	hitmarker.play(hitmarker_name)


func set_ammo_count(current_ammo: int, magazine_capacity: int, reserve_capacity: int) -> void:
	ammo_label.text = str(current_ammo) + ' / ' + str(magazine_capacity) + ' R: ' + str(reserve_capacity)


func set_ammo_icon() -> void:
	pass


func _on_Global_mob_damaged(data: Array) -> void:
	var attacker: int = data[2]
	var critical: bool = data[3]
	
	if attacker == Global.STEAM_ID:
		if critical:
			play_hitmarker(Hitmarker.CRITICAL_ANIMATION_NAME)
		else:
			play_hitmarker(Hitmarker.NORMAL_ANIMATION_NAME)


func _on_Global_mob_killed(data: Array) -> void:
	var attacker: int = data[2]
	if attacker == Global.STEAM_ID:
		play_hitmarker(Hitmarker.KILL_ANIMATION_NAME)
