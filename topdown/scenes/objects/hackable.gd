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


func _process(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining -= delta
		if cooldown_remaining < 0.0:
			cooldown_remaining = 0.0


func get_valid_commands() -> PackedStringArray:
	return valid_commands


## Called by CommandParser on a successful hack.
func on_hack_success(command: String) -> void:
	is_hacked = true
	_on_hacked(command)


## Override in subclasses to define what happens when hacked.
func _on_hacked(_command: String) -> void:
	pass
