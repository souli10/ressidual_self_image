extends CanvasLayer

## Terminal UI — split panel: Inspector (left) + Console (right)
## Includes Trace Timer and minigame integration.

@onready var overlay: ColorRect = $DarkOverlay
@onready var panel: PanelContainer = $TerminalPanel
@onready var inspector_label: RichTextLabel = $TerminalPanel/Margin/Layout/HSplit/InspectorPanel/InspectorContent
@onready var output_log: RichTextLabel = $TerminalPanel/Margin/Layout/HSplit/ConsolePanel/VBox/OutputLog
@onready var command_input: LineEdit = $TerminalPanel/Margin/Layout/HSplit/ConsolePanel/VBox/InputRow/CommandInput
@onready var target_label: Label = $TerminalPanel/Margin/Layout/HeaderRow/TargetLabel
@onready var trace_bar: ProgressBar = $TerminalPanel/Margin/Layout/HeaderRow/TraceBar

## Minigame container — we'll add minigames as children of the console area
@onready var console_vbox: VBoxContainer = $TerminalPanel/Margin/Layout/HSplit/ConsolePanel/VBox
@onready var input_row: HBoxContainer = $TerminalPanel/Margin/Layout/HSplit/ConsolePanel/VBox/InputRow

## Preloaded minigame scenes
var tumbler_scene: PackedScene = preload("res://scenes/minigames/tumbler_minigame.tscn")
var deconstruct_scene: PackedScene = preload("res://scenes/minigames/deconstruct_minigame.tscn")
var signal_scene: PackedScene = preload("res://scenes/minigames/signal_minigame.tscn")
var stasis_scene: PackedScene = preload("res://scenes/minigames/stasis_minigame.tscn")

var current_target: Node = null
var trace_percent: float = 0.0
var trace_speed: float = 8.0
var current_minigame: MinigameBase = null
var pending_command: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameManager.terminal_requested.connect(open)
	command_input.text_submitted.connect(_on_command_submitted)
	overlay.gui_input.connect(_on_overlay_clicked)
	_apply_terminal_style()


func _process(delta: float) -> void:
	if not visible or current_target == null:
		return
	# Only tick trace when no minigame is active (minigame has its own pressure)
	if current_minigame == null:
		trace_percent += trace_speed * delta
		trace_bar.value = trace_percent
		if trace_percent >= 100.0:
			_on_trace_detected()


func _on_overlay_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if current_minigame == null:
			close()


func open(target: Node) -> void:
	current_target = target
	visible = true
	trace_percent = 0.0
	trace_bar.value = 0.0
	trace_speed = lerpf(8.0, 15.0, GameManager.faith_percent / 100.0)
	pending_command = ""

	output_log.clear()
	target_label.text = "TARGET: " + target.object_name

	# Inspector view
	inspector_label.clear()
	inspector_label.append_text("[color=#00ff00]// Object Inspector[/color]\n\n")
	inspector_label.append_text("[color=#00cc00]" + target.hack_description + "[/color]\n\n")
	inspector_label.append_text("[color=#008800]// Status: ")
	if target.is_hacked:
		inspector_label.append_text("COMPROMISED[/color]\n")
	else:
		inspector_label.append_text("ACTIVE[/color]\n")

	# Console
	_print_line("[color=#00ff00]>>> Connected to %s <<<[/color]" % target.object_name)
	_print_line("")
	_print_line("Valid commands: " + ", ".join(target.get_valid_commands()))
	if GameManager.tank_connected:
		_print_line("[color=#888888]TANK: Try typing one of those commands.[/color]")
	_print_line("")

	# Reset input area
	_remove_active_minigame()
	command_input.text = ""
	command_input.editable = true
	input_row.visible = true
	command_input.grab_focus()
	GameManager.pause_world()


func close() -> void:
	_remove_active_minigame()
	visible = false
	current_target = null
	trace_percent = 0.0
	pending_command = ""
	GameManager.resume_world()


func _on_trace_detected() -> void:
	_print_line("[color=#ff0000]!!! TRACE DETECTED — CONNECTION SEVERED !!![/color]")
	if current_target:
		current_target.cooldown_remaining = GameManager.get_cooldown()
		if current_target is Node2D:
			GameManager.broadcast_hack_failure(current_target.global_position)
	await get_tree().create_timer(0.5).timeout
	close()


func _on_command_submitted(text: String) -> void:
	var cmd := text.strip_edges().to_lower()
	command_input.text = ""
	if cmd.is_empty():
		return

	_print_line("[color=#888888]> " + cmd + "[/color]")

	if cmd == "exit" or cmd == "quit":
		close()
		return

	if current_target == null:
		_print_line("[color=#ff4444]ERROR: No target connected.[/color]")
		return

	# --- Pre-validation (same as before) ---
	if current_target.is_hacked:
		_print_line("[color=#ff4444]System already compromised.[/color]")
		return

	if current_target.cooldown_remaining > 0.0:
		_print_line("[color=#ff4444]System locked. Retry in %.1fs.[/color]" % current_target.cooldown_remaining)
		return

	var valid: PackedStringArray = current_target.get_valid_commands()
	if cmd not in valid:
		current_target.cooldown_remaining = GameManager.get_cooldown()
		if current_target is Node2D:
			GameManager.broadcast_hack_failure(current_target.global_position)
		_print_line("[color=#ff4444]ERROR: Command '%s' rejected. System locked for %.0fs.[/color]" % [cmd, current_target.cooldown_remaining])
		return

	# --- Valid command → launch minigame ---
	pending_command = cmd
	_print_line("[color=#00ff00]INITIATING HACK PROTOCOL...[/color]")
	_print_line("")

	# Hide input row and show the minigame
	command_input.editable = false
	input_row.visible = false

	_launch_minigame(cmd)


func _launch_minigame(cmd: String) -> void:
	var scene: PackedScene = null
	match cmd:
		"unlock":
			scene = tumbler_scene
		"delete":
			scene = deconstruct_scene
		"ping":
			scene = signal_scene
		"stop":
			scene = stasis_scene

	if scene == null:
		# Fallback: instant execution (for any future commands)
		_on_minigame_won()
		return

	current_minigame = scene.instantiate() as MinigameBase
	current_minigame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	current_minigame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	console_vbox.add_child(current_minigame)

	# Connect signals
	current_minigame.minigame_won.connect(_on_minigame_won)
	current_minigame.minigame_lost.connect(_on_minigame_lost)

	# Difficulty scales with faith (more faith = harder minigames, but shorter cooldowns)
	var diff := GameManager.faith_percent / 100.0
	current_minigame.start_minigame(diff)


func _on_minigame_won() -> void:
	_remove_active_minigame()
	# Execute the command
	if current_target and not current_target.is_hacked:
		current_target.on_hack_success(pending_command)
		_print_line("[color=#00ff00]SUCCESS: %s executed on %s.[/color]" % [pending_command, current_target.object_name])
	await get_tree().create_timer(0.6).timeout
	close()


func _on_minigame_lost() -> void:
	_remove_active_minigame()
	_print_line("[color=#ff0000]HACK FAILED — System lockout engaged.[/color]")
	if current_target:
		current_target.cooldown_remaining = GameManager.get_cooldown()
		if current_target is Node2D:
			GameManager.broadcast_hack_failure(current_target.global_position)
	await get_tree().create_timer(0.6).timeout
	close()


func _remove_active_minigame() -> void:
	if current_minigame != null:
		current_minigame.queue_free()
		current_minigame = null
	# Restore input row
	input_row.visible = true
	command_input.editable = true


func _print_line(bbcode: String) -> void:
	output_log.append_text(bbcode + "\n")


func _apply_terminal_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.05, 0.02, 0.95)
	style.border_color = Color(0.0, 0.6, 0.0, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)

	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color(0.0, 0.08, 0.0, 1.0)
	input_style.border_color = Color(0.0, 0.4, 0.0, 1.0)
	input_style.set_border_width_all(1)
	command_input.add_theme_stylebox_override("normal", input_style)
	command_input.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	command_input.add_theme_color_override("caret_color", Color(0.0, 1.0, 0.0))
