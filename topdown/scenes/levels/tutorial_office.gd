extends Node2D

@onready var nav_region: NavigationRegion2D = $NavigationRegion2D
@onready var hud = $HUD

func _ready() -> void:
	GameManager.current_level = "tutorial_office"
	GameManager.tank_connected = true
	_setup_navigation()
	await get_tree().create_timer(1.0).timeout
	if hud and hud.has_method("tank_says"):
		hud.tank_says("Neo, can you hear me? You need to get out of this building.", 3.0)
		await get_tree().create_timer(4.5).timeout
		hud.tank_says("Right-click on that door. Then type 'unlock' in the terminal.", 4.0)

func _setup_navigation() -> void:
	var verts := PackedVector2Array([
		Vector2(32, 32), Vector2(400, 32), Vector2(400, 260),
		Vector2(240, 260), Vector2(180, 260), Vector2(32, 260),
		Vector2(240, 300), Vector2(180, 300),
		Vector2(32, 300), Vector2(608, 300), Vector2(608, 500),
		Vector2(460, 500), Vector2(400, 500), Vector2(32, 500),
		Vector2(460, 540), Vector2(400, 540),
		Vector2(240, 540), Vector2(608, 540), Vector2(608, 720), Vector2(240, 720),
	])
	var polys: Array = [
		PackedInt32Array([0, 1, 2, 3, 4, 5]),
		PackedInt32Array([4, 3, 6, 7]),
		PackedInt32Array([8, 7, 6, 9, 10, 11, 12, 13]),
		PackedInt32Array([12, 11, 14, 15]),
		PackedInt32Array([16, 15, 14, 17, 18, 19]),
	]
	nav_region.navigation_polygon = GameManager.build_nav_poly(verts, polys)

func _on_exit_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if hud and hud.has_method("tank_says"):
			hud.tank_says("Good work, Neo. You're learning fast.", 2.0)
		await get_tree().create_timer(2.5).timeout
		GameManager.load_next_level()
