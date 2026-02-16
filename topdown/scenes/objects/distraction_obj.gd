extends Hackable

## Distraction Object (Printer, etc.) — Use "ping" to emit a sound
## that attracts nearby Agents to investigate this position.

@export var distraction_duration: float = 5.0


func _ready() -> void:
	object_name = "Printer"
	valid_commands = PackedStringArray(["ping"])
	hack_description = "struct Printer {\n  bool active = false;\n  int queue_size = 0;\n}"
	collision_layer = 2   # hackable only, doesn't block movement
	collision_mask = 0


func _on_hacked(_command: String) -> void:
	# Emit sound that attracts agents
	GameManager.broadcast_hack_failure(global_position)

	# Visual feedback: blink the printer
	var tween = create_tween()
	tween.set_loops(5)
	tween.tween_property($Visual, "modulate", Color(0.0, 1.0, 0.0, 1.0), 0.3)
	tween.tween_property($Visual, "modulate", Color(0.3, 0.5, 0.3, 1.0), 0.3)

	# Reset hacked state after duration so it can be reused
	await get_tree().create_timer(distraction_duration).timeout
	is_hacked = false
