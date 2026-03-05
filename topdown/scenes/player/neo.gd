extends CharacterBody2D

@export var speed: float = Constants.PLAYER_SPEED

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var is_moving: bool = false


func _ready() -> void:
	add_to_group("player")


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.is_terminal_open:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			nav_agent.target_position = get_global_mouse_position()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_try_hack_at(get_global_mouse_position())


func _physics_process(_delta: float) -> void:
	if nav_agent.is_navigation_finished():
		if is_moving:
			AudioManager.stop_footsteps()
		is_moving = false
		velocity = Vector2.ZERO
		return

	var next_pos := nav_agent.get_next_path_position()
	var direction := global_position.direction_to(next_pos)
	velocity = direction * speed
	move_and_slide()

	# Only play steps if actually moving
	if get_real_velocity().length() < 10.0:
		if is_moving:
			AudioManager.stop_footsteps()
		is_moving = false
		_update_animation(Vector2.ZERO)
	else:
		if not is_moving:
			AudioManager.play_footsteps()
		is_moving = true
		_update_animation(direction)


func _update_animation(dir: Vector2) -> void:
	var sprite = $Sprite2D
	if not sprite:
		return
		
	# Matrix Layout (vframes=5, hframes=4):
	# Row 0: Invalid
	# Row 1: North (Up)
	# Row 2: West (Left)
	# Row 3: South (Down)
	# Row 4: East (Right)
	var row = 3 # Default South
	sprite.flip_h = false # Matrix has all 4 directions, no need to flip
	
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			row = 4 # East (Right)
		else:
			row = 2 # West (Left)
	else:
		if dir.y < 0:
			row = 1 # North (Up)
		else:
			row = 3 # South (Down)
			
	if dir == Vector2.ZERO:
		# Idle: freeze on the first frame of the current row
		var current_row = sprite.frame / sprite.hframes
		if current_row == 0:
			current_row = 3 # Fallback if somehow on invalid row
		sprite.frame = current_row * sprite.hframes
		return
		
	# Animate using time
	var anim_speed = 6.0
	var frames_in_row = sprite.hframes
	var current_frame = int(Time.get_ticks_msec() / 1000.0 * anim_speed) % frames_in_row
	sprite.frame = row * frames_in_row + current_frame


func _try_hack_at(click_pos: Vector2) -> void:
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = click_pos
	params.collide_with_bodies = true
	params.collision_mask = 2
	var results := space.intersect_point(params, 1)
	if results.size() > 0:
		var obj = results[0].collider
		if obj is Hackable:
			if obj.cooldown_remaining > 0.0:
				_show_locked_message(obj)
			else:
				GameManager.request_terminal(obj)


func _show_locked_message(obj: Hackable) -> void:
	var label := Label.new()
	label.text = "SYSTEM LOCKED"
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	label.add_theme_font_size_override("font_size", 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = obj.position + Vector2(-40, -40)
	label.z_index = 100
	obj.get_parent().add_child(label)
	
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.3)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
