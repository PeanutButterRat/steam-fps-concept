extends Panel


const MAX_LINE_COUNT: int = 10
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
	Global.connect('mob_killed', self, '_on_Global_mob_killed')


func _on_Global_mob_killed(data: Array) -> void:
	var victim: String = Steam.getFriendPersonaName(data[0])
	var killstring_id: int = data[1] % len(KILLSTRINGS)
	var attacker: String = Steam.getFriendPersonaName(data[2])
	
	if attacker.empty():
		attacker = 'God'
	
	if victim.empty():
		victim = data[3]
	
	add_entry(attacker, victim, KILLSTRINGS[killstring_id])


func add_entry(attacker: String, victim: String, killstring: String) -> void:
	text.add_text('%s %s %s.\n' % [attacker, killstring, victim])
	if text.get_line_count() > MAX_LINE_COUNT:
		text.remove_line(0)
