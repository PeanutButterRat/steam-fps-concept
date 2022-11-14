extends Panel


onready var _kick_button: Button = $"%KickButton"
onready var _label: Label = $"%PlayerName"
onready var _profile_button: Button = $"%ViewProfile"
onready var _kick_confirmation: Button = $"%KickConfirmation"
onready var _steam_id: int


func initialize(name: String, steam_id: int) -> void:
	_label.set_text(name)
	_steam_id = steam_id
	
	if steam_id != GlobalSteam.STEAM_ID:
		_kick_confirmation.set_text("Kick player %s?" % name)
		_kick_button.show()


func _on_KickButton_pressed() -> void:
	_kick_confirmation.show()


func _on_KickConfirmation_pressed() -> void:
	print("Kicked player")


func _on_ViewProfile_pressed() -> void:
	Steam.activateGameOverlayToUser("steamid", _steam_id)
