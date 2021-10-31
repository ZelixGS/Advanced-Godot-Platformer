extends Node

onready var player: Player = get_tree().get_nodes_in_group("Player").front()

var d_input: Vector2 = Vector2.ZERO

func poll_input() -> Vector2:
	d_input = Vector2.ZERO
	d_input.x = Input.get_action_strength("right") -Input.get_action_strength("left")
	d_input.y = Input.get_action_strength("down") -Input.get_action_strength("up")
	return d_input 
