extends Control


onready var hitmarker: Hitmarker = $"%Hitmarker"
onready var ammo_label: Label = $"%AmmoCount"


func play_hitmarker(hitmarker_name: String) -> void:
	hitmarker.play(hitmarker_name)


func set_ammo_count(current_ammo: int, magazine_capacity: int, reserve_capacity: int) -> void:
	ammo_label.text = str(current_ammo) + ' / ' + str(magazine_capacity) + ' R: ' + str(reserve_capacity)


func set_ammo_icon() -> void:
	pass
