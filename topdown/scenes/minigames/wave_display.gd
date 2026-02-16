extends Control

## Custom drawing for the wave display — renders target and player sine waves.

var target_amplitude: float = 0.5
var player_amplitude: float = 0.3
var time_offset: float = 0.0


func _process(delta: float) -> void:
	time_offset += delta * 3.0


func _draw() -> void:
	var w := size.x
	var h := size.y
	var mid_y := h / 2.0
	var max_amp := h * 0.4

	# Draw target wave (dim green)
	var target_points: PackedVector2Array = []
	for i in range(int(w)):
		var x := float(i)
		var y := mid_y + sin((x / w) * TAU * 2.5 + time_offset) * target_amplitude * max_amp
		target_points.append(Vector2(x, y))
	if target_points.size() >= 2:
		draw_polyline(target_points, Color(0.0, 0.6, 0.0, 0.5), 2.0)

	# Draw player wave (bright green)
	var player_points: PackedVector2Array = []
	for i in range(int(w)):
		var x := float(i)
		var y := mid_y + sin((x / w) * TAU * 2.5 + time_offset) * player_amplitude * max_amp
		player_points.append(Vector2(x, y))
	if player_points.size() >= 2:
		draw_polyline(player_points, Color(0.0, 1.0, 0.0, 1.0), 2.0)

	# Draw center line
	draw_line(Vector2(0, mid_y), Vector2(w, mid_y), Color(0.0, 0.3, 0.0, 0.3), 1.0)
