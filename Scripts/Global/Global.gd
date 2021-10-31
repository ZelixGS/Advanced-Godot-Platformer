extends Node

onready var player: Player = get_tree().get_nodes_in_group("Player").front()

var d_input: Vector2 = Vector2.ZERO

func get_input() -> Vector2:
	d_input = Vector2.ZERO
	d_input = Input.get_vector("left", "right", "up", "down")
	return d_input

func clamp_input(d_pad: Vector2) -> Vector2:
	var output: Vector2 = Vector2.ZERO
	output.x = -1 if d_pad.x < 0 else 1
	output.y = -1 if d_pad.y > 0 else 1
	return output
