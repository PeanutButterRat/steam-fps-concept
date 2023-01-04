extends Node


onready var file: File = File.new()
onready var filepath: String = "res://log.txt"
onready var file_error: int 


func _ready() -> void:
	# Disable logging for release versions.
	if OS.has_feature('standalone') and not OS.has_feature('debug'):
		file = null
	else:
		file_error = file.open(filepath, File.WRITE)
		if file_error != OK:
			error('Could not open log file.')
	
	debug('Game launched.')


# Formulates message as such: [SEVERITY] TIME: MESSAGE
func generate_message(serverity: String, message: String) -> String:
	return '[%s] %s: %s' % [serverity, Time.get_time_string_from_system(), message]


func debug(string: String) -> void:
	var message: String = generate_message(' debug ', string)
	print(message)
	write_to_log(message)


func warn(string: String) -> void:
	var message: String = generate_message('Warning', string)
	push_warning(string)
	write_to_log(message)


func error(string: String) -> void:
	var message: String = generate_message(' ERROR ', string)
	push_error(string)
	write_to_log(message)


# Writes the given string to the log file.
func write_to_log(string: String) -> void:
	if file == null or file_error != OK:
		return
	file.store_string(string + '\n')


func _exit_tree():
	file.close()
