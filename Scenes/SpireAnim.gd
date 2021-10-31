extends AnimatedSprite

onready var player: Player = get_parent().get_parent()

func _ready() -> void:
	pass
	
func _process(_delta: float) -> void:
	offset = Vector2.ZERO
	speed_scale = 2.0 if abs(player.velocity.x) > player.move_speed else 1.0
	match player.state:
		player.IDLE:
			play("Idle")
		player.MOVE:
			play("Run")
		player.CROUCH:
			play("Crouch")
		player.CRAWL:
			play("Crawl")
		player.SLIDE:
			play("Slide")
		player.POWERSLIDE:
			play("Slide")
		player.JUMP:
			play("Jump")
		player.SPINJUMP:
			if animation != "Jump_Spinning":
				play("Jump_Intro_Spin")
				yield(self, "animation_finished")
			play("Jump_Spinning")
		player.FALL:
			if animation == "Jump_Spinning":
				play("Jump_Spinning")
			else:
				play("Fall")
		player.LAND:
			play("Land")
		player.GROUNDSLAM:
			if animation == "Groundslam" and frame >= 4:
				if frame == 4:
					player.camera.add_shake(0.2, 25, 20)
				if Input.is_action_pressed("up") or Input.is_action_pressed("jump"):
					stop()
					emit_signal("animation_finished")
			play("Groundslam")
		player.LEDGE:
			play("Ledge")
		player.LEDGECLIMB:
#			speed_scale = 2
			play("LedgeClimb")
#			yield(self, "animation_finished")
#			play("Idle")
		player.WALLSLIDE:
			play("Wallslide")
