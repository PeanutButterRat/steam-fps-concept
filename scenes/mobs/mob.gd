class_name Mob extends KinematicBody


const MAX_TYPE_ID: int = 5000

enum Type {
	TIMMY = 1,
	ONLINE_PLAYER = 2
}

const PATHS: Dictionary = {
	Type.TIMMY: 'res://scenes/mobs/timmy/timmy.tscn',
	Type.ONLINE_PLAYER: 'res://scenes/mobs/player_online/player_online.tscn'
}

export var _max_health: float = 100.0

var last_attacker: int = 0
var last_healer: int = 0
var health: float = _max_health
var nickname: String = ''
var id: int = 0


static func create(type: int, mob_id: int) -> Mob:
	var path: String = PATHS.get(type)
	
	if path == null:
		Logging.error('Attempted to instantiate an invalid mob type.')
		return null
	
	var instance: Mob = load(path).instance()
	instance.id = mob_id
	
	return instance


func _ready() -> void:
	seed(OS.get_unix_time())
	connect_hitboxes(self, self)  # DSF search for all mob hitboxes.
	Global.connect('mob_damaged', self ,'_on_Global_mob_damaged')


func connect_hitboxes(root: Mob, current: Node) -> void:
	for child in current.get_children():
		if child is MobHitbox:
			child.connect('damaged', root, '_on_MobHitbox_damaged')
			child.connect('healed', root, '_on_MobHitbox_healed')


func damage(amount: float, attacker: int) -> void:
	health -= amount
	last_attacker = attacker


func _on_MobHitbox_damaged(amount: float, attacker: int, critical: bool) -> void:
	damage(amount, attacker)
	var data: Array = [id, amount, last_attacker, critical]
	Global.send_signal(Global.Signals.MOB_DAMAGED, data)
	
	if health <= 0:
		data[1] = randi()
		data.append(nickname)
		Global.send_signal(Global.Signals.MOB_KILLED, data)


func heal(amount: float, healer: int) -> void:
	health += amount
	last_attacker = healer


func _on_MobHitbox_healed(amount: float, healer: int, critical: bool) -> void:
	heal(amount, healer)
	
	var data: Array = [id, amount, last_healer, critical]
	Global.send_signal(Global.Signals.MOB_HEALED, data)
	var mob_id: int = data[0]
	var mob_transform: Transform = data[1]
	
	if mob_id == id:
		transform = mob_transform


func _on_Global_mob_damaged(data: Array) -> void:
	var mob_id: int = data[0]
	var damage: float = data[1]
	var attacker: int = data[2]
	if mob_id == id:
		damage(damage, attacker)
