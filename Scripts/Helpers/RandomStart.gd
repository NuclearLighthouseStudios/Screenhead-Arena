extends AudioStreamPlayer3D

func _ready():
	if autoplay:
		play(randf()*stream.get_length())
	else:
		seek(randf()*stream.get_length())