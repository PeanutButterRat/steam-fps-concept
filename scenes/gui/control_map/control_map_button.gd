extends Button


signal remapped_control(button, event)  # Emits to ControlMapContainer.

enum Type {KEYBOARD, CONTROLLER}

const RIGHT_CLICK = 2
const MOUSE_BUTTON_STRINGS = {
	1: "Left Click (Mouse 1)",
	2: "Right Click (Mouse 2)",
	3: "Middle Mouse Button (Mouse 3)",
	8: "Lower Thumb Button (Mouse 5)",
	9: "Upper Thumb Button (Mouse 4)",
	4: "Scroll Wheel Up",
	5: "Scroll Wheel Down",
	6: "Scroll Wheel Left",
	7: "Scroll Wheel Right",
	128: "BUTTON_MASK_XBUTTON1",
	256: "BUTTON_MASK_XBUTTON2"
}

export(Type) onready var _type
onready var _event: InputEvent setget set_event, get_event
var _waiting_input: bool = false  # Tracks if the user is setting a new key bind.


func _input(event: InputEvent) -> void:
	if not _waiting_input: return
	
	var input_registered: bool = false  # Tracks if an input was registered to rebind an action or cancel it.

	# Cancel the re-map.
	if event.is_action_pressed("ui_cancel"):
		input_registered = true
		update_text()
	
	# Delete the binding.
	elif event.is_action_pressed("delete"):
		input_registered = true
		self.emit_signal("remapped_control", self, null)
	
	# Re-mapping keyboard input.
	elif _type == Type.KEYBOARD and (event is InputEventJoypadButton):
		input_registered = true
		self.emit_signal("remapped_control", self, event)
	
	# Re-mapping controller input.
	elif _type == Type.KEYBOARD and (event is InputEventKey or event is InputEventMouseButton):
		input_registered = true
		self.emit_signal("remapped_control", self, event)
	
	# Improper input for mapping type, cancel the input.
	elif _type == Type.CONTROLLER and (event is InputEventKey or event is InputEventMouseButton):
		input_registered = true
		update_text()
	
	# User clicked on a different button while rebinding a control, cancel the first rebind.
	elif event is InputEventMouseButton and not self.has_focus(): 
		input_registered = true
		update_text()
	
	elif _type is InputEventMouseButton:
		input_registered = true
		update_text()
		
	# Unfocus the button.
	if input_registered:
		_waiting_input = false
		self.set_pressed(false)
		self.get_tree().set_input_as_handled()


func update_text() -> void:
	# Updates the text on the button to reflect the input binding for the action.
	if _event is InputEventJoypadButton:
		self.set_text("Joypad Button")
	elif _event is InputEventKey:
		self.set_text(_event.as_text())
	elif _event is InputEventMouseButton:
		self.set_text(MOUSE_BUTTON_STRINGS.get(_event.get_button_index(), "Unknown Assignment"))
	elif _event == null:
		self.set_text("Unassigned")
	else:
		assert(false, "Unexpected event parsed in ControlMapper.")


func _on_Self_pressed() -> void:
	self.set_pressed(true)
	self.set_text("Waiting for input...")
	_waiting_input = true


func set_event(event: InputEvent) -> void:
	_event = event


func get_event() -> InputEvent:
	return _event

