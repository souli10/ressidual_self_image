class_name Hackable
extends StaticBody2D

## Display name shown in the terminal header.
@export var object_name: String = "Unknown Object"
## Which commands work on this object (e.g. ["unlock"]).
@export var valid_commands: PackedStringArray = []
## Flavour text shown when the terminal connects.
@export var hack_description: String = "A hackable system node."

var is_hacked: bool = false
var cooldown_remaining: float = 0.0

## Visual cooldown references (created at runtime)
var _cooldown_label: Label = null
var _original_modulate: Color = Color.WHITE
var _pulse_time: float = 0.0


func _ready() -> void:
	_original_modulate = modulate
	_create_cooldown_label()


func _process(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining -= delta
		_pulse_time += delta
		
		# Pulse red while on cooldown
		var pulse := (sin(_pulse_time * 6.0) + 1.0) / 2.0
		modulate = _original_modulate.lerp(Color(1.0, 0.2, 0.2, 1.0), pulse * 0.6)
		
		# Update cooldown label
		if _cooldown_label:
			_cooldown_label.visible = true
			_cooldown_label.text = "LOCKED %.1fs" % cooldown_remaining
		
		if cooldown_remaining < 0.0:
			cooldown_remaining = 0.0
	else:
		if _pulse_time > 0.0:
			# Cooldown just expired — flash green briefly
			_pulse_time = 0.0
			modulate = _original_modulate
			if _cooldown_label:
				_cooldown_label.visible = false
			_flash_available()


func get_valid_commands() -> PackedStringArray:
	return valid_commands


## Called by CommandParser on a successful hack.
func on_hack_success(command: String) -> void:
	is_hacked = true
	modulate = _original_modulate
	if _cooldown_label:
		_cooldown_label.visible = false
	_on_hacked(command)


## Override in subclasses to define what happens when hacked.
func _on_hacked(_command: String) -> void:
	pass


func _create_nav_obstacle() -> void:
	var obstacle := NavigationObstacle2D.new()
	obstacle.avoidance_enabled = true
	# Try to derive size from collision shape
	var radius := 20.0
	for child in get_children():
		if child is CollisionShape2D and child.shape:
			if child.shape is RectangleShape2D:
				var half := (child.shape as RectangleShape2D).size / 2.0
				obstacle.vertices = PackedVector2Array([
					Vector2(-half.x, -half.y),
					Vector2(half.x, -half.y),
					Vector2(half.x, half.y),
					Vector2(-half.x, half.y),
				])
				add_child(obstacle)
				return
			elif child.shape is CircleShape2D:
				radius = (child.shape as CircleShape2D).radius
	# Fallback: square obstacle
	obstacle.vertices = PackedVector2Array([
		Vector2(-radius, -radius),
		Vector2(radius, -radius),
		Vector2(radius, radius),
		Vector2(-radius, radius),
	])
	add_child(obstacle)


func _create_cooldown_label() -> void:
	_cooldown_label = Label.new()
	_cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cooldown_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	_cooldown_label.add_theme_font_size_override("font_size", 10)
	_cooldown_label.position = Vector2(-30, -25)
	_cooldown_label.visible = false
	add_child(_cooldown_label)


func _flash_available() -> void:
	modulate = Color(0.2, 1.0, 0.2, 1.0)
	await get_tree().create_timer(0.3).timeout
	modulate = _original_modulate
