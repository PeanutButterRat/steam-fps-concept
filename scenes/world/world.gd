extends Spatial



const NO_PLAYER_FOUND: int = 0

onready var spawn: Spatial = $'%Spawn'
onready var death_confirmation: Popup = $'%DeathConfirmation'
var command_spawn: FuncRef = funcref(self, '_on_Command_spawn')
var command_teleport_player: FuncRef = funcref(self, '_on_Command_teleport_player')
var command_op_player: FuncRef = funcref(self, '_on_Command_op_player')
var command_kill_player: FuncRef = funcref(self, '_on_Command_kill')

var mobs: Dictionary = {}
var local_player: Mob


func _ready() -> void:
	Global.connect('player_list_changed', self, '_on_Global_player_list_changed')
	Global.connect('mob_spawned', self, '_on_Global_mob_spawned')
	Global.connect('mob_killed', self, '_on_Global_mob_killed')
	
	Console.register('spawn', command_spawn)
	Console.register('tp', command_teleport_player)
	Console.register('op', command_op_player)
	Console.register('kill', command_kill_player)
	

	var data: Array = [Mob.Type.ONLINE_PLAYER, Global.STEAM_ID, spawn.translation]
	Global.send_signal(Global.Signals.MOB_SPAWNED, data)


func spawn_mob(type: int, mob_id: int, mob_translation: Vector3) -> Mob:
	var mob: Mob = Mob.create(type, mob_id)
	mob.translation = mob_translation
	mobs[mob_id] = mob
	add_child(mob)
	return mob



func remove_mob(id: int) -> void:
	if not id in mobs:
		return
	
	var mob: Mob = mobs[id]
	remove_child(mob)
	mobs.erase(id)
	mob.queue_free()


func _on_Command_spawn(arguments: Array) -> String:
	if not len(arguments) == 1:
		return Console.COUNT_ERROR
	
	var mob: String = arguments[0]
	var type: int
	
	match mob.to_lower():
		'timmy':
			type = Mob.Type.TIMMY
		_:
			return 'Invalid mob type.'
	
	var data: Array = [type, Global.generate_unique_id(), local_player.translation]
	Global.send_signal(Global.Signals.MOB_SPAWNED, data)
	return Console.SUCCESS


func _on_Global_mob_spawned(data: Array) -> void:
	var type: int = data[0]
	var mob_id: int = data[1]
	var mob_translation: Vector3 = data[2]
	
	if mob_id == Global.STEAM_ID:
		type = Mob.Type.LOCAL_PLAYER
	
	var mob: Mob = spawn_mob(type, mob_id, mob_translation)
	
	if mob_id == Global.STEAM_ID:
		local_player = mob


func _on_Global_mob_killed(data: Array) -> void:
	var id: int = data[0]
	if id == Global.STEAM_ID:
		death_confirmation.popup()
	
	remove_mob(id)


func _on_Command_teleport_player(args: Array) -> String:
	if len(args) != 1:
		return Console.COUNT_ERROR
	
	if local_player == null:
		return 'Cannot teleport players while dead.'
	
	var username: String = args[0]
	var id: int = get_lobby_member_id_from_name(username)
	
	if id == Global.STEAM_ID:
		return 'You cannot teleport yourself.'
	elif id != NO_PLAYER_FOUND:
		var data: Array = [id, local_player.translation]
		Global.send_signal(Global.Signals.MOB_TELEPORTED, data)
		return Console.SUCCESS
	else:
		return "No player found with the name of '%s.'" % username


func _on_Command_op_player(args: Array) -> String:
	if len(args) != 1:
		return Console.COUNT_ERROR
	
	var username: String = args[0]
	var id: int = get_lobby_member_id_from_name(username)
	
	if id == Global.STEAM_ID:
		return 'You cannot change your own permissions.'
	elif id != NO_PLAYER_FOUND:
		var data: Array = [id]
		Global.send_signal(Global.Signals.PLAYER_CONSOLE_ENABLE, data)
		return Console.SUCCESS
	else:
		return "No player found with the name of '%s.'" % username 


func _on_Global_player_list_changed(players: Array) -> void:
	for mob_id in mobs:
		if mob_id > Global.UNIQUE_ID_MAX and not mob_id in players:
			remove_mob(mob_id)
# [Mob ID, translation]

func _on_Command_kill(args: Array) -> String:
	for username in args:
		var id: int = get_lobby_member_id_from_name(username)
		if id != NO_PLAYER_FOUND:
			var data: Array = [id, randi(), Mob.WORLD_ID]
			Global.send_signal(Global.Signals.MOB_KILLED, data)
		else:
			return "No player by the name of '%s' in the lobby." % [username]
	
	if len(args) == 0:
		var data: Array = [Global.STEAM_ID, randi(), Mob.WORLD_ID]
		Global.send_signal(Global.Signals.MOB_KILLED, data)
	
	return Console.SUCCESS


func _on_DeathConfirmation_respawned() -> void:
	var data: Array = [Mob.Type.ONLINE_PLAYER, Global.STEAM_ID, spawn.translation]
	Global.send_signal(Global.Signals.MOB_SPAWNED, data)


func get_lobby_member_id_from_name(username: String) -> int:
	var members: Dictionary = {}
	
	for id in Global.lobby_members:
		var nickname: String = Steam.getFriendPersonaName(id)
		members[nickname] = id
	
	return members.get(username, NO_PLAYER_FOUND)


