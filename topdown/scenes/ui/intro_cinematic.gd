extends Control

## Intro Cinematic — "Wake up, Neo..." typewriter sequence.

@onready var text_label: RichTextLabel = $CenterContainer/TextLabel
@onready var skip_label: Label = $SkipLabel

var lines: Array[Dictionary] = [
	{"text": "Wake up, Neo...", "delay": 2.0, "speed": 0.08},
	{"text": "The Matrix has you...", "delay": 2.0, "speed": 0.06},
	{"text": "Follow the white rabbit.", "delay": 2.0, "speed": 0.05},
	{"text": "Knock, knock, Neo.", "delay": 2.5, "speed": 0.07},
]

var is_playing: bool = true
var can_skip: bool = false


func _ready() -> void:
	text_label.clear()
	skip_label.modulate.a = 0.0
	_play_sequence()


func _input(event: InputEvent) -> void:
	if not can_skip:
		return
	if event is InputEventKey and event.pressed:
		_skip_to_game()
	elif event is InputEventMouseButton and event.pressed:
		_skip_to_game()


func _play_sequence() -> void:
	await get_tree().create_timer(1.0).timeout
	can_skip = true
	
	# Fade in skip hint
	var skip_tween := create_tween()
	skip_tween.tween_property(skip_label, "modulate:a", 0.5, 1.0)
	
	for line_data: Dictionary in lines:
		if not is_playing:
			return
		text_label.clear()
		var full_text: String = str(line_data["text"])
		var speed: float = line_data["speed"] as float
		var delay: float = line_data["delay"] as float
		
		for i in full_text.length():
			if not is_playing:
				return
			text_label.clear()
			text_label.append_text("[color=#00ff00]" + full_text.substr(0, i + 1) + "[/color]")
			await get_tree().create_timer(speed).timeout
		
		await get_tree().create_timer(delay).timeout
		
		# Fade out current line
		if is_playing:
			var fade := create_tween()
			fade.tween_property(text_label, "modulate:a", 0.0, 0.5)
			await fade.finished
			text_label.modulate.a = 1.0
			text_label.clear()
	
	if is_playing:
		_skip_to_game()


func _skip_to_game() -> void:
	if not is_playing:
		return
	is_playing = false
	
	# Fade to black then load level 1
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.3)
	await fade.finished
	
	GameManager.start_new_game()
