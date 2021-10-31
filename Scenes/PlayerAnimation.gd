extends AnimationTree

onready var player: Player = get_parent()


func _ready() -> void:
	active = true

func _process(_delta: float) -> void:
	match player.state:
		player.IDLE:
			state.travel("Idle")
		player.MOVE:
			state.travel("Run")
		player.JUMP:
			state.travel("Jump_Mid")
		player.FALL:
			state.travel("Fall")
		player.CROUCH:
			state.travel("Crouch")
		player.CRAWL:
			state.travel("Crawl")
		player.LEDGE:
			state.travel("LedgeGrab")
		player.LEDGECLIMB:
			state.travel("LedgeClimb")
