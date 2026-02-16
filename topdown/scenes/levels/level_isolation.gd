extends Node2D

@onready var nav_region: NavigationRegion2D = $NavigationRegion2D
@onready var hud = $HUD

func _ready() -> void:
	GameManager.current_level = "level_isolation"
	GameManager.tank_connected = true
	_setup_navigation()
	await get_tree().create_timer(1.0).timeout
	if hud and hud.has_method("tank_says"):
		hud.tank_says("Neo, something's wrong. The signal is degrading...", 3.0)
		await get_tree().create_timer(5.0).timeout
		_trigger_disconnect()

func _trigger_disconnect() -> void:
	var camera = get_viewport().get_camera_2d()
	if camera:
		var original_offset = camera.offset
		for i in 15:
			camera.offset = original_offset + Vector2(randf_range(-4, 4), randf_range(-4, 4))
			await get_tree().create_timer(0.05).timeout
		camera.offset = original_offset
	GameManager.tank_connected = false
	if hud and hud.has_method("show_message"):
		hud.show_message("TANK", "Neo... signal jamming... [CONNECTION LOST]", 3.0)
	await get_tree().create_timer(4.0).timeout
	if hud and hud.has_method("show_message"):
		hud.show_message("SYSTEM", "Operator connection terminated.", 3.0)

func _setup_navigation() -> void:
	var verts := PackedVector2Array([
		Vector2(100, 100), Vector2(540, 100), Vector2(540, 500), Vector2(100, 500)
	])
	nav_region.navigation_polygon = GameManager.build_nav_poly(verts, [PackedInt32Array([0, 1, 2, 3])])

func _on_exit_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.load_next_level()
