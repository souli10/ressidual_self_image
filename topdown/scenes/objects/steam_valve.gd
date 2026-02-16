extends Hackable

## Steam Valve — Use "unlock" to activate fog in the level.


func _ready() -> void:
	object_name = "Steam Valve"
	valid_commands = PackedStringArray(["unlock"])
	hack_description = "struct Valve {\n  bool sealed = true;\n  float pressure_psi = 120.0;\n  string system = \"STEAM_MAIN\";\n}"
	collision_layer = 2   # hackable only
	collision_mask = 0


func _on_hacked(_command: String) -> void:
	# Visual feedback
	$Visual.color = Color(0.0, 0.8, 0.0, 0.6)

	# Activate fog in the level
	var level = get_parent()
	if level.has_method("activate_fog"):
		level.activate_fog()
