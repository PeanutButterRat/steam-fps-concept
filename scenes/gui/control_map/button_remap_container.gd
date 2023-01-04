extends HBoxContainer


enum Type {KEYBOARD, CONTROLLER}
export(Type) onready var _type

var button_script: Script = load('res://scenes/gui/control_map/button_remap.gd')
const CONFIG_SECTION: String = 'controls'

export var _action: String = 'default'
onready var _buttons: Array = []
onready var _bindings: Array


var _input_handlers: Dictionary = {
	Type.KEYBOARD: funcref(self, '_is_keyboard_input'),
	Type.CONTROLLER: funcref(self, '_is_controller_input')
}


func _ready() -> void:
	# Initialize the input map according to the settings file.
	if not InputMap.get_actions().has(_action):
		InputMap.add_action(_action)
	
	# Retrieve the saved keybinds.
	_bindings = Settings.retrieve(CONFIG_SECTION, _action, [])
	if _bindings: InputMap.action_erase_events(_action)
	
	# Initialize the label and store references to the buttons.
	for child in self.get_children():
		if child is Button:
			_buttons.append(child)
		elif child is Label:
			child.text = _action.capitalize()
	
	# Initialize the InputEvents for the buttons.
	for index in len(_buttons):
		var button: Button = _buttons[index]
		var event: InputEvent = _bindings[index] if index < len(_bindings) else null
		if event: InputMap.action_add_event(_action, event)
		
		button.set_script(button_script)
		button.initialize(_input_handlers[_type], event, _action)


func _is_keyboard_input(event: InputEvent) -> bool:
	return event is InputEventKey or event is InputEventMouseButton


func _is_controller_input(event: InputEvent) -> bool:
	return event is InputEventJoypadButton


func save() -> void:
	var bindings: Array = []
	
	for child in get_children():
		if child is Button and child.event != null:
			bindings.append(child.event)
	
	Settings.save(CONFIG_SECTION, _action, bindings)

func _exit_tree() -> void:
	save()
