extends Node

var music_player: AudioStreamPlayer

var tracks = {
	"beyond_ocean_waters": preload("res://sfx/Beyond Ocean Waters.mp3")
}


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	play_track("beyond_ocean_waters")


func play_track(track_name: String) -> void:
	if not tracks.has(track_name):
		return

	if music_player.playing:
		return

	music_player.stream = tracks[track_name]
	music_player.play()
