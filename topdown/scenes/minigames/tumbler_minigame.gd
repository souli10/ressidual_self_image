extends MinigameBase

## Tumbler Protocol (unlock command)
## A timing bar sweeps left-right. Click when in the green zone.
## Must succeed 3 times in a row.

@onready var bar_bg: ColorRect = $BarBG
@onready var sweet_spot: ColorRect = $BarBG/SweetSpot
@onready var needle: ColorRect = $BarBG/Needle
@onready var progress_label: Label = $ProgressLabel
@onready var instruction_label: Label = $InstructionLabel

var needle_pos: float = 0.0  # 0.0 to 1.0
var needle_speed: float = 1.5
var needle_direction: float = 1.0
var successes: int = 0
var required_successes: int = 3
var sweet_spot_start: float = 0.0
var sweet_spot_width: float = 0.0
var is_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _begin() -> void:
	successes = 0
	is_active = true
	# Scale difficulty: faster needle, smaller sweet spot
	needle_speed = lerpf(1.2, 3.0, difficulty)
	sweet_spot_width = lerpf(0.25, 0.10, difficulty)
	_randomize_sweet_spot()
	_update_progress()
	instruction_label.text = "[ CLICK when the needle is in the GREEN zone ]"


func _process(delta: float) -> void:
	if not visible or not is_active:
		return

	# Move needle back and forth
	needle_pos += needle_speed * needle_direction * delta
	if needle_pos >= 1.0:
		needle_pos = 1.0
		needle_direction = -1.0
	elif needle_pos <= 0.0:
		needle_pos = 0.0
		needle_direction = 1.0

	# Update needle visual position
	var bar_width: float = bar_bg.size.x
	needle.position.x = needle_pos * (bar_width - needle.size.x)


func _input(event: InputEvent) -> void:
	if not visible or not is_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_click()
		get_viewport().set_input_as_handled()


func _on_click() -> void:
	# Check if needle is within sweet spot
	if needle_pos >= sweet_spot_start and needle_pos <= sweet_spot_start + sweet_spot_width:
		successes += 1
		_update_progress()
		if successes >= required_successes:
			is_active = false
			instruction_label.text = ">> TUMBLER CRACKED <<"
			await get_tree().create_timer(0.4).timeout
			minigame_won.emit()
		else:
			# Flash green and re-randomize
			needle.color = Color(0.0, 1.0, 0.0, 1.0)
			_randomize_sweet_spot()
			await get_tree().create_timer(0.15).timeout
			needle.color = Color(1.0, 1.0, 1.0, 1.0)
	else:
		# Miss — fail entire minigame
		is_active = false
		instruction_label.text = ">> TUMBLER JAMMED — HACK FAILED <<"
		needle.color = Color(1.0, 0.0, 0.0, 1.0)
		await get_tree().create_timer(0.5).timeout
		minigame_lost.emit()


func _randomize_sweet_spot() -> void:
	sweet_spot_start = randf_range(0.05, 0.95 - sweet_spot_width)
	# Update visual
	var bar_width: float = bar_bg.size.x
	sweet_spot.position.x = sweet_spot_start * bar_width
	sweet_spot.size.x = sweet_spot_width * bar_width


func _update_progress() -> void:
	progress_label.text = "TUMBLERS: %d / %d" % [successes, required_successes]
