extends CharacterBody2D

## Agent AI — Finite State Machine: PATROL → INVESTIGATE → CHASE
## Patrols waypoints, investigates hack failures or last-seen player positions,
## chases the player on sight. Collision with player restarts the level.

enum State { PATROL, INVESTIGATE, CHASE }

@export var patrol_speed: float = 80.0
@export var chase_speed: float = 160.0
@export var investigate_speed: float = 100.0
@export var vision_range: float = 150.0
@export var vision_angle_deg: float = 90.0
@export var investigate_timeout: float = 4.0
@export var patrol_wait_time: float = 1.5

## If true, this is Agent Smith — reacts to successful hacks too.
@export var is_smith: bool = false

@export var patrol_points: Array[Vector2] = []

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: Sprite2D = $Sprite2D

var current_state: State = State.PATROL
var patrol_index: int = 0
var investigate_timer: float = 0.0
var patrol_wait_timer: float = 0.0
var player_ref: CharacterBody2D = null
var last_known_player_pos: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	add_to_group("agents")
	collision_layer = 8
	collision_mask = 5

	nav_agent.path_desired_distance = 8.0
	nav_agent.target_desired_distance = 8.0

	# React to hack failures — investigate the noise
	GameManager.hack_failed.connect(_on_hack_failed)
	# Smith also detects successful hacks
	if is_smith:
		GameManager.hack_succeeded.connect(_on_hack_succeeded)


func _physics_process(delta: float) -> void:
	if GameManager.is_terminal_open:
		velocity = Vector2.ZERO
		return

	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.INVESTIGATE:
			_process_investigate(delta)
		State.CHASE:
			_process_chase(delta)

	_check_vision()
	_update_facing()
	move_and_slide()

	# Check direct collision with player → restart level
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		if col.get_collider() is CharacterBody2D:
			var collider = col.get_collider()
			if collider.is_in_group("player"):
				GameManager.restart_level()


# -- PATROL --
func _process_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		velocity = Vector2.ZERO
		return

	if patrol_wait_timer > 0.0:
		patrol_wait_timer -= delta
		velocity = Vector2.ZERO
		return

	var target = patrol_points[patrol_index]
	nav_agent.target_position = target

	if nav_agent.is_navigation_finished():
		patrol_wait_timer = patrol_wait_time
		patrol_index = (patrol_index + 1) % patrol_points.size()
		return

	var next_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_pos)
	velocity = direction * patrol_speed
	facing_direction = direction


# -- INVESTIGATE --
func _process_investigate(delta: float) -> void:
	investigate_timer -= delta
	nav_agent.target_position = last_known_player_pos

	if nav_agent.is_navigation_finished() or investigate_timer <= 0.0:
		_change_state(State.PATROL)
		return

	var next_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_pos)
	velocity = direction * investigate_speed
	facing_direction = direction


# -- CHASE --
func _process_chase(_delta: float) -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		_change_state(State.INVESTIGATE)
		return

	last_known_player_pos = player_ref.global_position
	nav_agent.target_position = last_known_player_pos

	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return

	var next_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_pos)
	velocity = direction * chase_speed
	facing_direction = direction


# -- VISION --
func _check_vision() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		if current_state == State.CHASE:
			_change_state(State.INVESTIGATE)
		return

	var player = players[0]
	var to_player = player.global_position - global_position
	var dist = to_player.length()

	if dist > vision_range:
		if current_state == State.CHASE:
			_change_state(State.INVESTIGATE)
		return

	var angle_to_player = rad_to_deg(facing_direction.angle_to(to_player))
	if abs(angle_to_player) > vision_angle_deg / 2.0:
		if current_state == State.CHASE:
			_change_state(State.INVESTIGATE)
		return

	# Raycast line of sight
	var space = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.collision_mask = 1
	query.exclude = [self]
	var result = space.intersect_ray(query)

	if result.is_empty():
		# Clear line of sight — chase!
		player_ref = player
		last_known_player_pos = player.global_position
		if current_state != State.CHASE:
			_change_state(State.CHASE)
	else:
		if current_state == State.CHASE:
			_change_state(State.INVESTIGATE)


# -- REACTIONS --
func _on_hack_failed(pos: Vector2) -> void:
	# Investigate hack failure noise — but seeing Neo is higher priority
	if current_state == State.PATROL or current_state == State.INVESTIGATE:
		last_known_player_pos = pos
		_change_state(State.INVESTIGATE)


func _on_hack_succeeded(pos: Vector2) -> void:
	# Only Smith reacts to successful hacks
	if current_state == State.PATROL or current_state == State.INVESTIGATE:
		last_known_player_pos = pos
		_change_state(State.INVESTIGATE)


# -- STATE MANAGEMENT --
func _change_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.PATROL:
			investigate_timer = 0.0
			player_ref = null
		State.INVESTIGATE:
			investigate_timer = investigate_timeout
		State.CHASE:
			pass
	_update_visual()


func _update_visual() -> void:
	if sprite == null:
		return
	match current_state:
		State.PATROL:
			sprite.modulate = Color(0.3, 0.3, 0.3, 1.0)
		State.INVESTIGATE:
			sprite.modulate = Color(0.8, 0.6, 0.0, 1.0)
		State.CHASE:
			sprite.modulate = Color(1.0, 0.0, 0.0, 1.0)


func _update_facing() -> void:
	if velocity.length_squared() > 1.0:
		facing_direction = velocity.normalized()
