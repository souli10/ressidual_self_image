extends Node

signal terminal_requested(target: Node)
signal hack_failed(pos: Vector2)
signal hack_succeeded(pos: Vector2)

var faith_percent: float = 0.0
var current_level: String = ""
var is_terminal_open: bool = false
var tank_connected: bool = true

var level_sequence: Array[String] = [
	"res://scenes/levels/tutorial_office.tscn",
	"res://scenes/levels/level_isolation.tscn",
	"res://scenes/levels/level_subway.tscn",
	"res://scenes/levels/level_boss.tscn",
	"res://scenes/levels/level_finale.tscn",
]
var current_level_index: int = 0

## Faith checkpoints per GDD:
## Level 1 (tutorial): 0%, Level 2 (isolation): 20%, Level 3 (subway): 40%
## Level 4 (boss): 60%, Level 5 (finale): 80% → completes at 100%
var faith_per_level: Array[float] = [0.0, 20.0, 40.0, 60.0, 80.0]


func pause_world() -> void:
	is_terminal_open = true
	get_tree().paused = true


func resume_world() -> void:
	is_terminal_open = false
	get_tree().paused = false


func request_terminal(target: Node) -> void:
	terminal_requested.emit(target)


func restart_level() -> void:
	resume_world()
	get_tree().reload_current_scene()


func start_new_game() -> void:
	current_level_index = 0
	faith_percent = 0.0
	tank_connected = true
	resume_world()
	print("[GameManager] Starting new game, loading: ", level_sequence[0])
	get_tree().call_deferred("change_scene_to_file", level_sequence[0])


func load_next_level() -> void:
	current_level_index += 1
	print("[GameManager] load_next_level called, index now: ", current_level_index, " / ", level_sequence.size())
	if current_level_index < level_sequence.size():
		# Set faith based on level checkpoint
		if current_level_index < faith_per_level.size():
			faith_percent = faith_per_level[current_level_index]
		else:
			faith_percent = clampf(faith_percent + Constants.FAITH_PER_LEVEL, 0.0, 100.0)
		resume_world()
		var next_scene: String = level_sequence[current_level_index]
		print("[GameManager] Loading level: ", next_scene)
		get_tree().call_deferred("change_scene_to_file", next_scene)
	else:
		# All levels complete — show game over screen
		print("[GameManager] All levels complete! Loading game over screen.")
		faith_percent = 100.0
		resume_world()
		get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/game_over_screen.tscn")


func load_level(level_name: String) -> void:
	resume_world()
	get_tree().change_scene_to_file(level_name)


func load_main_menu() -> void:
	current_level_index = 0
	faith_percent = 0.0
	tank_connected = true
	resume_world()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func get_cooldown() -> float:
	var t := faith_percent / 100.0
	return lerpf(Constants.DEFAULT_COOLDOWN, Constants.MIN_COOLDOWN, t)


func broadcast_hack_failure(pos: Vector2) -> void:
	hack_failed.emit(pos)


func broadcast_hack_success(pos: Vector2) -> void:
	hack_succeeded.emit(pos)


func build_nav_poly(verts: PackedVector2Array, polys: Array) -> NavigationPolygon:
	var nav_poly := NavigationPolygon.new()
	nav_poly.vertices = verts
	for p in polys:
		nav_poly.add_polygon(p as PackedInt32Array)
	return nav_poly


## Build a nav mesh for a level, automatically excluding areas around StaticBody2D objects.
## walkable_outline: PackedVector2Array defining the walkable boundary (counter-clockwise)
## level_root: the level Node2D — all StaticBody2D children will create navigation obstacles
func build_nav_for_level(walkable_outlines: Array, level_root: Node) -> NavigationPolygon:
	var nav_poly := NavigationPolygon.new()
	
	# Collect obstacle rects from all StaticBody2D children
	var obstacle_rects: Array[Rect2] = []
	var margin := 10.0
	for child in level_root.get_children():
		if child is StaticBody2D:
			var rect := _get_body_rect(child, margin)
			if rect.size.length() > 0:
				obstacle_rects.append(rect)
	
	# Add walkable outlines
	for outline: PackedVector2Array in walkable_outlines:
		nav_poly.add_outline(outline)
	
	# Add obstacle holes (counter-clockwise winding for holes in Godot 4)
	for rect in obstacle_rects:
		var hole := PackedVector2Array([
			Vector2(rect.end.x, rect.position.y),   # top-right
			rect.position,                            # top-left
			Vector2(rect.position.x, rect.end.y),    # bottom-left
			rect.end,                                 # bottom-right
		])
		nav_poly.add_outline(hole)
	
	nav_poly.make_polygons_from_outlines()
	
	# If make_polygons_from_outlines didn't produce results, fall back to simple outline
	if nav_poly.get_polygon_count() == 0:
		print("[GameManager] make_polygons_from_outlines produced no polygons, using fallback")
		nav_poly = NavigationPolygon.new()
		for outline: PackedVector2Array in walkable_outlines:
			nav_poly.add_outline(outline)
		nav_poly.make_polygons_from_outlines()
	
	# Final fallback — build from raw vertices like the old method
	if nav_poly.get_polygon_count() == 0:
		print("[GameManager] Fallback also failed, using raw polygon method")
		nav_poly = NavigationPolygon.new()
		if walkable_outlines.size() > 0:
			var verts: PackedVector2Array = walkable_outlines[0]
			nav_poly.vertices = verts
			var indices := PackedInt32Array()
			for i in verts.size():
				indices.append(i)
			nav_poly.add_polygon(indices)
	
	return nav_poly


## Get a bounding Rect2 for a StaticBody2D from its collision shape.
func _get_body_rect(body: StaticBody2D, margin: float = 0.0) -> Rect2:
	for child in body.get_children():
		if child is CollisionShape2D and child.shape:
			var pos: Vector2 = body.position + child.position
			if child.shape is RectangleShape2D:
				var half: Vector2 = (child.shape as RectangleShape2D).size / 2.0 + Vector2(margin, margin)
				return Rect2(pos - half, half * 2.0)
			elif child.shape is CircleShape2D:
				var r: float = (child.shape as CircleShape2D).radius + margin
				return Rect2(pos - Vector2(r, r), Vector2(r * 2, r * 2))
	return Rect2()
