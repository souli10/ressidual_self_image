extends Hackable

## Security Camera — sweeps back and forth detecting the player.
## Use "stop" to freeze it temporarily.

@export var sweep_speed: float = 30.0  # degrees per second
@export var sweep_range: float = 60.0  # total sweep arc in degrees
@export var freeze_duration: float = 8.0
@export var detection_range: float = 180.0

var base_rotation: float = 0.0
var sweep_timer: float = 0.0
var is_frozen: bool = false
var freeze_timer: float = 0.0


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

	# Sweep back and forth
	sweep_timer += delta
	var sweep_offset = sin(sweep_timer * sweep_speed * 0.05) * (sweep_range / 2.0)
	rotation_degrees = base_rotation + sweep_offset

	# Check for player in detection cone
	_check_detection()


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
	$Visual.color = Color(0.2, 0.2, 0.2, 0.3)
	if has_node("DetectionArea"):
		$DetectionArea.monitoring = false
