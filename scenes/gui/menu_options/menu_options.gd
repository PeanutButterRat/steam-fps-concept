extends Control


onready var popup_panel: PopupPanel = $'%PopupPanel'


func _ready() -> void:
	open()


func open() -> void:
	popup_panel.popup_centered()
