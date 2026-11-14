extends AudioStreamPlayer


const RATE: = 22050
const BEAT: = 0.6

var _events: = [

	{"m": 67, "s": 0.0, "d": 0.5}, {"m": 67, "s": 0.5, "d": 0.5}, 
	{"m": 69, "s": 1.0, "d": 1.0}, {"m": 67, "s": 2.0, "d": 1.0}, 
	{"m": 72, "s": 3.0, "d": 1.0}, {"m": 71, "s": 4.0, "d": 2.0}, 

	{"m": 67, "s": 6.0, "d": 0.5}, {"m": 67, "s": 6.5, "d": 0.5}, 
	{"m": 69, "s": 7.0, "d": 1.0}, {"m": 67, "s": 8.0, "d": 1.0}, 
	{"m": 74, "s": 9.0, "d": 1.0}, {"m": 72, "s": 10.0, "d": 2.0}, 

	{"m": 67, "s": 12.0, "d": 0.5}, {"m": 67, "s": 12.5, "d": 0.5}, 
	{"m": 79, "s": 13.0, "d": 1.0}, {"m": 76, "s": 14.0, "d": 1.0}, 
	{"m": 72, "s": 15.0, "d": 1.0}, {"m": 71, "s": 16.0, "d": 1.0}, 
	{"m": 69, "s": 17.0, "d": 2.0}, 

	{"m": 77, "s": 19.0, "d": 0.5}, {"m": 77, "s": 19.5, "d": 0.5}, 
	{"m": 76, "s": 20.0, "d": 1.0}, {"m": 72, "s": 21.0, "d": 1.0}, 
	{"m": 74, "s": 22.0, "d": 1.0}, {"m": 72, "s": 23.0, "d": 2.0}, 
]
var _chord_roots: = [60, 60, 65, 67, 60, 60, 67, 65, 60, 60, 67, 72, 67, 65, 60, 60]

func _ready() -> void :
	volume_db = -7.0
	stream = _make_stream()
	play()

func _freq(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)

func _make_stream() -> AudioStreamWAV:
	var total_beats: = 25.0
	var frames: = int(RATE * BEAT * total_beats)
	var data: = PackedByteArray()
	data.resize(frames * 4)
	var idx: = 0
	var ev_i: = 0
	for f in range(frames):
		var t: = float(f) / float(RATE)
		var beat: = t / BEAT
		while ev_i < _events.size() - 1 and beat >= float(_events[ev_i]["s"]) + float(_events[ev_i]["d"]):
			ev_i += 1
		var ev: Dictionary = _events[ev_i]
		var local: float = t - float(ev["s"]) * BEAT
		var env: = 0.0
		if local >= 0.0:
			env = minf(1.0, local * 90.0) * exp(-3.2 * local)
		var freq: = _freq(float(ev["m"]))
		var bell: = sin(TAU * freq * t) * 0.55
		bell += sin(TAU * freq * 2.0 * t) * 0.15
		bell += sin(TAU * freq * 3.0 * t) * 0.05
		bell *= env
		var chord_step: = int(beat / 2.0) % _chord_roots.size()
		var root: = float(_chord_roots[chord_step])
		var pad: = sin(TAU * _freq(root) * t) * 0.045
		pad += sin(TAU * _freq(root + 7.0) * t) * 0.03
		pad += sin(TAU * _freq(root + 12.0) * t) * 0.02
		var sample: = (bell * 0.34 + pad) * 0.9
		sample = clampf(sample, -0.8, 0.8)
		var v: = int(sample * 32767.0)
		if v < 0:
			v += 65536
		data[idx] = v & 255
		data[idx + 1] = (v >> 8) & 255
		data[idx + 2] = v & 255
		data[idx + 3] = (v >> 8) & 255
		idx += 4
	var wav: = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = true
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = frames
	return wav
