extends Node


const FILEPATH: String = 'res://settings.ini'

var _config: ConfigFile  # Saved settings.

var key_mappings = []


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


func _on_Button_remapped_control(rebound_button: Button, new_event: InputEvent) -> void:# Erase the previously bound event if there is one.
	var action: String = rebound_button.action
	var event: InputEvent = rebound_button.event
	
	if event:
		InputMap.action_erase_event(action, event)
		InputMap.action_add_event(action, event)
	
	rebound_button.event = new_event  # Update the button.
	
	for button in key_mappings:
		if button == rebound_button: continue
		if button.get_event_text() == button.get_event_text():
			button.event = null
