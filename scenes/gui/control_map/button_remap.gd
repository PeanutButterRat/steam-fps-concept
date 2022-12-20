extends Button


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
	Settings.connect('remapped_control', self, "_on_Button_remapped_control")
	set_process_input(true)
	self._input_check = input_check
	self.action = new_action
	self.event = new_event
	toggle_mode = true
	text = convert_InputEvent_to_text(self.event)


func _input(current_event: InputEvent) -> void:

	if not pressed: 
		return
	print('Type check: ', str(_input_check.call_func(current_event)))
	var input_registered: bool = false

	if current_event.is_action_pressed("ui_cancel"):  # Cancel the re-map.
		input_registered = true
	
	elif current_event.is_action_pressed("delete"):  # Delete the binding.
		input_registered = true
		InputMap.action_erase_event(self.action, self.event)
		set_event(null)
	
	elif _input_check.call_func(current_event):  # Normal rebind.
		print('Found a rebind')
		input_registered = true
		if self.event != null:
			InputMap.action_erase_event(self.action, self.event)
		
		InputMap.action_add_event(self.action, current_event)
		
		set_event(current_event)
		Settings.emit_signal("remapped_control", self)
	
	if input_registered:  # Unfocus the button.
		pressed = false
		release_focus()
		get_tree().set_input_as_handled()


func _toggled(button_pressed: bool) -> void:
	if button_pressed:
		text = "Waiting for input..."
	else:
		text = convert_InputEvent_to_text(self.event)


func set_event(new_event: InputEvent) -> void:
	if self.event != null:
		InputMap.action_erase_event(self.action, self.event)
	
	if new_event != null:
		InputMap.action_add_event(self.action, new_event)
	
	event = new_event
	text = convert_InputEvent_to_text(self.event)


func convert_InputEvent_to_text(input_event: InputEvent) -> String:
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


func _on_Button_remapped_control(button) -> void:
	if button.get_instance_id() == self.get_instance_id():
		return
	
	if convert_InputEvent_to_text(button.event) == convert_InputEvent_to_text(self.event):
		set_event(null)
