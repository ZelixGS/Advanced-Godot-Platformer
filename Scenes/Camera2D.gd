extends Camera2D

var _min := 0.5
var _max := 8
var _factor := 1
var _duration := 0.2

var _zoom_level := 1.0 setget _set_zoom_level
onready var tween: Tween = $Tween

func _set_zoom_level(value: float) -> void:
	_zoom_level = clamp(value, _min, _max)
	# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "zoom", zoom, Vector2(_zoom_level, _zoom_level), _duration, Tween.TRANS_SINE, Tween.EASE_OUT)
	# warning-ignore:return_value_discarded
	tween.start()

func _input(event) -> void:
	if event.is_action_pressed("mouse_wheel_up"):
		_set_zoom_level(_zoom_level - _factor)
	if event.is_action_pressed("mouse_wheel_down"):
		_set_zoom_level(_zoom_level + _factor)
