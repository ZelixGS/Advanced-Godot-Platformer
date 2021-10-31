class_name Player
extends KinematicBody2D

enum {DEAD, IDLE, MOVE, JUMP, SPINJUMP, FALL, CROUCH, CRAWL, LAND, SLIDE, DIVE, LEDGE, LEDGECLIMB, WALLSLIDE, CLIMB, POWERSLIDE, GROUNDSLAM}
var state: int = FALL setget set_state
var previous_state: int = 1

export(bool) var allow_input: bool = true
export(bool) var can_move: bool = true
export(bool) var use_gravity: bool = true
export(bool) var auto_clamber: bool = true
export(bool) var auto_crawl: bool = true

export(float) var move_speed: float = 240.0
export(float) var acceleration: float = 6.5
export(float) var friction: float = 44
export(float) var jump_buffer: float = 0.2
export(float) var coyate_buffer: float = 0.2
var max_velocity: float = move_speed
var current_max_velocity: float = max_velocity

var was_on_floor: bool = false
var speed: float = 0.0
var last_facing: int = 1
var velocity: Vector2 = Vector2.ZERO
var floor_snap: Vector2
var ledge_snap: bool
var ground_slam: bool
var frictionless_jump: bool

onready var standing: CollisionShape2D = $Standing
onready var crouching: CollisionShape2D = $Crouch

onready var ray_head: RayCast2D = $Facing/Head
onready var ray_ledge: RayCast2D = $Facing/Ledge
onready var ray_torso: RayCast2D = $Facing/Torso
onready var ray_legs: RayCast2D = $Facing/Legs
onready var ray_feet: RayCast2D = $Facing/Feet
onready var ray_below_feet: RayCast2D = $Facing/BelowFeet
onready var ray_other_wall: RayCast2D = $Facing/OtherWall

onready var ray_close_ground: RayCast2D = $Facing/CloseGround
onready var ray_ceiling: RayCast2D = $Crouch/Ceiling
onready var ray_crouch_ceiling: RayCast2D = $Crouch/Ceiling2

onready var facing: Node2D = $Facing

onready var crawl_timer_started: bool = false
onready var auto_clamber_timer: Timer = $Timers/AutoClamberCD
onready var slide_timer: Timer = $Timers/Slide
onready var slide_cd_timer: Timer = $Timers/SlideCD
onready var ledge_timer: Timer = $Timers/Ledge
onready var powerslide_timer: Timer = $Timers/Powerslide
onready var jump_buffer_timer: Timer = $Timers/JumpBuffer
onready var jump_coyate_timer: Timer = $Timers/JumpCoyate

onready var sprite: AnimatedSprite = $Facing/AnimatedSprite
onready var camera: Camera2D = $Camera2D

export(float) var jump_height: float = 64.0
export(float) var jump_time_to_peak: float = 0.4
export(float) var jump_time_to_fall: float = 0.3

export(float) var slide_distance: float = 64.0
export(float) var slide_duration: float = 0.4

onready var slide_velocity: float = ((2.0 * slide_distance) / slide_duration)
var last_state: int = 0

onready var jump_velocity: float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
onready var jump_gravity: float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
onready var fall_gravity: float = ((-2.0 * jump_height) / (jump_time_to_fall * jump_time_to_fall)) * -1.0

var last_wall: int

func _ready() -> void:
#	Engine.time_scale = 0.50
	pass

func _physics_process(delta: float) -> void:
	handle_state(delta)
	handle_collison()

func set_state(new_state: int) -> void:
	previous_state = state
	state = new_state

func handle_state(delta: float) -> void:
	match state:
		IDLE:
			ledge_snap = false
			last_wall = 0
			frictionless_jump = false
			apply_gravity(delta)
			apply_velocity()
			if not is_on_floor():
				set_state(FALL)
			if abs(G.poll_input().x) > 0:
				set_state(MOVE)
			if Input.is_action_just_pressed("down"):
				set_state(CROUCH)
			if Input.is_action_just_pressed("jump") or not jump_buffer_timer.is_stopped():
				jump()
		MOVE:
			apply_gravity(delta)
			if not is_on_floor():
				set_state(FALL)
			if abs(G.poll_input().x) == 0:
				set_state(IDLE)
			if Input.is_action_just_pressed("down"):
				set_state(CROUCH)
			if Input.is_action_just_pressed("jump") or not jump_buffer_timer.is_stopped():
				jump()
			if Input.is_action_just_pressed("slide"):
				slide()
			apply_velocity()
		CROUCH:
			apply_gravity(delta)
			if not is_on_floor():
				set_state(FALL)
			if abs(G.poll_input().x) > 0:
				set_state(CRAWL)
			if Input.is_action_just_pressed("up") and not detect_ceiling():
				set_state(IDLE)
			if Input.is_action_just_pressed("jump") and not detect_ceiling():
				jump()
			apply_velocity()
		CRAWL:
			apply_gravity(delta)
			if not is_on_floor():
				set_state(FALL)
			if abs(G.poll_input().x) == 0:
				set_state(CROUCH)
			if Input.is_action_just_pressed("up") and not detect_ceiling():
				set_state(MOVE)
			if Input.is_action_just_pressed("jump") and not detect_ceiling():
				jump()
			apply_velocity()
		JUMP, SPINJUMP:
			apply_gravity(delta)
			if Input.is_action_just_pressed("slide") and abs(velocity.x) > move_speed:
				powerslide_timer.start(0.5)
				set_state(POWERSLIDE)
			if detect_ledge():
				snap_ledge()
#			if detect_wallslide():
#				set_state(WALLSLIDE)
			if velocity.y > 0 and !is_on_floor():
				set_state(FALL)
			if Input.is_action_just_pressed("jump"):
				jump()
			apply_velocity()
		FALL:
			apply_gravity(delta)
			if velocity.y > 2000:
				ground_slam = true
			if Input.is_action_just_pressed("slide") and abs(velocity.x) > move_speed:
					powerslide_timer.start(0.5)
					set_state(POWERSLIDE)
			if detect_ledge():
				snap_ledge()
			if Input.is_action_just_pressed("jump"):
				jump()
			if is_on_floor():
				set_state(GROUNDSLAM if ground_slam else LAND)
			if detect_wallslide():
				set_state(WALLSLIDE)
			apply_velocity()
		WALLSLIDE:
			apply_gravity(delta)
			if Input.is_action_just_pressed("jump") or not jump_buffer_timer.is_stopped():
				var temp = (jump_velocity*-1)*ray_torso.get_collision_normal().x /2
				print(temp)
				facing.scale.x = ray_torso.get_collision_normal().x
				last_facing = ray_torso.get_collision_normal().x
				velocity.x = temp
				jump()
			if not detect_wallslide() or ray_close_ground.is_colliding() or ray_other_wall.is_colliding():
				set_state(FALL)
			apply_velocity()
		LAND:
			apply_gravity(delta)
			apply_velocity()
			if Input.is_action_just_pressed("jump") or not jump_buffer_timer.is_stopped():
				jump()
			else:
				set_state(IDLE)
		GROUNDSLAM:
			apply_gravity(delta)
			if ground_slam:
				velocity = Vector2.ZERO
			ground_slam = false
			yield(sprite, "animation_finished")
			set_state(IDLE)
		LEDGE:
			snap_ledge()
			velocity.y = 0
			if Input.is_action_pressed("up"):
				climb_ledge(delta)
			if Input.is_action_just_pressed("down"):
				ledge_timer.start(0.15)
				set_state(FALL)
			if Input.is_action_just_pressed("jump"):
				print(G.poll_input().x)
				print(ray_torso.get_collision_normal().x)
				if abs(G.poll_input().x) > 0 and G.poll_input().x != ray_torso.get_collision_normal().x*-1:
					velocity.x = (jump_velocity*-1)*ray_torso.get_collision_normal().x /2
				jump()
		LEDGECLIMB:
			pass
		SLIDE:
			if slide_timer.is_stopped():
				set_state(CROUCH if detect_ceiling() else IDLE)
			apply_velocity()
		POWERSLIDE:
			apply_gravity(delta)
			if (is_on_floor() and powerslide_timer.is_stopped()) or is_on_wall():
				set_state(IDLE)
			elif not is_on_floor():
				powerslide_timer.start(0.5)
			if Input.is_action_just_pressed("jump"):
				jump()
			apply_velocity()

func handle_collison() -> void:
	if [CROUCH, SLIDE, CRAWL, POWERSLIDE].has(state):
		crouching.disabled = false
		standing.disabled = true
	elif not detect_ceiling():
		standing.disabled = false
		crouching.disabled = true

func apply_velocity() -> void:
	if was_on_floor and not is_on_floor():
		jump_coyate_timer.start(coyate_buffer)
	if G.poll_input().x != 0:
		last_facing = facing.scale.x
		facing.scale.x = G.poll_input().x
	velocity.x = get_speed()
	floor_snap = Vector2.DOWN * 8 if not [JUMP, CLIMB, SPINJUMP].has(state) else Vector2.ZERO
	was_on_floor = is_on_floor()
	velocity = move_and_slide_with_snap(velocity, floor_snap, Vector2.UP, true)

func snap_ledge() -> void:
	var ledge: Ledge = ray_ledge.get_collider()
	position = ledge.left_position if ray_ledge.get_collision_normal().x == -1 else ledge.right_position
	print(position)
	print(position.floor())
#	position = position.floor()
	set_state(LEDGE)

func climb_ledge(_delta: float) -> void:
	set_state(LEDGECLIMB)
	camera.smoothing_enabled = true
	var ledge: Ledge = ray_ledge.get_collider()
	position = ledge.top_position
	pass
	yield(sprite,"animation_finished")
	camera.smoothing_enabled = false
	velocity = Vector2.ZERO
	set_state(IDLE)

func get_speed() -> float:
	if is_on_floor():
		if abs(G.poll_input().x) > 0:
			speed += get_acceleration() * G.poll_input().x
		else:
			speed = move_toward(velocity.x, 0, get_friction())
	else:
		if detect_wallslide():
			speed = velocity.x
		if velocity.x < move_speed and abs(G.poll_input().x) > 0:
			speed += (get_acceleration()/2) * G.poll_input().x
		if [LEDGE, LEDGECLIMB].has(state):
			speed = 0.0
	if facing.scale.x != last_facing and not get_friction() < friction:
		speed = velocity.x / 4
	speed = clamp(speed, -get_max_speed(), get_max_speed())
	return speed if can_move else 0.0

func jump() -> void:
	if not [LEDGE, WALLSLIDE].has(state) and not is_on_floor() and jump_coyate_timer.is_stopped():
		jump_buffer_timer.start(jump_buffer)
	elif not detect_ceiling():
		if get_friction() < friction:
			frictionless_jump = true
		if abs(velocity.x) >= move_speed/2:
			set_state(SPINJUMP)
		else:
			set_state(JUMP)
		velocity.y = jump_velocity
		print(velocity.x)

func slide() -> void:
	if slide_timer.is_stopped() and slide_cd_timer.is_stopped():
		slide_timer.start(slide_duration)
		set_state(SLIDE)
		handle_collison()
		velocity.x = slide_velocity * facing.scale.x

func apply_gravity(delta: float) -> void:
	var gravity: float = jump_gravity if velocity.y < 0.0 else fall_gravity
	if velocity.y > 0.0 and Input.is_action_pressed("down"):
		gravity = gravity*2
	if state == WALLSLIDE:
		velocity.y = gravity/64
	else:
		velocity.y += gravity * delta if not is_on_floor() else 0.0

func get_max_speed() -> float:
	if (not is_on_floor() and abs(velocity.x) > move_speed) or state == POWERSLIDE:
		return abs(velocity.x)
	if get_friction() < friction or frictionless_jump:
		return move_speed * 2
	if [CRAWL, CROUCH].has(state):
		return move_speed / 4
	return move_speed

func get_acceleration() -> float:
	if [CROUCH, CRAWL].has(state):
		return acceleration * 3
	if get_friction() < friction:
		return acceleration / 2
	return acceleration

func get_friction() -> float:
	if ray_feet.is_colliding():
		return ray_feet.get_collider().friction
	return friction

func clamber(delta: float) -> void:
	position = Vector2(position.x + ((move_speed/10)*G.poll_input().x)*delta, position.y - 16)

func detect_wallslide() -> bool:
	return true if ray_torso.is_colliding() and ray_legs.is_colliding() and ray_below_feet.is_colliding() and not ray_close_ground.is_colliding() and not ray_other_wall.is_colliding() else false

func detect_ledge() -> bool:
	return true if ray_ledge.is_colliding() and ledge_timer.is_stopped() else false

func detect_clamber() -> bool:
	return true if abs(G.poll_input().x) > 0 and not ray_torso.is_colliding() and not ray_head.is_colliding() and ray_legs.is_colliding() else false

func detect_ceiling() -> bool:
	return true if ray_ceiling.is_colliding() or ray_crouch_ceiling.is_colliding() else false

func _unhandled_input(event) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()
	if event.is_action_pressed("restart"):
		var _discard := get_tree().reload_current_scene()
