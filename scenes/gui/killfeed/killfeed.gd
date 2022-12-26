extends Panel


const KILLSTRINGS = [
	'swagged on',
	'absolutely destroyed',
	'killed',
	'blasted',
	'slaughtered',
]


onready var text: RichTextLabel = $"%Text"


func _ready():
	seed(
		
	)

func _on_Global_recieved_kill_notification(event_data: Array) -> void:
	var attacker: String = event_data[0]
	var victim: String = event_data[1]
	var killstring_id: int = event_data[2]
	
	text.add_text('%s %s %s.' % [attacker, KILLSTRINGS[killstring_id], victim])


func send_kill_notification(attacker: String, victim: String) -> void:
	pass
