class_name Weapon extends Spatial


signal swapped
signal ammo_changed(current_ammo, magazine_capacity, reserve_capacity)
signal attacked
signal reloaded


const SWAP_ANIMATION_NAME: String = 'swap'
const MIN_ATTACKS_PER_SECOND: float = 0.001
const MAX_ATTACKS_PER_SECOND: float = 20.0
const INFINITE_AMMO_ID: int = -1

export var _damage: float = 25.0
export var _enabled: bool = true
export var _magazine_capacity: int = 30
export var _reserve_capacity: int = INFINITE_AMMO_ID
var _current_ammo: int


func attack() -> void:
	pass


func reload() -> void:
	pass


func aim() -> void:
	pass

