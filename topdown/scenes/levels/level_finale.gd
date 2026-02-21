extends Node2D

@onready var nav_region: NavigationRegion2D = $NavigationRegion2D
@onready var hud = $HUD
@onready var fog_overlay: CanvasModulate = $FogOverlay

var fog_active: bool = false
var level_active: bool = true


func _ready() -> void:
	GameManager.current_level = "level_finale"
	GameManager.tank_connected = true
	level_active = true
	_setup_navigation()
	fog_overlay.visible = false
	await get_tree().create_timer(1.0).timeout
	if not level_active or not is_inside_tree():
		return
	if hud and hud.has_method("tank_says"):
		hud.tank_says("Neo! I'm back. Hardline is across the street.", 3.0)
		await get_tree().create_timer(4.0).timeout
		if not level_active or not is_inside_tree():
			return
		hud.tank_says("There's a sniper on the roof. Find the steam valve.", 3.0)

func _setup_navigation() -> void:
	var outline := PackedVector2Array([
		Vector2(32, 100), Vector2(608, 100), Vector2(608, 500), Vector2(32, 500)
	])
	nav_region.navigation_polygon = GameManager.build_nav_for_level([outline], self)

func activate_fog() -> void:
	fog_active = true
	fog_overlay.visible = true
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var light = PointLight2D.new()
		light.texture = preload("res://assets/vfx/steam_particle.png")
		light.texture_scale = 8.0
		light.color = Color(0.2, 0.8, 0.2, 0.6)
		light.energy = 1.5
		players[0].add_child(light)
	if hud and hud.has_method("tank_says"):
		hud.tank_says("The fog is up! Run to the phone!", 3.0)

func _on_phone_reached(body: Node2D) -> void:
	if body.is_in_group("player") and level_active:
		level_active = false
		# Stop the agent so it can't restart the level during the victory sequence
		var agent = get_node_or_null("Agent")
		if agent:
			agent.set_physics_process(false)
			agent.velocity = Vector2.ZERO
		if hud and hud.has_method("show_message"):
			hud.show_message("SYSTEM", "EXIT PROTOCOL INITIATED...", 2.0)
			await get_tree().create_timer(2.5).timeout
			if not is_inside_tree():
				return
			hud.show_message("SYSTEM", "ROOT ACCESS ACHIEVED.", 4.0)
			await get_tree().create_timer(5.0).timeout
			if not is_inside_tree():
				return
		GameManager.load_next_level()
