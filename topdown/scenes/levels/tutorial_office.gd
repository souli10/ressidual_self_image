extends Node2D

@onready var nav_region: NavigationRegion2D = $NavigationRegion2D
@onready var hud = $HUD

var level_active: bool = true


func _ready() -> void:
	GameManager.current_level = "tutorial_office"
	GameManager.tank_connected = true
	level_active = true
	_setup_navigation()
	await get_tree().create_timer(1.0).timeout
	if not level_active or not is_inside_tree():
		return
	if hud and hud.has_method("tank_says"):
		hud.tank_says("Neo, can you hear me? You need to get out of this building.", 3.0)
		await get_tree().create_timer(4.5).timeout
		if not level_active or not is_inside_tree():
			return
		hud.tank_says("Right-click on that door. Then type 'unlock' in the terminal.", 4.0)

func _setup_navigation() -> void:
	# Define walkable area outlines (counter-clockwise)
	var room1 := PackedVector2Array([
		Vector2(32, 32), Vector2(400, 32), Vector2(400, 260), Vector2(32, 260)
	])
	var hallway1 := PackedVector2Array([
		Vector2(180, 260), Vector2(240, 260), Vector2(240, 300), Vector2(180, 300)
	])
	var room2 := PackedVector2Array([
		Vector2(32, 300), Vector2(608, 300), Vector2(608, 500), Vector2(32, 500)
	])
	var hallway2 := PackedVector2Array([
		Vector2(400, 500), Vector2(460, 500), Vector2(460, 540), Vector2(400, 540)
	])
	var room3 := PackedVector2Array([
		Vector2(240, 540), Vector2(608, 540), Vector2(608, 720), Vector2(240, 720)
	])
	# Merge into single walkable outline covering all rooms
	var full_outline := PackedVector2Array([
		Vector2(32, 32), Vector2(400, 32), Vector2(400, 260),
		Vector2(240, 260), Vector2(240, 300),
		Vector2(608, 300), Vector2(608, 500),
		Vector2(460, 500), Vector2(460, 540),
		Vector2(608, 540), Vector2(608, 720),
		Vector2(240, 720), Vector2(240, 540),
		Vector2(400, 540), Vector2(400, 500),
		Vector2(32, 500), Vector2(32, 300),
		Vector2(180, 300), Vector2(180, 260),
		Vector2(32, 260),
	])
	nav_region.navigation_polygon = GameManager.build_nav_for_level([full_outline], self)

func _on_exit_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and level_active:
		level_active = false
		if hud and hud.has_method("tank_says"):
			hud.tank_says("Good work, Neo. You're learning fast.", 2.0)
		await get_tree().create_timer(2.5).timeout
		if not is_inside_tree():
			return
		GameManager.load_next_level()
