#func detect_wall() -> int:
#	if not is_on_wall():
#		return NULL
#	elif not ray_torse.is_colliding() and not ray_above_head.is_colliding() and ray_legs.is_colliding():
#		return CAN_CLAMBER
#	elif not ray_torse.is_colliding() and ray_above_head.is_colliding() and ray_legs.is_colliding():
#		return CAN_CLAMBER_CRAWL
#	elif ray_torse.is_colliding() and not ray_legs.is_colliding():
#		return CAN_CRAWL
#	else:
#		return WALL
		
#	if detect_wall() == CAN_CRAWL:
#		auto_into_crawl()
#	if detect_wall() == CAN_CLAMBER_CRAWL:
#		auto_into_crawl()
#		if [CRAWL, CROUCH].has(state):
#			clamber(delta)

#func auto_into_crawl() -> void:
#	if not crawl_timer_started:
#		crawl_timer_started = true
#		crawl_timer.start(0.25)
#	if crawl_timer_started and crawl_timer.is_stopped():
#		state = CRAWL
#		crawl_timer_started = false
