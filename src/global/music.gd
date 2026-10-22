extends AudioStreamPlayer

# TODO: Use this in places that should use this
func play_song(song:String):
	stream = load(song)
	play()
