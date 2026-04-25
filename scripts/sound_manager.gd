extends Node

# Dictionary to store audio file paths for easy reference
var sounds = {
	"player-jump": "res://assets/sounds/player-jump.wav",
	"player-death": "res://assets/sounds/player-death.wav",
	"player-shoot": "res://assets/sounds/player-shoot.mp3",
	"collect-apple": "res://assets/sounds/collect-apple.wav",
	"enemy-hit": "res://assets/sounds/enemy-hit.wav",
	"enemy-death": "res://assets/sounds/enemy-death.wav",
	"music": "res://assets/sounds/music.ogg",
}

# Pool of AudioStreamPlayer2D instances for positional audio
var audio_players = []
const POOL_SIZE = 8


func _ready() -> void:
	# Initialize the audio player pool
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer2D.new()
		add_child(player)
		audio_players.append(player)


# Play a sound at a specific position (for positional audio)
func play_sound(sound_name: String, position: Vector2 = Vector2.ZERO, volume_db: float = 0.0) -> void:
	if sound_name not in sounds:
		push_error("Sound '%s' not found in sound manager" % sound_name)
		return
	
	var audio_player = _get_available_player()
	if audio_player == null:
		push_warning("Audio player pool exhausted, sound may be cut off")
		return
	
	audio_player.stream = load(sounds[sound_name])
	audio_player.global_position = position
	audio_player.volume_db = volume_db
	audio_player.play()


# Play a sound without positional audio (useful for UI sounds, etc.)
func play_sound_2d(sound_name: String, volume_db: float = 0.0) -> void:
	if sound_name not in sounds:
		push_error("Sound '%s' not found in sound manager" % sound_name)
		return
	
	var audio_player = _get_available_player()
	if audio_player == null:
		push_warning("Audio player pool exhausted, sound may be cut off")
		return
	
	audio_player.stream = load(sounds[sound_name])
	audio_player.volume_db = volume_db
	audio_player.play()


# Get an available audio player from the pool
func _get_available_player() -> AudioStreamPlayer2D:
	for player in audio_players:
		if not player.playing:
			return player
	
	# If no player is available, return null (could expand pool here if needed)
	return null
