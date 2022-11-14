extends HBoxContainer


export(String) var _label_text = ""
export(String) var _option = ""
export(float) onready var _minimum = 0.0
export(float) onready var _maximum = 100.0
export(float) onready var _slider_step = 0.01
export(float) onready var _box_step = 0.1

onready var _label: Label = $"%Setting"
onready var _slider: HSlider = $"%Slider"
onready var _spin_box: SpinBox = $"%Box"
onready var _value: float

onready var settings: ConfigFile = Global.get("settings")


func _ready() -> void:
	assert(settings, "'settings' is not defined in Global.gd")
	assert(_minimum < _maximum, "Minimum slider value must be less than maximum value.")
	assert(_slider_step > 0, "Slider step value must be greater than 0.")
	assert(_box_step > 0, "SpinBox step value must be greater than 0.")
	
	var value: float = settings.get_value("options", _option, (_maximum - _minimum) / 2)
	if value == null: push_error("Couldn't find option for '%s'." % _option)
	if _option.empty(): _option = '_'.join(_label_text.split(' ')).to_lower()
	if _label_text.empty(): _label_text = "Dummy"
	
	_label.set_text(_label_text)
	
	_slider.set_min(_minimum)
	_slider.set_max(_maximum)
	_slider.set_step(_slider_step)

	_spin_box.set_min(_minimum)
	_spin_box.set_max(_maximum)
	_spin_box.set_step(_box_step)
	_spin_box.set_value(value)  # Also sets the slider's value indirectly (_on_Slider_value_changed).


func _on_Slider_value_changed(value: float) -> void:
	if _spin_box.get_value() != value:  # Reduces the number of ocillating calls between the two signals.
		_spin_box.set_value(value)
		if not _option.empty(): Global.emit_signal("%s_changed" % _option, value) # Update's option in-game.
	
	settings.set_value("options", _option, value)  # Update the ConfigFile.


func _on_Box_value_changed(value: float) -> void:
	if _slider.get_value() != value: _slider.set_value(value)
