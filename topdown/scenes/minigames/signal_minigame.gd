extends MinigameBase

## Signal Protocol (ping command)
## Two sine waves on screen. Player uses mouse scroll wheel to
## adjust amplitude until their wave matches the target wave.

@onready var instruction_label: Label = $InstructionLabel
@onready var wave_display: Control = $WaveDisplay
@onready var match_label: Label = $MatchLabel

var target_amplitude: float = 0.5
var player_amplitude: float = 0.3
var match_threshold: float = 0.05
var hold_time_required: float = 1.5
var hold_timer: float = 0.0
var is_active: bool = false
var time_elapsed: float = 0.0
var max_time: float = 12.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _begin() -> void:
	is_active = true
	hold_timer = 0.0
	time_elapsed = 0.0

	# Scale difficulty
	match_threshold = lerpf(0.08, 0.03, difficulty)
	hold_time_required = lerpf(1.0, 2.0, difficulty)
	max_time = lerpf(15.0, 8.0, difficulty)

	# Randomize target
	target_amplitude = randf_range(0.2, 0.9)
	player_amplitude = 0.5

	instruction_label.text = "[ SCROLL WHEEL to match the wave amplitude ]"
	_update_match_display()


func _process(delta: float) -> void:
	if not visible or not is_active:
		return

	time_elapsed += delta
	if time_elapsed >= max_time:
		_fail()
		return

	# Sync amplitudes to the wave display for rendering
	wave_display.target_amplitude = target_amplitude
	wave_display.player_amplitude = player_amplitude

	# Check if amplitudes match
	var diff := absf(player_amplitude - target_amplitude)
	if diff <= match_threshold:
		hold_timer += delta
		if hold_timer >= hold_time_required:
			_win()
			return
	else:
		hold_timer = maxf(hold_timer - delta * 2.0, 0.0)

	_update_match_display()
	wave_display.queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible or not is_active:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			player_amplitude = clampf(player_amplitude + 0.03, 0.05, 1.0)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			player_amplitude = clampf(player_amplitude - 0.03, 0.05, 1.0)
			get_viewport().set_input_as_handled()


func _update_match_display() -> void:
	var diff := absf(player_amplitude - target_amplitude)
	var match_pct := clampf(1.0 - (diff / 0.5), 0.0, 1.0) * 100.0
	var lock_pct := (hold_timer / hold_time_required) * 100.0
	match_label.text = "MATCH: %.0f%%  |  LOCK: %.0f%%  |  TIME: %.1fs" % [
		match_pct, lock_pct, max_time - time_elapsed
	]


func _win() -> void:
	is_active = false
	instruction_label.text = ">> SIGNAL LOCKED <<"
	await get_tree().create_timer(0.4).timeout
	minigame_won.emit()


func _fail() -> void:
	is_active = false
	instruction_label.text = ">> SIGNAL LOST — HACK FAILED <<"
	await get_tree().create_timer(0.5).timeout
	minigame_lost.emit()
