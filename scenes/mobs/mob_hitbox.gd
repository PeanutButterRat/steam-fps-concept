class_name MobHitbox extends Area


signal damaged(amount, attacker)
signal healed(amount)

export var _damage_multiplier: float = 1.0
export var _heal_multiplier: float = 1.0



func damage(amount: float, attacker: String) -> void:
	emit_signal('damaged', amount * _damage_multiplier, attacker)


func heal(amount: float) -> void:
	emit_signal('healed', amount * _heal_multiplier)


func is_critical() -> bool:
	return _damage_multiplier > 1.0  # Crits are registered if multiplier > 1.

