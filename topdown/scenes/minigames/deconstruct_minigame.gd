extends MinigameBase

## Deconstruction Protocol (delete command)
## Red malicious code blocks fall from the top. Click them to destroy
## before they reach the bottom. Survive until the counter reaches zero.

@onready var game_area: Control = $GameArea
@onready var instruction_label: Label = $InstructionLabel
@onready var progress_label: Label = $ProgressLabel

var blocks_to_destroy: int = 8
var blocks_destroyed: int = 0
var blocks_missed: int = 0
var max_misses: int = 3
var spawn_timer: float = 0.0
var spawn_interval: float = 0.8
var fall_speed: float = 120.0
var is_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _begin() -> void:
	blocks_destroyed = 0
	blocks_missed = 0
	is_active = true
	spawn_timer = 0.0

	# Scale difficulty
	spawn_interval = lerpf(1.0, 0.4, difficulty)
	fall_speed = lerpf(100.0, 220.0, difficulty)
	blocks_to_destroy = int(lerpf(6, 14, difficulty))
	max_misses = int(lerpf(3, 2, difficulty))

	_update_progress()
	instruction_label.text = "[ CLICK the RED blocks before they reach the bottom ]"


func _process(delta: float) -> void:
	if not visible or not is_active:
		return

	# Spawn new blocks
	spawn_timer -= delta
	if spawn_timer <= 0.0 and blocks_destroyed < blocks_to_destroy:
		_spawn_block()
		spawn_timer = spawn_interval

	# Move blocks downward
	for block in game_area.get_children():
		block.position.y += fall_speed * delta
		# Check if block fell past the bottom
		if block.position.y > game_area.size.y:
			block.queue_free()
			blocks_missed += 1
			_update_progress()
			if blocks_missed >= max_misses:
				_fail()
				return

	# Check win condition
	if blocks_destroyed >= blocks_to_destroy:
		_win()


func _spawn_block() -> void:
	var block := Button.new()
	block.custom_minimum_size = Vector2(50, 22)
	var block_width := 50.0
	block.position = Vector2(randf_range(10, game_area.size.x - block_width - 10), -30.0)
	block.text = _random_code_fragment()
	block.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	block.add_theme_color_override("font_hover_color", Color(1.0, 0.5, 0.5, 1.0))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.4, 0.0, 0.0, 0.9)
	style.border_color = Color(1.0, 0.0, 0.0, 0.8)
	style.set_border_width_all(1)
	block.add_theme_stylebox_override("normal", style)
	block.add_theme_stylebox_override("hover", style)

	block.pressed.connect(_on_block_clicked.bind(block))
	game_area.add_child(block)


func _on_block_clicked(block: Button) -> void:
	if not is_active:
		return
	# Destroy effect
	block.queue_free()
	blocks_destroyed += 1
	_update_progress()


func _random_code_fragment() -> String:
	var fragments: Array[String] = [
		"0xDEAD", "0xBEEF", "VIRUS", "WORM",
		"TRACE", "INJECT", "0xFF", "CORRUPT",
		"MALWR", "ROOTKIT", "SPOOF", "EXPLOIT",
	]
	return fragments[randi() % fragments.size()]


func _win() -> void:
	is_active = false
	# Clear remaining blocks
	for block in game_area.get_children():
		block.queue_free()
	instruction_label.text = ">> CODE PURGED <<"
	await get_tree().create_timer(0.4).timeout
	minigame_won.emit()


func _fail() -> void:
	is_active = false
	for block in game_area.get_children():
		block.queue_free()
	instruction_label.text = ">> SYSTEM CORRUPTED — HACK FAILED <<"
	await get_tree().create_timer(0.5).timeout
	minigame_lost.emit()


func _update_progress() -> void:
	progress_label.text = "PURGED: %d / %d  |  BREACHES: %d / %d" % [
		blocks_destroyed, blocks_to_destroy, blocks_missed, max_misses
	]
