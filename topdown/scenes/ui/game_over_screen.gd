extends Control

## Game Over / Victory Screen — ROOT ACCESS ACHIEVED.

@onready var title_label: Label = $CenterVBox/TitleLabel
@onready var subtitle_label: RichTextLabel = $CenterVBox/SubtitleLabel
@onready var continue_label: Label = $ContinueLabel

var phase: int = 0


func _ready() -> void:
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	continue_label.modulate.a = 0.0
	_play_sequence()


func _input(event: InputEvent) -> void:
	if phase < 2:
		return
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		get_tree().change_scene_to_file("res://scenes/ui/credits_screen.tscn")


func _play_sequence() -> void:
	await get_tree().create_timer(1.0).timeout
	
	# Phase 1: Title fade in
	var tween1 := create_tween()
	tween1.tween_property(title_label, "modulate:a", 1.0, 2.0)
	await tween1.finished
	phase = 1
	
	await get_tree().create_timer(1.5).timeout
	
	# Phase 2: Subtitle
	subtitle_label.clear()
	subtitle_label.append_text("[center][color=#00ff00]")
	subtitle_label.append_text("The Matrix cannot hold you.\n\n")
	subtitle_label.append_text("You are [b]The One[/b].")
	subtitle_label.append_text("[/color][/center]")
	
	var tween2 := create_tween()
	tween2.tween_property(subtitle_label, "modulate:a", 1.0, 1.5)
	await tween2.finished
	
	await get_tree().create_timer(2.0).timeout
	phase = 2
	
	var tween3 := create_tween()
	tween3.tween_property(continue_label, "modulate:a", 0.6, 1.0)
