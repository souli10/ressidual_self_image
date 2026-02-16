extends Hackable


func _ready() -> void:
	object_name = "Locked Door"
	valid_commands = PackedStringArray(["unlock"])
	hack_description = "struct Door {\n  bool locked = true;\n  string auth_level = \"LEVEL_1\";\n  string status = \"SEALED\";\n}"
	collision_layer = 3   # layers 1 + 2
	collision_mask = 0


func _on_hacked(_command: String) -> void:
	# Remove from ALL collision layers so nothing blocks on us
	collision_layer = 0
	collision_mask = 0
	$CollisionShape2D.set_deferred("disabled", true)
	# Visual: fade to green-tinted ghost
	$Visual.color = Color(0.15, 0.4, 0.15, 0.2)
