extends Node

signal terminal_requested(target: Node)
signal hack_failed(pos: Vector2)
signal agent_alert(pos: Vector2)

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


func load_next_level() -> void:
	current_level_index += 1
	if current_level_index < level_sequence.size():
		faith_percent = clampf(faith_percent + Constants.FAITH_PER_LEVEL, 0.0, 100.0)
		resume_world()
		get_tree().change_scene_to_file(level_sequence[current_level_index])
	else:
		print("=== GAME COMPLETE ===")


func load_level(level_name: String) -> void:
	resume_world()
	get_tree().change_scene_to_file(level_name)


func get_cooldown() -> float:
	var t := faith_percent / 100.0
	return lerpf(Constants.DEFAULT_COOLDOWN, Constants.MIN_COOLDOWN, t)


func broadcast_hack_failure(pos: Vector2) -> void:
	hack_failed.emit(pos)


func build_nav_poly(verts: PackedVector2Array, polys: Array) -> NavigationPolygon:
	var nav_poly := NavigationPolygon.new()
	nav_poly.vertices = verts
	for p in polys:
		nav_poly.add_polygon(p as PackedInt32Array)
	return nav_poly
