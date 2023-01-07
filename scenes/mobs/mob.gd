class_name Mob extends KinematicBody


signal died

enum Type {
	TIMMY
	LOCAL_PLAYER
	ONLINE_PLAYER
}

const PATHS: Dictionary = {
	Type.TIMMY: 'res://scenes/mobs/timmy/timmy.tscn',
	Type.LOCAL_PLAYER: 'res://scenes/player_local/player_local.tscn',
	Type.ONLINE_PLAYER: 'res://scenes/mobs/player_online/player_online.tscn'
}

const WORLD_ID: int = 0

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
	connect_hitboxes(self)  # DSF search for all mob hitboxes.
	Global.connect('mob_damaged', self ,'_on_Global_mob_damaged')


func connect_hitboxes(root: Node) -> void:
	for child in root.get_children():
		if child is MobHitbox:
			child.connect('damaged', self, '_on_MobHitbox_damaged')
			child.connect('healed', self, '_on_MobHitbox_healed')
		
		connect_hitboxes(child)


func damage(amount: float, attacker: int) -> void:
	health -= amount
	last_attacker = attacker
	
	if health <= 0:
		var data: Array = [id, randi(), last_attacker, nickname]
		Global.send_signal(Global.Signals.MOB_KILLED, data)


func _on_MobHitbox_damaged(amount: float, attacker: int, critical: bool) -> void:
	last_attacker = attacker
	var data: Array = [id, amount, last_attacker, critical]
	Global.send_signal(Global.Signals.MOB_DAMAGED, data)


func heal(amount: float, healer: int) -> void:
	health += amount
	last_attacker = healer


func _on_MobHitbox_healed(amount: float, healer: int, critical: bool) -> void:
	last_healer = healer
	var data: Array = [id, amount, last_healer, critical]
	Global.send_signal(Global.Signals.MOB_HEALED, data)


func _on_Global_mob_damaged(data: Array) -> void:
	var mob_id: int = data[0]
	var damage: float = data[1]
	var attacker: int = data[2]
	if mob_id == id:
		damage(damage, attacker)
