extends HBoxContainer


export(String) var _label_text = ""
export(String) var _spin_box_suffix = ""
export(float) var _minimum = 0.0
export(float) var _maximum = 100.0
export(float) var _default_value = (_maximum - _minimum) / 2
export(float) var _step_value = 0.1
export(int) var _separation = 0
export(int) var _tick_count = 0
export(bool) var _box_enabled = true
onready var _label: Label = $"%Setting"
onready var _slider: HSlider = $"%Slider"
onready var _spin_box: SpinBox = $"%Box"
var _value: float


func _ready() -> void:
	if not _label_text:
		self.remove_child(_label)
	else:
		_label.set_text(_label_text)
	
	if not _box_enabled:
		self.remove_child(_spin_box)
	else:
		_spin_box.set_suffix(_spin_box_suffix)
		_spin_box.set_min(_minimum)
		_spin_box.set_max(_maximum)
		_spin_box.set_step(_step_value)
		_spin_box.set_value(_default_value)
		var _error = _spin_box.connect("value_changed", self, "_on_Box_value_changed")

	_slider.set_min(_minimum)
	_slider.set_max(_maximum)
	_slider.set_step(_step_value)
	_slider.set_ticks(_tick_count)
	_slider.set_value(_default_value)
	self.add_constant_override('separation', _separation)


func _on_Slider_value_changed(value: float) -> void:
	if _spin_box.get_value() != value: _spin_box.set_value(value)


func _on_Box_value_changed(value: float) -> void:
	if _slider.get_value() != value:
		_slider.set_value(value)


func get_value() -> float:
	return _slider.get_value()

