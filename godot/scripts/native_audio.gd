extends RefCounted
## Original procedural PCM effects. Finite voices clean themselves up; no audio downloads.

var controller: Node
var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer3D] = []
const RATE: int = 22050
const SOUNDS: Dictionary = {
	"fire": [720.0, 155.0, 0.12, 0.24],
	"shotgun_fire": [110.0, 28.0, 0.30, 0.38],
	"rifle_fire": [520.0, 65.0, 0.16, 0.23],
	"smg_fire": [1050.0, 90.0, 0.075, 0.19],
	"hit": [190.0, 48.0, 0.18, 0.22],
	"reload": [880.0, 310.0, 0.18, 0.10],
	"detect": [510.0, 1030.0, 0.22, 0.10],
	"attack": [90.0, 280.0, 0.26, 0.10],
	"impact": [1100.0, 120.0, 0.07, 0.12],
	"damage": [150.0, 32.0, 0.23, 0.20],
	"use": [620.0, 1230.0, 0.18, 0.12],
	"alarm": [330.0, 610.0, 0.40, 0.10],
	"step": [85.0, 45.0, 0.055, 0.06]
}

func setup(main: Node) -> void:
	controller = main

func play(kind: String, at: Vector3 = Vector3.INF) -> void:
	if not controller or not SOUNDS.has(kind):
		return
	_prune()
	var preferences: Dictionary = _preferences()
	if bool(preferences.get("muted", false)) or float(preferences.get("volume", 0.65)) <= 0:
		return
	if not _streams.has(kind):
		_streams[kind] = _make_stream(SOUNDS[kind])
	if _voices.size() >= 24:
		var oldest: AudioStreamPlayer3D = _voices.pop_front()
		if is_instance_valid(oldest):
			oldest.stop()
			oldest.stream = null
			oldest.queue_free()
	var voice := AudioStreamPlayer3D.new()
	voice.name = "Sound_" + kind
	voice.process_mode = Node.PROCESS_MODE_PAUSABLE
	voice.stream = _streams[kind]
	voice.unit_size = 6.667
	voice.max_distance = 40
	voice.volume_db = linear_to_db(clampf(float(preferences.get("volume", 0.65)), 0.0001, 1))
	controller.add_child(voice)
	var player: Node3D = controller.get("player")
	voice.global_position = player.global_position + Vector3(0, 1.4, 0) if at == Vector3.INF else at + Vector3(0, 1.4, 0)
	voice.finished.connect(voice.queue_free)
	_voices.append(voice)
	voice.play()

func refresh_volume() -> void:
	_prune()
	var preferences: Dictionary = _preferences()
	var volume: float = 0.0 if bool(preferences.get("muted", false)) else float(preferences.get("volume", 0.65))
	for voice: AudioStreamPlayer3D in _voices:
		voice.volume_db = -80 if volume <= 0 else linear_to_db(clampf(volume, 0.0001, 1))

func stop_all() -> void:
	for voice: AudioStreamPlayer3D in _voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
			voice.queue_free()
	_voices.clear()

func shutdown() -> void:
	stop_all()
	_streams.clear()
	controller = null

func _prune() -> void:
	var alive: Array[AudioStreamPlayer3D] = []
	for voice: AudioStreamPlayer3D in _voices:
		if is_instance_valid(voice) and not voice.is_queued_for_deletion():
			alive.append(voice)
	_voices = alive

func _preferences() -> Dictionary:
	var session: RefCounted = controller.get("session") if controller else null
	return session.get("preferences") if session else {}

func _make_stream(spec: Array) -> AudioStreamWAV:
	var start_frequency: float = spec[0]
	var end_frequency: float = spec[1]
	var duration: float = spec[2]
	var gain: float = spec[3]
	var samples: int = ceili(duration * RATE)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	var phase: float = 0
	for i in samples:
		var progress: float = float(i) / samples
		var frequency: float = lerpf(start_frequency, end_frequency, progress)
		phase += TAU * frequency / RATE
		var envelope: float = minf(float(i) / (RATE * 0.008), 1.0) * pow(1.0 - progress, 2)
		var sample: float = (sin(phase) + sin(phase * 2.013) * 0.22) * gain * envelope
		bytes.encode_s16(i * 2, int(clampf(sample, -1, 1) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	return stream
