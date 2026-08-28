extends AudioStreamPlayer

# A dictionary to hold your game tracks for easy swapping
# [Replace the folder paths below with your actual sound file paths!]
var tracks = {
	"level_01": preload("res://sfx/Beyond Ocean Waters.mp3"),
}

# Function to play a specific song by its dictionary key name
func play_track(track_name: String) -> void:
	if tracks.has(track_name):
		# If the requested track is already playing, don't restart it
		if stream == tracks[track_name] and playing:
			return
			
		stream = tracks[track_name]
		play()
	else:
		push_error("Track name not found in MusicManager: " + track_name)

# Function to safely toggle pausing
func toggle_pause() -> void:
	stream_paused = !stream_paused

# Explicit pause and unpause functions
func pause_music() -> void:
	stream_paused = true

func unpause_music() -> void:
	stream_paused = false
