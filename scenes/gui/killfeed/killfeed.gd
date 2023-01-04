extends Panel


const KILLSTRINGS = [
	'swagged on',
	'absolutely destroyed',
	'killed',
	'blasted',
	'slaughtered',
	'defeated',
	'tapped',
	'railed'
]

onready var text: RichTextLabel = $"%Text"


func _ready():
	Global.connect('player_died', self, '_on_Global_player_died')
	Global.connect('timmy_died', self, '_on_Global_timmy_died')


func _on_Global_player_died(data: Array, sender: int) -> void:
	var attacker: String = data[2]
	var victim: String = Steam.getFriendPersonaName(data[0])
	var killstring_id: int = data[1] % len(KILLSTRINGS)
	
	add_entry(attacker, victim, KILLSTRINGS[killstring_id])


func _on_Global_timmy_died(data: Array, sender: int) -> void:
	var attacker: String = Steam.getFriendPersonaName(sender)
	var victim: String = 'Timmy'
	var killstring_id: int = data[1] % len(KILLSTRINGS)
	
	add_entry(attacker, victim, KILLSTRINGS[killstring_id])


func add_entry(attacker: String, victim: String, killstring: String) -> void:
	text.add_text('%s %s %s.\n' % [attacker, killstring, victim])
