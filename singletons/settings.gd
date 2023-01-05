extends Node


# warning-ignore:unused_signal
signal remapped_control(rebound_button)

const FILEPATH: String = 'res://settings.ini'

var _config: ConfigFile  # Saved settings.


func _ready() -> void:
	_config = ConfigFile.new()
	var error = _config.load(FILEPATH)
	
	if error != OK:
		Logging.error("'%s' did not load properly: RETURNED %d" % [FILEPATH, error])
	else:
		Logging.debug("'%s' loaded properly." % FILEPATH)


func _exit_tree() -> void:
	var error = _config.save(FILEPATH)
	
	if error != OK:
		Logging.error("'%s' was unable to save correctly: RETURNED %d" % [FILEPATH, error])
	else:
		Logging.debug("'%s' saved successfully." % FILEPATH)


func save(section: String, key: String, value) -> void:
	_config.set_value(section, key, value)


func retrieve(section: String, key: String, default):
	return _config.get_value(section, key, default)
