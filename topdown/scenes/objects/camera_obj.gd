extends Hackable

## Security Camera — sweeps back and forth detecting the player.
## Use "stop" to freeze it temporarily.

@export var sweep_speed: float = 30.0  # degrees per second
@export var sweep_range: float = 60.0  # total sweep arc in degrees
@export var freeze_duration: float = 8.0
@export var detection_range: float = 180.0
@export var pause_duration: float = 1.5  # Pause at each end of the sweep

var base_rotation: float = 0.0
var sweep_timer: float = 0.0
var is_frozen: bool = false
var freeze_timer: float = 0.0
var pause_timer: float = 0.0
var is_pausing: bool = false
var sweep_direction: int = 1 # 1 for clockwise/right, -1 for counter-clockwise/left
var current_sweep_angle: float = 0.0


func _ready() -> void:
	object_name = "Security Camera"
	valid_commands = PackedStringArray(["stop"])
	hack_description = "struct Camera {\n  bool recording = true;\n  float sweep_angle = 0.0;\n  string status = \"ACTIVE\";\n}"
	collision_layer = 2   # hackable only
	collision_mask = 0
	base_rotation = rotation_degrees


func _process(delta: float) -> void:
	super._process(delta)

	if is_frozen:
		freeze_timer -= delta
		if freeze_timer <= 0.0:
			is_frozen = false
			is_hacked = false  # can be hacked again
			$Visual.color = Color(0.4, 0.5, 0.4, 1.0)
			if has_node("DetectionArea"):
				$DetectionArea.monitoring = true
		return

	# Sweep back and forth with pauses at ends
	if is_pausing:
		pause_timer -= delta
		if pause_timer <= 0.0:
			is_pausing = false
	else:
		# Use linear sweep for more predictable pauses
		var move_step = sweep_speed * delta * sweep_direction
		current_sweep_angle += move_step
		
		# Check if we've reached the range limit
		var half_range = sweep_range / 2.0
		if abs(current_sweep_angle) >= half_range:
			current_sweep_angle = clamp(current_sweep_angle, -half_range, half_range)
			sweep_direction *= -1 # Reverse direction
			is_pausing = true
			pause_timer = pause_duration
		
		rotation_degrees = base_rotation + current_sweep_angle

	# Check for player in detection cone
	_check_detection()
	queue_redraw()


func _draw() -> void:
	if is_frozen:
		# Draw a faded or different colored cone when frozen
		_draw_cone(Color(0.5, 0.5, 0.5, 0.1))
	else:
		# Draw the active detection cone
		_draw_cone(Color(0.1, 1.0, 0.1, 0.2) if not GameManager.is_terminal_open else Color(0.1, 0.8, 0.1, 0.1))


func _draw_cone(color: Color) -> void:
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	
	var cone_half_angle := 30.0 # 60 degree total cone
	var segments := 20
	
	for i in range(segments + 1):
		var angle_deg = -cone_half_angle + (i * (cone_half_angle * 2.0 / segments))
		var angle_rad = deg_to_rad(angle_deg)
		points.append(Vector2.RIGHT.rotated(angle_rad) * detection_range)
	
	draw_polygon(points, [color])


func _check_detection() -> void:
	if is_frozen or GameManager.is_terminal_open:
		return

	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return

	var player = players[0]
	var to_player = player.global_position - global_position
	var dist = to_player.length()

	if dist > detection_range:
		return

	# Check if player is within sweep cone angle
	var cam_forward = Vector2.RIGHT.rotated(deg_to_rad(rotation_degrees))
	var angle = rad_to_deg(cam_forward.angle_to(to_player))

	if abs(angle) < 30.0:  # 60 degree cone
		# Camera spotted the player — alert all agents!
		GameManager.agent_alert.emit(player.global_position)


func _on_hacked(_command: String) -> void:
	is_frozen = true
	freeze_timer = freeze_duration
	if has_node("Visual"):
		$Visual.modulate = Color(0.2, 0.2, 0.2, 0.5)
	if has_node("DetectionArea"):
		$DetectionArea.monitoring = false
	queue_redraw()
