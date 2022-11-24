extends Node


const filepath: String = "res://settings.ini"

onready var settings: ConfigFile
var control_map_buttons: Array = []


func _ready() -> void:
	settings = ConfigFile.new()
	
	var error = settings.load(filepath)
	if error != OK:
		Logging.error("'%s' did not load properly: RETURNED %d" % [filepath, error])
	else:
		Logging.debug("'%s' loaded properly." % filepath)


func _exit_tree() -> void:
	var error = settings.save(filepath)
	if error != OK:
		Logging.error("'%s' was unable to save correctly: RETURNED %d" % [filepath, error])
	else:
		Logging.debug("'%s' saved successfully." % filepath)
