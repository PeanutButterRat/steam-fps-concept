extends Control


onready var hitmarker: Node2D = $"%Hitmarker"
onready var ammo_label: Label = $"%AmmoCount"


func update_ammo_count(current_ammo: int, mag_capacity: int) -> void:
	ammo_label.text = '%d / %d' % [current_ammo, mag_capacity]


func normal_hitmarker() -> void:
	hitmarker.hit()


func critical_hitmarker() -> void:
	hitmarker.crit()


func kill_hitmarker() -> void:
	hitmarker.kill()
