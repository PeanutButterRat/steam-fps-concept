extends Node


const COMMAND_SUCCESS: String = 'Command was successfully executed.'
const COMMAND_TYPE_ERROR: String = 'Improper type for one of the arguments.'
const COMMAND_COUNT_ERROR: String = 'Improper number of supplied arguments.'

onready var commands: Dictionary = {}
onready var default: FuncRef = funcref(self, '_default')

var focused: bool = false
var enabled: bool = true


func execute(command: String, arguments: Array) -> String:
	if not enabled:
		return 'You do not have permissions to use the console.'
	
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

