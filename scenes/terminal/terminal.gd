extends Control


const COLOR_ERROR: Color = Color.indianred

onready var line: LineEdit = $'%LineEdit'
onready var animations: AnimationPlayer = $'%AnimationPlayer'
onready var feedback: Label = $'%Feedback'
onready var timer: Timer = $'%FeedbackTimer'
onready var feedback_panel: Panel = $'%FeedbackPanel'


func _ready() -> void:
	feedback.set("custom_colors/font_color", COLOR_ERROR)
	hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed('console'):  # User opens console.
		if visible: close()
		else: open()
		get_tree().set_input_as_handled()
	elif event.is_action_pressed('ui_cancel') and visible:  # User is in console and wants to leave.
		close()


func _on_LineEdit_text_changed(new_text: String) -> void:
	line.text = new_text.lstrip('/')
	line.caret_position = len(line.text)


func _on_LineEdit_text_entered(new_text: String) -> void:
	if new_text.empty():  # Empty commands are thrown out.
		hide()
		return
	
	# Parse command.
	var strings: Array = new_text.split(' ')
	var command: String = strings[0]
	var arguments: Array = strings.slice(1, -1)
	Logging.debug('Command entered: [%s], arguments: %s.' % [command, arguments])
	
	# Execute the command.
	var message: String = Console.execute(command, arguments)
	Logging.debug(message)
	
	# Set up the feedback message.
	feedback.text = message
	
	if message == Console.COMMAND_SUCCESS:
		close()
	# Reset the feedback timer if the message icon is already displayed.
	elif not timer.is_stopped():
		timer.start()
	else:
		animations.play('feedback_show')
	
	line.clear()


func close() -> void:
	Console.focus(false)
	line.release_focus()  # Prevents user from entering in a command while closing prompt.
	animations.play('hide')


func open() -> void:
	Console.focus(true)
	show()
	animations.play('show')


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == 'show':
		line.grab_focus()  # User may start typing.
	elif anim_name == 'hide':
		line.clear()  # Clear the line when hidden from view.
		timer.stop()  # Prevents 'feedback_hide' animation.
		hide()
	elif anim_name == 'feedback_show':
		timer.start()


func _on_FeedbackTimer_timeout() -> void:
	animations.play('feedback_hide')
