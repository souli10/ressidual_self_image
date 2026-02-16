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
			var dist := global_position.distance_to(obj.global_position)
			if dist < Constants.HACK_RANGE:
				GameManager.request_terminal(obj)
