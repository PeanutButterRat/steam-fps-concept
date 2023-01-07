extends Popup


signal respawned


var previous_mouse_mode: int


func _on_DeathConfirmation_about_to_show() -> void:
	previous_mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_DeathConfirmation_popup_hide() -> void:
	Input.set_mouse_mode(previous_mouse_mode)


func _on_Respawn_pressed() -> void:
	emit_signal('respawned')
	hide()


func _on_Lobby_pressed() -> void:
	if Global.STEAM_ID == Global.lobby_owner:
		Global.send_signal(Global.Signals.GAME_ENDED, [])
		hide()
