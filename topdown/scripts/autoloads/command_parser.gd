extends Node

## Validates and executes a typed command against a Hackable target.
## Returns { "success": bool, "message": String }
func execute(command_text: String, target) -> Dictionary:
	var cmd := command_text.strip_edges().to_lower()

	if target.is_hacked:
		return { "success": false, "message": "System already compromised." }

	if target.cooldown_remaining > 0.0:
		return {
			"success": false,
			"message": "System locked. Retry in %.1fs." % target.cooldown_remaining
		}

	var valid: PackedStringArray = target.get_valid_commands()

	if cmd not in valid:
		target.cooldown_remaining = GameManager.get_cooldown()
		# Broadcast hack failure to agents
		if target is Node2D:
			GameManager.broadcast_hack_failure(target.global_position)
		return {
			"success": false,
			"message": "ERROR: Command '%s' rejected. System locked for %.0fs." % [cmd, target.cooldown_remaining]
		}

	# Success — let the object handle its own effect
	target.on_hack_success(cmd)
	return {
		"success": true,
		"message": "SUCCESS: %s executed on %s." % [cmd, target.object_name]
	}
