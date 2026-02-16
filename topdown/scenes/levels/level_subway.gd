extends Node2D

@onready var nav_region: NavigationRegion2D = $NavigationRegion2D
@onready var hud = $HUD

func _ready() -> void:
	GameManager.current_level = "level_subway"
	GameManager.tank_connected = false
	_setup_navigation()
	_setup_agent_patrol()
	await get_tree().create_timer(1.5).timeout
	if hud and hud.has_method("show_message"):
		hud.show_message("SYSTEM", "Security camera detected. Use 'stop' to freeze it.", 4.0)

func _setup_navigation() -> void:
	var verts := PackedVector2Array([
		Vector2(32, 150), Vector2(608, 150), Vector2(608, 450), Vector2(32, 450)
	])
	nav_region.navigation_polygon = GameManager.build_nav_poly(verts, [PackedInt32Array([0, 1, 2, 3])])

func _setup_agent_patrol() -> void:
	if has_node("Agent"):
		$Agent.patrol_points = [Vector2(150, 300), Vector2(500, 300), Vector2(500, 200), Vector2(150, 200)]

func _on_exit_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.load_next_level()
