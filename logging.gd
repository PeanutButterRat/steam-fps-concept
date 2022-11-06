extends Node


onready var file: File = File.new()
onready var filepath: String = "res://log.txt"


func _ready() -> void:
	file.open(filepath, File.READ_WRITE)
	file.seek_end(-1)


func debug(message: String) -> void:
	file.store_string('[debug] %s: %s' % [Time.get_time_string_from_system(), message])


func warn(message: String) -> void:
	file.store_string('[Warning] %s: %s' % [Time.get_time_string_from_system(), message])


func error(message: String) -> void:
	file.store_string('[ERROR] %s: %s' % [Time.get_time_string_from_system(), message])


func _exit_tree():
	file.close()
