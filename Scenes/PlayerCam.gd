extends Camera2D

#export(NodePath) onready var player = get_node(player)

#var game_size: Vector2 = Vector2(960,538)
#onready var window_scale: float = (OS.window_size / game_size).x
#onready var actual_cam_pos: Vector2 = global_position

const TRANS = Tween.TRANS_SINE
const EASE = Tween.EASE_IN_OUT

onready var duration: Timer = $Duration
onready var frequency: Timer = $Frequency
onready var tween: Tween = $Tween

var amplitude: float = 0.0
var priority: int = 0

#func _process(delta: float) -> void:
#	var mouse_pos = G.viewport.get_mouse_position() / window_scale - (game_size/4) + player.global_position
#	var cam_pos = lerp(player.global_position, mouse_pos, 0.7)
#	actual_cam_pos = lerp(actual_cam_pos, cam_pos, delta*5)
#	var subpixel_positon = actual_cam_pos.round() - actual_cam_pos
#	G.viewport_container.material.set_shader_param("cam_offset", subpixel_positon)
#	global_position = actual_cam_pos.round()



func add_shake(dur: float = 0.2, freq: float = 15.0, amp: float = 16.0, prio: int = 0) -> void:
	if prio >= priority:
		amplitude = amp
		
		duration.wait_time = dur
		frequency.wait_time = 1/freq
		
		duration.start()
		frequency.start()
		shake()

func shake() -> void:
	var rand = Vector2.ZERO
	rand.x = rand_range(-amplitude, amplitude)
	rand.y = rand_range(-amplitude, amplitude)
	
	# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "offset", offset, rand, frequency.wait_time, TRANS, EASE)
	# warning-ignore:return_value_discarded
	tween.start()

func reset() -> void:
	# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "offset", offset, Vector2.ZERO, frequency.wait_time, TRANS, EASE)
	# warning-ignore:return_value_discarded
	tween.start()
	
func _on_Frequency_timeout():
	shake()

func _on_Duration_timeout():
	reset()
	frequency.stop()
