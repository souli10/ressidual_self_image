extends CanvasLayer

## HUD — Faith progress bar and Tank dialogue box.

@onready var faith_bar: ProgressBar = $HUDContainer/VBox/TopRow/FaithBar
@onready var faith_label: Label = $HUDContainer/VBox/TopRow/FaithLabel
@onready var dialogue_panel: PanelContainer = $HUDContainer/VBox/DialoguePanel
@onready var dialogue_label: RichTextLabel = $HUDContainer/VBox/DialoguePanel/DialogueMargin/DialogueVBox/DialogueText
@onready var speaker_label: Label = $HUDContainer/VBox/DialoguePanel/DialogueMargin/DialogueVBox/SpeakerLabel

var dialogue_queue: Array[Dictionary] = []
var is_showing_dialogue: bool = false
var typewriter_speed: float = 0.03


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	dialogue_panel.visible = false
	_update_faith_display()


func _process(_delta: float) -> void:
	_update_faith_display()


func _update_faith_display() -> void:
	faith_bar.value = GameManager.faith_percent
	faith_label.text = "FAITH: %d%%" % int(GameManager.faith_percent)


func show_message(speaker: String, text: String, duration: float = 4.0) -> void:
	dialogue_queue.append({
		"speaker": speaker,
		"text": text,
		"duration": duration,
	})
	if not is_showing_dialogue:
		_show_next_dialogue()


func _show_next_dialogue() -> void:
	if dialogue_queue.is_empty():
		is_showing_dialogue = false
		dialogue_panel.visible = false
		return

	is_showing_dialogue = true
	var msg: Dictionary = dialogue_queue.pop_front()
	dialogue_panel.visible = true
	speaker_label.text = str(msg.speaker) + ":"
	dialogue_label.clear()

	# Typewriter effect
	var full_text: String = str(msg.text)
	for i in full_text.length():
		dialogue_label.clear()
		dialogue_label.append_text("[color=#00ff00]" + full_text.substr(0, i + 1) + "[/color]")
		await get_tree().create_timer(typewriter_speed).timeout

	await get_tree().create_timer(msg.duration).timeout
	_show_next_dialogue()


func tank_says(text: String, duration: float = 3.0) -> void:
	if GameManager.tank_connected:
		show_message("TANK", text, duration)
