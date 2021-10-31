class_name Ledge
extends Area2D

onready var top_position: Vector2 = $Top.global_position.floor()
onready var left_position: Vector2 = $Left.global_position.floor()
onready var right_position: Vector2 = $Right.global_position.floor()
