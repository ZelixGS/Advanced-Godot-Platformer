tool
extends KinematicBody2D

export(float) var idle_duration: float = 2.0
export(Vector2) var move_to: Vector2 = Vector2.UP * 160
export(float) var speed: float = 3.0

onready var tween: Tween = $Tween

onready var ghost_sprite: Sprite = $Ghost
onready var ghost_line: Line2D = $Line2D

onready var start_position: Vector2 = global_position

func _ready() -> void:
	ghost_sprite.position = move_to
	ghost_line.points[1] = move_to
	if not Engine.editor_hint:
		ghost_sprite.queue_free()
		ghost_line.queue_free()
		_init_tween()

func _init_tween() -> void:
	var duration = move_to.length() / float(speed * 16)
# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "position", start_position, start_position + move_to, duration, Tween.TRANS_LINEAR, Tween.EASE_IN, idle_duration)
# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "position", start_position + move_to, start_position, duration, Tween.TRANS_LINEAR, Tween.EASE_IN, duration + idle_duration *2)
# warning-ignore:return_value_discarded
	tween.start()

func _on_Area2D_body_entered(_body):
# warning-ignore:return_value_discarded
	tween.stop(self)

func _on_Area2D_body_exited(_body):
# warning-ignore:return_value_discarded
	tween.resume(self)
