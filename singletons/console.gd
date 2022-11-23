extends Node


enum ITEM {
	DUMMY,
}


const TYPES: Dictionary = {
	TYPE_NIL: 'Null',
	TYPE_BOOL: 'Bool',
	TYPE_INT: 'Int',
	TYPE_REAL: 'Float',
	TYPE_STRING: 'String',
	TYPE_VECTOR2: 'Vector2',
	TYPE_RECT2: 'Rect2',
	TYPE_VECTOR3: 'Vector3',
	TYPE_TRANSFORM2D: 'Transform2D',
	TYPE_PLANE: 'Plane',
	TYPE_QUAT: 'Quat',
	TYPE_AABB: 'AABB',
	TYPE_BASIS: 'Basis',
	TYPE_TRANSFORM: 'Transform',
	TYPE_COLOR: 'Color',
	TYPE_NODE_PATH: 'NodePath',
	TYPE_RID: 'RID',
	TYPE_OBJECT: 'Object',
	TYPE_DICTIONARY: 'Dictionary',
	TYPE_ARRAY: 'Array',
	TYPE_RAW_ARRAY: 'PoolByteArray',
	TYPE_INT_ARRAY: 'PoolIntArray',
	TYPE_REAL_ARRAY: 'PoolRealArray',
	TYPE_STRING_ARRAY: 'PoolStringArray',
	TYPE_VECTOR2_ARRAY: 'PoolVector2Array',
	TYPE_VECTOR3_ARRAY: 'PoolVector3Array',
	TYPE_COLOR_ARRAY: 'PoolColorArray',
	TYPE_MAX: 'Size',
}

const COMMAND_SUCCESS: String = 'Command was successfully executed.'
const COMMAND_TYPE_ERROR: String = 'Improper type for one of the arguments.'
const COMMAND_COUNT_ERROR: String = 'Improper number of supplied arguments.'

onready var commands: Dictionary = {}
onready var default: FuncRef = funcref(self, '_default')


func execute(command: String, arguments: Array) -> String:
	Logging.debug('Command entered: [%s], arguments: %s.' % [command, arguments])
	
	var function: FuncRef = commands.get(command, default)
	
	return function.call_func(arguments)  # Return a string denoting success.


func register(command: String, reference: FuncRef) -> void:
	if command in commands:
		Logging.warn(
			"Overwriting '%s' with '%s' for command '%s'. (Console.gd)" %
			[commands[command].function, reference.function, command]
		)
	
	commands[command] = reference


func deregister(command: String) -> void:
	if not command in commands:
		Logging.warn("Attempted to deregister nonexistent command '%s'. (Console.gd)" % command)
		return
	
	commands.erase(command)


func _default(_args: Array) -> String:
	return "Command not found."
