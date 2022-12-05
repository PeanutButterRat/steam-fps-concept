extends Tabs


const Mode: Dictionary = {
	'Windowed': 0,
	'Fullscreen': 1
}

const Aspect: Dictionary = {
	'_1920_x_1080': 0,
	'_1440_x_810': 1
}

const CONFIG_SECTION: String = 'display'  # Config file section to save options.
const MODE_KEY: String = 'mode'
const ASPECT_KEY: String = 'aspect'

onready var mode_options: OptionButton = $'%ModeOptions'  # Display mode.
onready var aspect_options: OptionButton = $'%AspectOptions'  # Aspect ratio.


func _ready() -> void:
	var filepath = Global.get('settings')
	if filepath == null: filepath = 'res://settings.ini'
	
	# Set up the mode options button.
	mode_options.connect('item_selected', self, '_on_ModeOptions_item_selected')
	
	for option in Mode:
		mode_options.add_item(option)
	
	var mode: int = Settings.retrieve(CONFIG_SECTION, MODE_KEY, 0)
	mode_options.emit_signal('item_selected', mode)
	mode_options.select(mode)
	
	# Set up the aspect options button.
	aspect_options.connect('item_selected', self, '_on_AspectOptions_item_selected')
	
	for option in Aspect:
		var text: String = option.split('_', false).join(' ')
		aspect_options.add_item(text)
	
	var aspect: int = Settings.retrieve(CONFIG_SECTION, ASPECT_KEY, 0)
	aspect_options.emit_signal('item_selected', aspect)
	aspect_options.select(aspect)


# User changed the display mode.
func _on_ModeOptions_item_selected(index: int) -> void:
	match index:
		Mode.Windowed: OS.set_window_fullscreen(false)
		Mode.Fullscreen: OS.set_window_fullscreen(true)
	
	Settings.save(CONFIG_SECTION, MODE_KEY, index)


# User changed the aspect ratio.
func _on_AspectOptions_item_selected(index: int) -> void:
	match index:
		Aspect._1920_x_1080:
			ProjectSettings.set_setting('Mode/window/size/width', 1920)
			ProjectSettings.set_setting('Mode/window/size/height', 1080)
		Aspect._1440_x_810:
			ProjectSettings.set_setting('Mode/window/size/width', 1440)
			ProjectSettings.set_setting('Mode/window/size/height', 810)
	
	Settings.save(CONFIG_SECTION, ASPECT_KEY, index)
