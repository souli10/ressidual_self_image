extends Node2D

@onready var nav_region: NavigationRegion2D = $NavigationRegion2D
@onready var hud = $HUD

func _ready() -> void:
	GameManager.current_level = "level_boss"
	GameManager.tank_connected = false
	_setup_navigation()
	_setup_agent_patrol()
	await get_tree().create_timer(1.5).timeout
	if hud and hud.has_method("show_message"):
		hud.show_message("SYSTEM", "High-security area. Standard commands may fail.", 4.0)

func _setup_navigation() -> void:
	var verts := PackedVector2Array([
		Vector2(60, 60), Vector2(400, 60), Vector2(400, 250),
		Vector2(200, 250), Vector2(60, 250),
		Vector2(580, 250), Vector2(580, 500), Vector2(200, 500),
	])
	var polys: Array = [PackedInt32Array([0, 1, 2, 3, 4]), PackedInt32Array([3, 2, 5, 6, 7])]
	nav_region.navigation_polygon = GameManager.build_nav_poly(verts, polys)

func _setup_agent_patrol() -> void:
	if has_node("Agent"):
		$Agent.patrol_points = [Vector2(300, 300), Vector2(500, 300), Vector2(500, 450), Vector2(300, 450)]

func _on_exit_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.load_next_level()
