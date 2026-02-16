extends MinigameBase

## Stasis Protocol (stop command)
## Shows a sequence of colored data nodes. Player must click them
## in the exact order shown within a time limit.

@onready var instruction_label: Label = $InstructionLabel
@onready var progress_label: Label = $ProgressLabel
@onready var node_container: Control = $NodeContainer

var NODE_COLORS: Array[Color] = [
	Color(0.0, 1.0, 0.0, 1.0),   # green
	Color(0.0, 0.6, 1.0, 1.0),   # blue
	Color(1.0, 0.8, 0.0, 1.0),   # yellow
	Color(1.0, 0.0, 0.5, 1.0),   # pink
	Color(0.6, 0.0, 1.0, 1.0),   # purple
	Color(1.0, 0.4, 0.0, 1.0),   # orange
]

var sequence: Array[int] = []
var player_index: int = 0
var sequence_length: int = 4
var is_showing: bool = false
var is_active: bool = false
var show_timer: float = 0.0
var show_index: int = 0
var show_interval: float = 0.6
var buttons: Array[Button] = []
var time_limit: float = 10.0
var time_remaining: float = 10.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _begin() -> void:
	player_index = 0
	is_active = false
	is_showing = true
	show_index = 0
	show_timer = 0.8  # initial delay before showing

	# Scale difficulty
	sequence_length = int(lerpf(4, 7, difficulty))
	show_interval = lerpf(0.7, 0.4, difficulty)
	time_limit = lerpf(12.0, 6.0, difficulty)
	time_remaining = time_limit

	# Generate random sequence
	sequence.clear()
	for i in sequence_length:
		sequence.append(randi() % NODE_COLORS.size())

	# Create buttons in a grid
	_create_buttons()
	_update_progress()
	instruction_label.text = "[ MEMORIZE the sequence... ]"


func _process(delta: float) -> void:
	if not visible:
		return

	if is_showing:
		show_timer -= delta
		if show_timer <= 0.0:
			if show_index < sequence.size():
				_flash_button(sequence[show_index])
				show_index += 1
				show_timer = show_interval
			else:
				# Done showing — player's turn
				is_showing = false
				is_active = true
				_reset_all_buttons()
				instruction_label.text = "[ CLICK the nodes in the same ORDER ]"
		return

	if is_active:
		time_remaining -= delta
		_update_progress()
		if time_remaining <= 0.0:
			_fail()


func _create_buttons() -> void:
	# Clear old buttons
	for child in node_container.get_children():
		child.queue_free()
	buttons.clear()

	var cols := 3
	var spacing := 8.0
	var btn_size := Vector2(70, 40)

	for i in NODE_COLORS.size():
		var btn := Button.new()
		btn.custom_minimum_size = btn_size
		var col := i % cols
		var row := i / cols
		btn.position = Vector2(
			col * (btn_size.x + spacing) + 10,
			row * (btn_size.y + spacing) + 10
		)
		btn.text = "NODE %d" % i

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
		style.border_color = NODE_COLORS[i]
		style.set_border_width_all(2)
		btn.add_theme_stylebox_override("normal", style)

		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = NODE_COLORS[i] * 0.3
		hover_style.border_color = NODE_COLORS[i]
		hover_style.set_border_width_all(2)
		btn.add_theme_stylebox_override("hover", hover_style)

		btn.add_theme_color_override("font_color", NODE_COLORS[i])
		btn.pressed.connect(_on_node_pressed.bind(i))
		node_container.add_child(btn)
		buttons.append(btn)


func _flash_button(idx: int) -> void:
	_reset_all_buttons()
	if idx < buttons.size():
		var style := StyleBoxFlat.new()
		style.bg_color = NODE_COLORS[idx] * 0.8
		style.border_color = NODE_COLORS[idx]
		style.set_border_width_all(3)
		buttons[idx].add_theme_stylebox_override("normal", style)


func _reset_all_buttons() -> void:
	for i in buttons.size():
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
		style.border_color = NODE_COLORS[i]
		style.set_border_width_all(2)
		buttons[i].add_theme_stylebox_override("normal", style)


func _on_node_pressed(idx: int) -> void:
	if not is_active:
		return

	if idx == sequence[player_index]:
		# Correct!
		_flash_button(idx)
		player_index += 1
		_update_progress()
		if player_index >= sequence.size():
			_win()
	else:
		# Wrong — fail
		_fail()


func _win() -> void:
	is_active = false
	instruction_label.text = ">> SYSTEM FROZEN <<"
	await get_tree().create_timer(0.4).timeout
	minigame_won.emit()


func _fail() -> void:
	is_active = false
	instruction_label.text = ">> SEQUENCE ERROR — HACK FAILED <<"
	await get_tree().create_timer(0.5).timeout
	minigame_lost.emit()


func _update_progress() -> void:
	if is_showing:
		progress_label.text = "SHOWING SEQUENCE..."
	else:
		progress_label.text = "STEP: %d / %d  |  TIME: %.1fs" % [
			player_index, sequence.size(), time_remaining
		]
