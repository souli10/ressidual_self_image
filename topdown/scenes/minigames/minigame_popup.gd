extends CanvasLayer

## Minigame Popup — A large terminal-styled window that overlays the screen.
## Appears when a valid command is typed. Contains only the minigame.

signal popup_won
signal popup_lost

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $Panel
@onready var header_label: Label = $Panel/Margin/VBox/HeaderRow/HeaderLabel
@onready var command_label: Label = $Panel/Margin/VBox/HeaderRow/CommandLabel
@onready var separator: HSeparator = $Panel/Margin/VBox/Sep
@onready var game_container: Control = $Panel/Margin/VBox/GameContainer

var current_minigame: MinigameBase = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_apply_style()


func open_minigame(minigame_scene: PackedScene, command_name: String, diff: float) -> void:
	_remove_minigame()
	visible = true
	
	header_label.text = "MATRIX HACK PROTOCOL"
	command_label.text = "CMD: " + command_name.to_upper()
	
	current_minigame = minigame_scene.instantiate() as MinigameBase
	current_minigame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	current_minigame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_container.add_child(current_minigame)
	
	current_minigame.minigame_won.connect(_on_won)
	current_minigame.minigame_lost.connect(_on_lost)
	current_minigame.start_minigame(diff)


func close_popup() -> void:
	_remove_minigame()
	visible = false


func _on_won() -> void:
	_remove_minigame()
	visible = false
	popup_won.emit()


func _on_lost() -> void:
	_remove_minigame()
	visible = false
	popup_lost.emit()


func _remove_minigame() -> void:
	if current_minigame != null:
		current_minigame.queue_free()
		current_minigame = null


func _apply_style() -> void:
	# Panel style — same Matrix terminal look but bigger
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.06, 0.02, 0.97)
	style.border_color = Color(0.0, 0.7, 0.0, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)
