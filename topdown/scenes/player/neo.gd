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
		is_moving = false
		velocity = Vector2.ZERO
		return
	is_moving = true
	var next_pos := nav_agent.get_next_path_position()
	var direction := global_position.direction_to(next_pos)
	velocity = direction * speed
	move_and_slide()


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
