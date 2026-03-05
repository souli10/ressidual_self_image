extends Node

## AudioManager
## Handles background music and global sound effects.

var music_player: AudioStreamPlayer
var sfx_player_footsteps: AudioStreamPlayer

var sfx_typing: AudioStreamPlayer
var sfx_door_open: AudioStreamPlayer
var sfx_printer: AudioStreamPlayer
var sfx_elevator: AudioStreamPlayer

var music_stream = preload("res://assets/audio/music/main_menu_and_credits.mp3")
var footsteps_stream = preload("res://assets/audio/sfx/freesound_community-concrete-footsteps-6752.mp3")

func _ready() -> void:
	# Keep processing even if the tree is paused (e.g., terminal open)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	music_player = AudioStreamPlayer.new()
	music_player.stream = music_stream
	music_player.bus = "Master"
	music_player.volume_db = -10.0
	add_child(music_player)
	
	sfx_player_footsteps = AudioStreamPlayer.new()
	sfx_player_footsteps.stream = footsteps_stream
	sfx_player_footsteps.bus = "Master"
	sfx_player_footsteps.volume_db = -5.0
	add_child(sfx_player_footsteps)
	
	sfx_typing = _create_sfx_player("res://assets/audio/sfx/618596__zrrion__typing-sounds-pc-1600-xt-keyboard.mp3", -8.0)
	sfx_door_open = _create_sfx_player("res://assets/audio/sfx/soundreality-opening-door-411632.mp3", 0.0)
	sfx_printer = _create_sfx_player("res://assets/audio/sfx/freesound_community-printer-25474.mp3", -5.0)
	sfx_elevator = _create_sfx_player("res://assets/audio/sfx/447876__deathscyp__elevator-arriving.wav", 0.0)
	
	# New assets
	sfx_elevator_door = _create_sfx_player("res://assets/audio/sfx/freesound_community-large-metal-lift-door-openingwav-14459.mp3", 0.0)
	sfx_pipeburst = _create_sfx_player("res://assets/audio/sfx/freesound_community-pipeburst-69945.mp3", 0.0)
	sfx_disconnect = _create_sfx_player("res://assets/audio/sfx/freesound_community-tuning-radio-7150.mp3", 0.0)
	
	play_music()

func _create_sfx_player(path: String, volume: float) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.stream = load(path)
	player.bus = "Master"
	player.volume_db = volume
	add_child(player)
	return player

func _play_with_timeout(player: AudioStreamPlayer, max_duration: float = 4.0) -> void:
	player.play()
	get_tree().create_timer(max_duration).timeout.connect(player.stop)

func play_music() -> void:
	if not music_player.playing:
		music_player.play()

func stop_music() -> void:
	music_player.stop()

func play_footsteps() -> void:
	if not sfx_player_footsteps.playing:
		sfx_player_footsteps.play()

func stop_footsteps() -> void:
	sfx_player_footsteps.stop()

func play_typing() -> void:
	# Small random pitch shift for variety
	sfx_typing.pitch_scale = randf_range(0.95, 1.05)
	sfx_typing.play()

func play_door_open() -> void:
	_play_with_timeout(sfx_door_open)

func play_printer() -> void:
	_play_with_timeout(sfx_printer)

func stop_printer() -> void:
	sfx_printer.stop()

func play_elevator() -> void:
	_play_with_timeout(sfx_elevator)

func play_elevator_door() -> void:
	_play_with_timeout(sfx_elevator_door)

func play_pipeburst() -> void:
	_play_with_timeout(sfx_pipeburst)

func play_disconnect() -> void:
	_play_with_timeout(sfx_disconnect)

func stop_all_sfx() -> void:
	sfx_player_footsteps.stop()
	sfx_typing.stop()
	sfx_door_open.stop()
	sfx_printer.stop()
	sfx_elevator.stop()
	if sfx_elevator_door: sfx_elevator_door.stop()
	if sfx_pipeburst: sfx_pipeburst.stop()
	if sfx_disconnect: sfx_disconnect.stop()

