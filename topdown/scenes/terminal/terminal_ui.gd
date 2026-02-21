extends CanvasLayer

## Terminal UI — split panel: Inspector (left) + Console (right)
## Includes Trace Timer, minigame popup integration, and error/kick behavior.

@onready var overlay: ColorRect = $DarkOverlay
@onready var panel: PanelContainer = $TerminalPanel
@onready var inspector_label: RichTextLabel = $TerminalPanel/Margin/Layout/HSplit/InspectorPanel/InspectorContent
@onready var output_log: RichTextLabel = $TerminalPanel/Margin/Layout/HSplit/ConsolePanel/VBox/OutputLog
@onready var command_input: LineEdit = $TerminalPanel/Margin/Layout/HSplit/ConsolePanel/VBox/InputRow/CommandInput
@onready var target_label: Label = $TerminalPanel/Margin/Layout/HeaderRow/TargetLabel
@onready var trace_bar: ProgressBar = $TerminalPanel/Margin/Layout/HeaderRow/TraceBar

## Minigame popup (separate terminal-styled window)
@onready var minigame_popup: Node = $MinigamePopup

## Console area references
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
var minigame_active: bool = false
var pending_command: String = ""
var is_being_kicked: bool = false

## Reference to the panel's original border style for flash effect
var _normal_border_color: Color = Color(0.0, 0.6, 0.0, 1.0)
var _error_border_color: Color = Color(1.0, 0.0, 0.0, 1.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameManager.terminal_requested.connect(open)
	command_input.text_submitted.connect(_on_command_submitted)
	overlay.gui_input.connect(_on_overlay_clicked)
	_apply_terminal_style()
	
	# Connect to minigame popup signals
	if minigame_popup:
		minigame_popup.popup_won.connect(_on_minigame_won)
		minigame_popup.popup_lost.connect(_on_minigame_lost)


func _process(delta: float) -> void:
	if not visible or current_target == null:
		return
	# Only tick trace when no minigame is active
	if not minigame_active:
		trace_percent += trace_speed * delta
		trace_bar.value = trace_percent
		if trace_percent >= 100.0:
			_on_trace_detected()


func _on_overlay_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if not minigame_active and not is_being_kicked:
			close()


func open(target: Node) -> void:
	# Don't open if object is on cooldown
	if target.cooldown_remaining > 0.0:
		return
	
	current_target = target
	visible = true
	is_being_kicked = false
	trace_percent = 0.0
	trace_bar.value = 0.0
	trace_speed = lerpf(8.0, 15.0, GameManager.faith_percent / 100.0)
	pending_command = ""
	minigame_active = false

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
	command_input.text = ""
	command_input.editable = true
	input_row.visible = true
	command_input.grab_focus()
	GameManager.pause_world()


func close() -> void:
	if minigame_popup:
		minigame_popup.close_popup()
	minigame_active = false
	visible = false
	current_target = null
	trace_percent = 0.0
	pending_command = ""
	is_being_kicked = false
	GameManager.resume_world()


func _on_trace_detected() -> void:
	_kick_from_terminal("!!! TRACE DETECTED — CONNECTION SEVERED !!!")


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

	# --- Pre-validation ---
	if current_target.is_hacked:
		_print_line("[color=#ff4444]System already compromised.[/color]")
		return

	if current_target.cooldown_remaining > 0.0:
		_print_line("[color=#ff4444]System locked. Retry in %.1fs.[/color]" % current_target.cooldown_remaining)
		return

	var valid: PackedStringArray = current_target.get_valid_commands()
	if cmd not in valid:
		# Wrong command — error + kick from terminal
		current_target.cooldown_remaining = GameManager.get_cooldown()
		if current_target is Node2D:
			GameManager.broadcast_hack_failure(current_target.global_position)
		_kick_from_terminal("ERROR: ACCESS DENIED — INVALID COMMAND '%s'" % cmd)
		return

	# --- Valid command → launch minigame in popup ---
	pending_command = cmd
	_print_line("[color=#00ff00]INITIATING HACK PROTOCOL...[/color]")
	_print_line("")

	# Disable input — minigame takes over
	command_input.editable = false
	input_row.visible = false
	minigame_active = true

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

	# Open in the popup terminal window
	var diff := clampf(GameManager.faith_percent / 100.0 * 0.5, 0.0, 0.4)
	if minigame_popup:
		minigame_popup.open_minigame(scene, cmd, diff)


func _on_minigame_won() -> void:
	minigame_active = false
	input_row.visible = true
	command_input.editable = true
	# Execute the command
	if current_target and not current_target.is_hacked:
		current_target.on_hack_success(pending_command)
		_print_line("[color=#00ff00]SUCCESS: %s executed on %s.[/color]" % [pending_command, current_target.object_name])
		if current_target is Node2D:
			GameManager.broadcast_hack_success(current_target.global_position)
	await get_tree().create_timer(0.6).timeout
	close()


func _on_minigame_lost() -> void:
	minigame_active = false
	input_row.visible = true
	command_input.editable = true
	# Hack failed — kick from terminal with error
	if current_target:
		current_target.cooldown_remaining = GameManager.get_cooldown()
		if current_target is Node2D:
			GameManager.broadcast_hack_failure(current_target.global_position)
	_kick_from_terminal("HACK FAILED — SYSTEM LOCKOUT ENGAGED")


## Kick the player from the terminal with an error message and visual effect.
func _kick_from_terminal(error_msg: String) -> void:
	if is_being_kicked:
		return
	is_being_kicked = true
	
	# Close any active minigame popup
	if minigame_popup:
		minigame_popup.close_popup()
	minigame_active = false
	
	# Flash terminal border red
	_flash_border_red()
	
	# Display error
	_print_line("")
	_print_line("[color=#ff0000]!!! " + error_msg + " !!![/color]")
	_print_line("[color=#ff4444]> Terminal connection terminated.[/color]")
	_print_line("[color=#ff4444]> System locked. Cooldown active.[/color]")
	
	# Shake effect
	_shake_terminal()
	
	# Wait then close
	await get_tree().create_timer(1.2).timeout
	close()


func _flash_border_red() -> void:
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	# Flash red
	style.border_color = _error_border_color
	await get_tree().create_timer(0.15).timeout
	if panel:
		style.border_color = _normal_border_color
	await get_tree().create_timer(0.1).timeout
	if panel:
		style.border_color = _error_border_color
	await get_tree().create_timer(0.15).timeout
	if panel:
		style.border_color = _normal_border_color


func _shake_terminal() -> void:
	var original_pos := panel.position
	for i in 8:
		panel.position = original_pos + Vector2(randf_range(-6, 6), randf_range(-4, 4))
		await get_tree().create_timer(0.04).timeout
	panel.position = original_pos


func _print_line(bbcode: String) -> void:
	output_log.append_text(bbcode + "\n")


func _apply_terminal_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.05, 0.02, 0.95)
	style.border_color = _normal_border_color
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
