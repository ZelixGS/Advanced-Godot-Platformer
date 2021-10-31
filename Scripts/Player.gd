class_name Player
extends KinematicBody2D

enum {DEAD, IDLE, MOVE, JUMP, FALL, CROUCH, CRAWL, LAND, SLIDE, DIVE, LEDGE, LEDGECLIMB, CLIMB, POWERSLIDE, GROUNDSLAM}
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

onready var facing: Node2D = $Facing

onready var ray_ceiling: RayCast2D = $Facing/Rays/Ceiling
onready var ray_ledge: RayCast2D = $Facing/Rays/Ledge
onready var ray_head: RayCast2D = $Facing/Rays/Head
onready var ray_torso: RayCast2D = $Facing/Rays/Torso
onready var ray_legs: RayCast2D = $Facing/Rays/Legs
onready var ray_feet: RayCast2D = $Facing/Rays/Feet

onready var sprite: AnimatedSprite = $Facing/AnimatedSprite
onready var camera: Camera2D = $GameCamera

onready var crawl_timer_started: bool = false
onready var auto_clamber_timer: Timer = $Timers/AutoClamberCD
onready var slide_timer: Timer = $Timers/Slide
onready var slide_cd_timer: Timer = $Timers/SlideCD
onready var ledge_timer: Timer = $Timers/Ledge
onready var powerslide_timer: Timer = $Timers/Powerslide
onready var jump_buffer_timer: Timer = $Timers/JumpBuffer
onready var jump_coyate_timer: Timer = $Timers/JumpCoyate


export(float) var jump_height: float = 64.0
export(float) var jump_time_to_peak: float = 0.4
export(float) var jump_time_to_fall: float = 0.3

export(float) var slide_distance: float = 64.0
export(float) var slide_duration: float = 0.4

onready var slide_velocity: float = ((2.0 * slide_distance) / slide_duration)
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
	if [IDLE, MOVE].has(state):
		ledge_snap = false
		frictionless_jump = false
		apply_gravity(delta)
		if not is_on_floor():
			set_state(FALL)
		else:
			if detect_vault() and state == MOVE:
				vault()
			set_state(MOVE if abs(G.get_input().x) > 0 else IDLE)
		if Input.is_action_just_pressed("slide"):
			slide()
		if Input.is_action_just_pressed("crouch"):
			set_state(CROUCH)
		if Input.is_action_just_pressed("jump") or not jump_buffer_timer.is_stopped():
			jump()
		apply_velocity()
	elif [CROUCH, CRAWL].has(state):
		apply_gravity(delta)
		if is_on_floor():
			set_state(CRAWL if abs(G.get_input().x) > 0 else CROUCH)
		else:
			set_state(FALL)
		if Input.is_action_just_pressed("up") and not detect_ceiling():
			set_state(IDLE)
		if Input.is_action_just_pressed("jump") and not detect_ceiling():
			jump()
		apply_velocity()
	elif state == JUMP:
		apply_gravity(delta)
		if Input.is_action_just_pressed("slide") and abs(velocity.x) > move_speed:
			powerslide_timer.start(0.5)
			set_state(POWERSLIDE)
		if detect_ledge():
			snap_ledge()
		if velocity.y > 0 and !is_on_floor():
			set_state(FALL)
		if Input.is_action_just_pressed("jump"):
			if detect_walljump():
				facing.scale.x = ray_torso.get_collision_normal().x
				last_facing = facing.scale.x
				velocity.x = (jump_velocity*-1)*last_facing /2
			jump()
		apply_velocity()
	elif state == FALL:
		apply_gravity(delta)
		if velocity.y > 2000 and not ground_slam:
			ground_slam = true
		if Input.is_action_just_pressed("slide") and abs(velocity.x) > move_speed:
				powerslide_timer.start(0.5)
				set_state(POWERSLIDE)
		if detect_ledge():
			snap_ledge()
		if Input.is_action_just_pressed("jump"):
			if detect_walljump():
				facing.scale.x = ray_torso.get_collision_normal().x
				last_facing = facing.scale.x
				velocity.x = (jump_velocity*-1)*last_facing /2
			jump()
		if is_on_floor():
			set_state(GROUNDSLAM if ground_slam else IDLE)
		apply_velocity()
	elif state == GROUNDSLAM:
		apply_gravity(delta)
		if ground_slam:
			velocity = Vector2.ZERO
		ground_slam = false
		yield(sprite, "animation_finished")
		set_state(IDLE)
	elif state == LEDGE:
		snap_ledge()
		velocity.y = 0
		if Input.is_action_pressed("up") or G.clamp_input(G.get_input()).x == ray_torso.get_collision_normal().x*-1:
			climb_ledge(delta)
		if Input.is_action_just_pressed("down"):
			ledge_timer.start(0.15)
			set_state(FALL)
		if Input.is_action_just_pressed("jump"):
			ledge_timer.start(0.15)
			if abs(G.get_input().x) > 0 and G.clamp_input(G.get_input()).x == ray_torso.get_collision_normal().x:
				facing.scale.x = ray_torso.get_collision_normal().x
				last_facing = facing.scale.x
				velocity.x = (jump_velocity*-1) * facing.scale.x / 2
			jump()
	elif state == SLIDE:
		if slide_timer.is_stopped():
			set_state(CROUCH if detect_ceiling() else IDLE)
		apply_velocity()
	elif state == POWERSLIDE:
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
	if was_on_floor and not is_on_floor() and state != JUMP:
		jump_coyate_timer.start(coyate_buffer)
	if G.get_input().x != 0:
		last_facing = facing.scale.x
		facing.scale.x = G.clamp_input(G.get_input()).x
	velocity.x = get_speed()
	floor_snap = Vector2.DOWN * 8 if state != JUMP else Vector2.ZERO
	was_on_floor = is_on_floor()
	velocity = move_and_slide_with_snap(velocity, floor_snap, Vector2.UP, true)

func snap_ledge() -> void:
	if ray_ledge.get_collider() is Ledge:
		var ledge: Ledge = ray_ledge.get_collider()
		position = ledge.left_position if ray_ledge.get_collision_normal().x == -1 else ledge.right_position
		set_state(LEDGE)

func climb_ledge(_delta: float) -> void:
	set_state(LEDGECLIMB)
	if ray_ledge.get_collider() is Ledge:
		var ledge: Ledge = ray_ledge.get_collider()
		position = ledge.top_position
		yield(sprite,"animation_finished")
		velocity = Vector2.ZERO
	set_state(IDLE)

func get_speed() -> float:
	if is_on_floor():
		if abs(G.get_input().x) > 0:
			speed += get_acceleration() * (-1 if G.get_input().x < 0 else 1)
		else:
			speed = move_toward(velocity.x, 0, get_friction())
	else:
		if detect_walljump() or previous_state == LEDGE:
			speed = velocity.x
		if velocity.x < move_speed and abs(G.get_input().x) > 0:
			speed += (get_acceleration()/2) * (-1 if G.get_input().x < 0 else 1)
		if [LEDGE, LEDGECLIMB].has(state):
			speed = 0.0
	if facing.scale.x != last_facing and not get_friction() < friction:
		speed = velocity.x / 4
	speed = clamp(speed, -get_max_speed(), get_max_speed())
	return speed if can_move else 0.0

func jump() -> void:
	if not [LEDGE].has(state) and not detect_walljump() and not is_on_floor() and jump_coyate_timer.is_stopped():
		jump_buffer_timer.start(jump_buffer)
	elif not detect_ceiling():
		if get_friction() < friction:
			frictionless_jump = true
		set_state(JUMP)
		velocity.y = jump_velocity

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
	velocity.y += gravity * delta if not is_on_floor() else 0.0

func get_max_speed() -> float:
	if (not is_on_floor() and abs(velocity.x) > move_speed) or state == POWERSLIDE:
		return abs(velocity.x)
	if [CRAWL, CROUCH].has(state):
		return move_speed / 4
	if get_friction() < friction or frictionless_jump:
		return move_speed * 2
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

func detect_vault() -> bool:
	return true if not ray_head.is_colliding() and not ray_torso.is_colliding() and ray_legs.is_colliding() else false
	
func vault() -> void:
	position = Vector2(position.x + (3 * facing.scale.x), position.y - 16)

func detect_walljump() -> bool:
	return true if not is_on_floor() and ray_torso.is_colliding() and ray_legs.is_colliding() else false

func detect_ledge() -> bool:
	return true if ray_ledge.is_colliding() and ledge_timer.is_stopped() else false

func detect_ceiling() -> bool:
	return true if ray_ceiling.is_colliding() else false

func _unhandled_input(event) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()
	if event.is_action_pressed("restart"):
		var _discard := get_tree().reload_current_scene()
