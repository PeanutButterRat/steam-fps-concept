extends PopupPanel


var previous_mouse_mode: int


func _unhandled_key_input(event: InputEventKey) -> void:
	if event.is_action_pressed('ui_cancel'):
		popup_centered()
		get_tree().set_input_as_handled()


func _on_PopupPanel_about_to_show() -> void:
	previous_mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_PopupPanel_popup_hide() -> void:
	Input.set_mouse_mode(previous_mouse_mode)
