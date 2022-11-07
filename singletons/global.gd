extends Node


# Steam variables.
var IS_OWNED: bool = false
var IS_ONLINE: bool = false
var STEAM_ID: int = 0


func _ready() -> void:
	_initialize_Steam()


func _process(_delta: float) -> void:
	Steam.run_callbacks()


func _initialize_Steam() -> void:
	var INIT: Dictionary = Steam.steamInit()
	print("Did Steam initialize?: " + str(INIT))

	if INIT['status'] != 1:
		print("Failed to initialize Steam. " + str(INIT['verbal']) + " Shutting down...")
		get_tree().quit()

	IS_ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	IS_OWNED = Steam.isSubscribed()
	
	if IS_OWNED == false:
		print("User does not own this game.")
		get_tree().quit()
