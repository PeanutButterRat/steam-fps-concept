extends Control


onready var line: LineEdit = $'%LineEdit'


func _ready() -> void:
	hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed('console'):  # User opens console.
		close() if visible else open()
		get_tree().set_input_as_handled()
	elif event.is_action_pressed('ui_cancel') and visible:  # User is in console and wants to leave.
		close()
		get_tree().set_input_as_handled()


func _on_LineEdit_text_changed(new_text: String) -> void:
	line.text = new_text.lstrip('/')
	line.caret_position = len(line.text)


func _on_LineEdit_text_entered(new_text: String) -> void:
	if new_text.empty(): hide()
	
	var strings: Array = new_text.split(' ')
	var command: String = strings[0]
	var arguments: Array = strings.slice(1, -1)
	
	Logging.debug('Command entered: [%s], arguments: %s.' % [command, arguments])
	
	var message: String
	
	message = Console.execute(command, arguments)
	
	Logging.debug(message)
	line.placeholder_text = ' ' + message
	line.clear()


func close() -> void:
	line.clear()
	hide()


func open() -> void:
	line.grab_focus()
	show()
