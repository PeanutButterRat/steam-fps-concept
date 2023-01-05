class_name MobHitbox extends Area


signal damaged(amount, attacker, critical)
signal healed(amount, healer, critical)

const BASE_MULTIPLIER: float = 1.0

export var _damage_multiplier: float = 1.0
export var _heal_multiplier: float = 1.0


func damage(amount: float, attacker: int) -> void:
	var value: float = amount * _damage_multiplier
	var critical: bool = _damage_multiplier > BASE_MULTIPLIER
	
	emit_signal('damaged', value, attacker, critical)


func heal(amount: float, healer: int) -> void:
	var value: float = amount * _heal_multiplier
	var critical: bool = _heal_multiplier > BASE_MULTIPLIER
	
	emit_signal('healed', value, healer, critical)
