extends AudioStreamGenerator
class_name AudioStreamPd

export(String, FILE, "*.pd") var patch
export(float) var interval

var playback: AudioStreamPlayback = null
var updater: Timer
var pdstream: PdStream = null
		
func setup(player: Node):
	pdstream = PdStream.new()
	pdstream.create(64)
	pdstream.open(patch)
	pdstream.flot("distance", 1.0)
		
	playback = player.get_stream_playback()
	_fill_buffer()
	
	updater = Timer.new()
	player.call_deferred("add_child", updater)
	updater.autostart = true
	updater.connect("timeout", self, "elapsed")
	updater.wait_time = interval
	
	player.call_deferred("play")
	
func elapsed():
	_fill_buffer()

func _fill_buffer():
	var available = playback.get_frames_available()
	var ticks = int(ceil(max(1, available/64.0)))
	var frames = pdstream.perform(ticks)
	var counter = 0
	while available > 0:
		playback.push_frame(frames[counter]) # Audio frames are stereo.
		counter = counter + 1
		available = available - 1
