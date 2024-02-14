extends Node


var ignore_list: Array = []
var impact_sounds: Array = []

func _ready():
	pass

func play(audio: AudioStream, volume=0.0, single=false) -> void:
	if not audio:
		return
	var flag = false
	if single:
		flag = stop(audio)
		if(flag):
			return
	for player in get_children():
		player = player as AudioStreamPlayer
		if not player.playing:
			player.stream = audio
			player.volume_db = volume
			player.play()
			break


func stop(audio: AudioStream) -> bool:
	var flag = false
	for player in get_children():
		player = player as AudioStreamPlayer
		if player.playing:
			for ignore_string in ignore_list:
				if ignore_string in audio.resource_path and not flag:
					flag = true
					continue
		player.stop()
	return flag
