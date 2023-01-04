class_name Mob extends KinematicBody


signal entity_damaged(entity)
signal entity_healed(entity)
signal died(entity)

const MOB_GROUP: String = 'Mobs'

export var max_health: float = 100.0

var health: float = max_health
var parts: Array = []


static func get_mob_from_part(part: MobHitbox) -> Mob:
	var mobs: Array = part.get_tree().get_nodes_in_group(MOB_GROUP)
	
	for mob in mobs:
		if part in mob.parts:
			return mob
	
	return null


func _ready() -> void:
	add_to_group(MOB_GROUP)
	for child in get_children():
		if child is MobHitbox:
			child.connect('damaged', self, 'damage')
			parts.append(child)


func damage(amount: float) -> void:
	health -= amount
	emit_signal('entity_damaged', self)


func heal(amount: float) -> void:
	health += amount
	emit_signal('entity_healed', self)


func is_dead() -> bool:
	return health <= 0


func kill() -> void:
	emit_signal('died', self)
