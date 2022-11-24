extends HBoxContainer


export(String) onready var _action: String

onready var control_map_buttons: Array = Keybinds.get('control_map_buttons')
onready var settings: ConfigFile = Keybinds.get('settings')

onready var _buttons: Array = []
onready var _bindings: Array

var _waiting_input: bool = false  # Tracks if the user is setting a new key bind.


func _ready() -> void:
	if _action.empty():  # Attempt to infer action from label if present and format it.
		for child in self.get_children():
			if child is Label:
				_action = child.get_text().to_lower().split(' ').join('_')  # Ex: move_forward.
				break
		
		if not _action:  # Attempt to infer action from node name instead.
			_action = name.to_lower().split(' ').join('_')  # Ex: move_forward.
	
	if control_map_buttons == null:
		Logging.warn("'control_map_buttons' is not defined in global.gd, no protection against keybind collisions.")
		control_map_buttons = []
	_bindings = settings.get_value("controls", _action, [])
	if _bindings == null: 
		Logging.warn("Couldn't find control bindings for '%s'." % _action)
	
	# Clear out the input map for each action and build it back up from the init file.
	if not InputMap.get_actions().has(_action): InputMap.add_action(_action)
	
	InputMap.action_erase_events(_action)
	
	for child in self.get_children():
		if child is Button: _buttons.append(child)
	
	for index in len(_buttons):
		var button: Button = _buttons[index]
		var event: InputEvent = _bindings[index] if index < len(_bindings) else null
		
		if event: InputMap.action_add_event(_action, event)  # Add the saved binding to the InputMap.
		
		# Initialize the button.
		button.connect("remapped_control", self, "_on_Button_remapped_control")
		button.set_event(event)
		button.update_text()

		control_map_buttons.append(button)  # Add button to global scope to prevent conflicting bindings.
		

func _on_Button_remapped_control(button: Button, event: InputEvent) -> void:
	# Erase the previously bound event if there is one.
	if button.get_event(): InputMap.action_erase_event(_action, button.get_event())
	
	# Add new mapping to InputMap as long as it isn't null.
	if event: InputMap.action_add_event(_action, event)
	
	# Update the button.
	button.set_event(event)
	button.update_text()
	
	# Check for collisions (same binding to multiple acitons) if the action was not unbound (event would be null).
	if event: check_for_collisions(button)
	
	settings.set_value("controls", _action, InputMap.get_action_list(_action))  # Update the ConfigFile.
	

func check_for_collisions(button):
	for element in control_map_buttons:
		if element.get_instance_id() == button.get_instance_id(): continue
		if element.get_text() == button.get_text():
			element.emit_signal("remapped_control", element, null)  # Unbind the previously bound control.
