extends CanvasLayer

onready var debug_text: Label = $Control/Label

onready var player: Player = get_tree().get_nodes_in_group("Player").front()

func _process(_delta: float):
#	if player.state != player.previous_state:
#		print(state_to_string(player.state))
	debug_text.text = str("FPS: %s" % [Engine.get_frames_per_second()])
	debug_text.text += str("\nInput: %s" % [G.poll_input()])
	debug_text.text += str("\nPosition: %.1f/%.1f" % [player.position.x, player.position.y])
	debug_text.text += str("\nVelocity: %.1f/%s, %.1f" % [abs(player.velocity.x),player.get_max_speed(),player.velocity.y])
	debug_text.text += str("\nCeiling: %s" % [player.detect_ceiling()])
	debug_text.text += str("\nWall: %s" % [player.is_on_wall()])
	debug_text.text += str("\nFloor: %s" % [player.is_on_floor()])
	debug_text.text += str("\nAcceleration: %s" % [player.get_acceleration()])
	debug_text.text += str("\nFriction: %s" % [player.get_friction()])
	debug_text.text += str("\nState: %s" % [state_to_string(player.state)])
	debug_text.text += str("\nLast State: %s" % [state_to_string(player.previous_state)])
	debug_text.text += str("\nPower Slide Time: %s" % [player.powerslide_timer.time_left])
	debug_text.text += str("\nJump Buffer Time: %s" % [player.jump_buffer_timer.time_left])
	pass

func state_to_string(value: int) -> String:
	var temp: String = "N/A"
	match value:
		player.IDLE:
			temp = "Idle"
		player.MOVE:
			temp = "Moving"
		player.JUMP:
			temp = "Jumping"
		player.FALL:
			temp = "Falling"
		player.CROUCH:
			temp = "Crouching"
		player.CRAWL:
			temp = "Crawling"
		player.SLIDE:
			temp = "Sliding"
		player.CLIMB:
			temp = "Climbing"
		player.WALLSLIDE:
			temp = "Wallsliding"
		player.LEDGE:
			temp = "Ledge"
		player.LEDGECLIMB:
			temp = "Climbing"
		player.POWERSLIDE:
			temp = "Powersliding"
		player.LAND:
			temp = "Landing"
		player.GROUNDSLAM:
			temp = "POWER SLAM!!"
		player.SPINJUMP:
			temp = "Spinning Jump"
	return(temp)

#func wall_type() -> String:
#	var temp: String = "N/A"
#	match player.detect_wall():
#		player.NULL:
#			temp = "NULL"
#		player.WALL:
#			temp = "Wall"
#		player.CAN_CLAMBER:
#			temp = "Clamber"
#		player.CAN_CRAWL:
#			temp = "Crawl"
#		player.CAN_CLAMBER_CRAWL:
#			temp = "Clamber and Crawl"
#	return temp
