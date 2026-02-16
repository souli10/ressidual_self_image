extends Hackable

## Debris — blocks the path. Use "delete" to remove it.


func _ready() -> void:
	object_name = "Debris"
	valid_commands = PackedStringArray(["delete"])
	hack_description = "struct Debris {\n  bool solid = true;\n  float integrity = 87.3;\n}"
	collision_layer = 3   # layers 1 (blocks movement) + 2 (hackable)
	collision_mask = 0


func _on_hacked(_command: String) -> void:
	# Disable collision so player can walk through
	$CollisionShape2D.set_deferred("disabled", true)
	# Visual: shrink and fade
	var tween = create_tween()
	tween.tween_property($Visual, "scale", Vector2(0.1, 0.1), 0.4)
	tween.parallel().tween_property($Visual, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
