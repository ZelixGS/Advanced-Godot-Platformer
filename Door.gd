extends StaticBody2D

enum STATE {CLOSED, OPEN}
enum FACE {LEFT, RIGHT}

export(FACE) var face: int = FACE.LEFT
var state: int = STATE.CLOSED

export(Rect2) var closed_sprite: Rect2 = Rect2(0,0,0,0)
export(Rect2) var opened_sprite: Rect2 = Rect2(0,0,0,0)

onready var _collision: CollisionShape2D = $CollisionShape2D
onready var _flip: Node2D = $Flip
onready var _area: Area2D = $Flip/Area2D
onready var _area_collison: CollisionShape2D = $Flip/Area2D/CollisionShape2D
onready var _sprite: Sprite = $Flip/Sprite
onready var _timer: Timer = $Timer

func _ready() -> void:
	_flip.scale.x = 1 if face == FACE.RIGHT else -1
	update_door(STATE.CLOSED)

func update_door(new_state: int) -> void:
	if new_state == STATE.CLOSED:
		state = STATE.CLOSED
		_sprite.region_rect = closed_sprite
		_collision.disabled = false
		_area_collison.disabled = false
	else:
		state = STATE.OPEN
		_sprite.region_rect = opened_sprite
		_collision.disabled = true
		_area_collison.disabled = true

func _on_Area2D_area_entered(area: Area2D) -> void:
	if area is Projectile:
		if area.creator == "Player":
			update_door(STATE.OPEN)
			_timer.start(10.0)

func _on_Timer_timeout():
	update_door(STATE.CLOSED)
