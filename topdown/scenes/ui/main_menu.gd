extends Control

## Main Menu — Matrix rain background, title, and buttons.

@onready var rain_container: Control = $RainContainer
@onready var title_label: Label = $VBoxCenter/TitleLabel
@onready var subtitle_label: Label = $VBoxCenter/SubtitleLabel
@onready var btn_start: Button = $VBoxCenter/ButtonBox/BtnStart
@onready var btn_credits: Button = $VBoxCenter/ButtonBox/BtnCredits
@onready var btn_quit: Button = $VBoxCenter/ButtonBox/BtnQuit

var rain_columns: Array[Label] = []
var rain_chars: String = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789"
var rain_timer: float = 0.0
const RAIN_INTERVAL: float = 0.06
const RAIN_COLUMNS: int = 50

var title_visible: bool = false
var fade_timer: float = 0.0


func _ready() -> void:
	_setup_rain()
	_setup_buttons()
	_animate_title()


func _process(delta: float) -> void:
	rain_timer += delta
	if rain_timer >= RAIN_INTERVAL:
		rain_timer = 0.0
		_update_rain()


func _setup_rain() -> void:
	for i in RAIN_COLUMNS:
		var col := Label.new()
		col.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		col.add_theme_color_override("font_color", Color(0.0, 0.6, 0.0, 0.5))
		col.add_theme_font_size_override("font_size", 14)
		col.position = Vector2(i * 26, -randf_range(0, 400))
		col.size = Vector2(26, 900)
		col.clip_text = true
		col.text = ""
		for _j in 40:
			col.text += rain_chars[randi() % rain_chars.length()] + "\n"
		rain_container.add_child(col)
		rain_columns.append(col)


func _update_rain() -> void:
	for col in rain_columns:
		col.position.y += 4
		if col.position.y > 800:
			col.position.y = -randf_range(200, 600)
			col.text = ""
			for _j in 40:
				col.text += rain_chars[randi() % rain_chars.length()] + "\n"


func _setup_buttons() -> void:
	btn_start.pressed.connect(_on_start)
	btn_credits.pressed.connect(_on_credits)
	btn_quit.pressed.connect(_on_quit)
	
	for btn: Button in [btn_start, btn_credits, btn_quit]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.0, 0.1, 0.0, 0.8)
		style.border_color = Color(0.0, 0.6, 0.0, 1.0)
		style.set_border_width_all(2)
		style.set_corner_radius_all(0)
		style.set_content_margin_all(10)
		btn.add_theme_stylebox_override("normal", style)
		
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.0, 0.3, 0.0, 0.9)
		hover_style.border_color = Color(0.0, 1.0, 0.0, 1.0)
		hover_style.set_border_width_all(2)
		hover_style.set_corner_radius_all(0)
		hover_style.set_content_margin_all(10)
		btn.add_theme_stylebox_override("hover", hover_style)
		
		var pressed_style := StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.0, 0.5, 0.0, 1.0)
		pressed_style.border_color = Color(0.0, 1.0, 0.0, 1.0)
		pressed_style.set_border_width_all(2)
		pressed_style.set_corner_radius_all(0)
		pressed_style.set_content_margin_all(10)
		btn.add_theme_stylebox_override("pressed", pressed_style)
		
		btn.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
		btn.add_theme_color_override("font_hover_color", Color(0.5, 1.0, 0.5))
		btn.add_theme_font_size_override("font_size", 18)


func _animate_title() -> void:
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	btn_start.modulate.a = 0.0
	btn_credits.modulate.a = 0.0
	btn_quit.modulate.a = 0.0
	
	var tween := create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 1.5).set_delay(0.5)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 1.0).set_delay(0.3)
	tween.tween_property(btn_start, "modulate:a", 1.0, 0.5).set_delay(0.2)
	tween.tween_property(btn_credits, "modulate:a", 1.0, 0.5).set_delay(0.1)
	tween.tween_property(btn_quit, "modulate:a", 1.0, 0.5).set_delay(0.1)


func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/intro_cinematic.tscn")


func _on_credits() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/credits_screen.tscn")


func _on_quit() -> void:
	get_tree().quit()
