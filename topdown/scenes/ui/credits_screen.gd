extends Control

## Credits Screen — Terminal-style scrolling credits.

@onready var credits_text: RichTextLabel = $CenterContainer/CreditsVBox/CreditsText
@onready var back_label: Label = $BackLabel

var scroll_speed: float = 30.0
var can_go_back: bool = false


func _ready() -> void:
	can_go_back = false
	_build_credits()
	
	# Delay before allowing exit
	await get_tree().create_timer(1.0).timeout
	can_go_back = true
	var tween := create_tween()
	tween.tween_property(back_label, "modulate:a", 0.6, 0.5)


func _input(event: InputEvent) -> void:
	if not can_go_back:
		return
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _build_credits() -> void:
	credits_text.clear()
	credits_text.append_text("[center]")
	credits_text.append_text("[color=#00ff00][font_size=28]RESIDUAL SELF IMAGE[/font_size][/color]\n\n")
	credits_text.append_text("[color=#00cc00]A Matrix Narrative Experience[/color]\n\n")
	credits_text.append_text("[color=#008800]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]\n\n")
	credits_text.append_text("[color=#00ff00]DEVELOPMENT TEAM[/color]\n\n")
	credits_text.append_text("[color=#00cc00]Soulayman Haouari[/color]\n")
	credits_text.append_text("[color=#00cc00]Ricardo Pereira[/color]\n\n")
	credits_text.append_text("[color=#008800]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]\n\n")
	credits_text.append_text("[color=#00ff00]COURSE[/color]\n\n")
	credits_text.append_text("[color=#00cc00]Narrative and Videogames (NAVI)[/color]\n\n")
	credits_text.append_text("[color=#008800]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]\n\n")
	credits_text.append_text("[color=#00ff00]TOOLS[/color]\n\n")
	credits_text.append_text("[color=#00cc00]Godot Engine 4[/color]\n")
	credits_text.append_text("[color=#00cc00]Aseprite[/color]\n")
	credits_text.append_text("[color=#00cc00]GitHub[/color]\n\n")
	credits_text.append_text("[color=#008800]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]\n\n")
	credits_text.append_text("[color=#00ff00]INSPIRED BY[/color]\n\n")
	credits_text.append_text("[color=#00cc00]The Matrix (1999)[/color]\n")
	credits_text.append_text("[color=#00cc00]Directed by The Wachowskis[/color]\n\n")
	credits_text.append_text("[color=#008800]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]\n\n")
	credits_text.append_text("[color=#006600]\"There is no spoon.\"[/color]\n\n")
	credits_text.append_text("[/center]")
