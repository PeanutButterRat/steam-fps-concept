extends Button


signal remapped_control(button, event)  # Emits to button_remap_container.

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

var event: InputEvent setget set_event
var _input_check: FuncRef
var action: String


func initialize(input_check: FuncRef, new_event: InputEvent, new_action: String) -> void:
	connect('remapped_control', Settings, "_on_Button_remapped_control")
	set_process_unhandled_input(true)
	self._input_check = input_check
	self.action = new_action
	self.event = new_event
	toggle_mode = true
	text = convert_input_event_to_text(self.event)


func _unhandled_input(event: InputEvent) -> void:
	if not pressed: return
	
	var input_registered: bool = false

	if event.is_action_pressed("ui_cancel"):  # Cancel the re-map.
		input_registered = true
	
	elif event.is_action_pressed("delete"):  # Delete the binding.
		input_registered = true
		emit_signal("remapped_control", self, null)
	
	elif _input_check.call_func(event):  # Normal rebind.
		input_registered = true
		emit_signal("remapped_control", self, event)
	
	# Unfocus the button.
	if input_registered:
		pressed = false
		release_focus()
		get_tree().set_input_as_handled()


func _pressed() -> void:
	text = "Waiting for input..."


func _toggled(button_pressed: bool) -> void:
	if button_pressed: text = "Waiting for input..."
	else: text = convert_input_event_to_text(self.event)


func set_event(new_event: InputEvent) -> void:
	event = new_event
	text = convert_input_event_to_text(self.event)


func convert_input_event_to_text(input_event: InputEvent) -> String:
	if input_event is InputEventJoypadButton:
		return 'Joypad Button'
	elif input_event is InputEventKey:
		return input_event.as_text()
	elif input_event is InputEventMouseButton:
		return MOUSE_BUTTON_STRINGS.get(input_event.get_button_index(), "Unknown Assignment")
	elif input_event == null:
		return 'Unassigned'
	else:
		return 'Error'
