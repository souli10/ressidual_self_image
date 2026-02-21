extends Node2D

@onready var nav_region: NavigationRegion2D = $NavigationRegion2D
@onready var hud = $HUD

var level_active: bool = true
var door_unlocked: bool = false


func _ready() -> void:
	GameManager.current_level = "level_isolation"
	GameManager.tank_connected = true
	_setup_navigation()
	
	# Gate the exit until the elevator door is unlocked
	door_unlocked = false
	
	await get_tree().create_timer(1.0).timeout
	if not level_active or not is_inside_tree():
		return
	if hud and hud.has_method("tank_says"):
		hud.tank_says("Neo, something's wrong. The signal is degrading...", 3.0)
		await get_tree().create_timer(5.0).timeout
		if not level_active or not is_inside_tree():
			return
		_trigger_disconnect()


func _trigger_disconnect() -> void:
	var camera = get_viewport().get_camera_2d()
	if camera:
		var original_offset = camera.offset
		for i in 15:
			if not is_inside_tree():
				return
			camera.offset = original_offset + Vector2(randf_range(-4, 4), randf_range(-4, 4))
			await get_tree().create_timer(0.05).timeout
		camera.offset = original_offset
	GameManager.tank_connected = false
	if not is_inside_tree():
		return
	if hud and hud.has_method("show_message"):
		hud.show_message("TANK", "Neo... signal jamming... [CONNECTION LOST]", 3.0)
		await get_tree().create_timer(4.0).timeout
		if not is_inside_tree():
			return
		hud.show_message("SYSTEM", "Operator connection terminated. Unlock the elevator door to escape.", 3.0)


func _setup_navigation() -> void:
	var outline := PackedVector2Array([
		Vector2(100, 100), Vector2(540, 100), Vector2(540, 500), Vector2(100, 500)
	])
	nav_region.navigation_polygon = GameManager.build_nav_for_level([outline], self)


func _on_exit_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Check if the elevator door was unlocked (hacked)
		var door = get_node_or_null("ElevatorDoor")
		if door and not door.is_hacked:
			# Door still locked — show feedback
			if hud and hud.has_method("show_message"):
				hud.show_message("SYSTEM", "Elevator door is still locked. Hack it to proceed.", 2.0)
			return
		level_active = false
		GameManager.load_next_level()
