extends Node2D

@onready var nav_region: NavigationRegion2D = $NavigationRegion2D
@onready var hud = $HUD

var level_active: bool = true


func _ready() -> void:
	GameManager.current_level = "level_boss"
	GameManager.tank_connected = false
	level_active = true
	_setup_navigation()
	_setup_agent_patrol()
	await get_tree().create_timer(1.5).timeout
	if not level_active or not is_inside_tree():
		return
	if hud and hud.has_method("show_message"):
		hud.show_message("SYSTEM", "High-security area. Standard commands may fail.", 4.0)

func _setup_navigation() -> void:
	var outline := PackedVector2Array([
		Vector2(60, 60), Vector2(400, 60), Vector2(400, 250),
		Vector2(580, 250), Vector2(580, 500),
		Vector2(200, 500), Vector2(200, 250),
		Vector2(60, 250),
	])
	nav_region.navigation_polygon = GameManager.build_nav_for_level([outline], self)

func _setup_agent_patrol() -> void:
	if has_node("Agent"):
		var pts: Array[Vector2] = [Vector2(300, 300), Vector2(500, 300), Vector2(500, 450), Vector2(300, 450)]
		$Agent.patrol_points = pts

func _on_exit_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and level_active:
		level_active = false
		GameManager.load_next_level()
