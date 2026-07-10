extends Node
## Autoload "Sfx" — efeitos sonoros sintetizados em runtime (sem assets).
## Uso: Sfx.tocar("hit" | "click" | "coin" | "ko" | "win" | "lose" | "reveal")

const MIX_RATE := 22050
var _sons: Dictionary = {}
var _players: Array = []


func _ready() -> void:
	for i in 4:  # pequenas pools para sons simultâneos
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_players.append(p)
	_sons["click"] = _tom([[880.0, 0.05]], 0.4)
	_sons["coin"] = _tom([[1320.0, 0.07], [1760.0, 0.1]], 0.5)
	_sons["reveal"] = _varredura(400.0, 950.0, 0.2, 0.5)
	_sons["hit"] = _ruido(0.13, 0.8)
	_sons["ko"] = _varredura(300.0, 60.0, 0.35, 0.7)
	_sons["win"] = _tom([[523.25, 0.12], [659.25, 0.12], [783.99, 0.12], [1046.5, 0.3]], 0.5)
	_sons["lose"] = _tom([[392.0, 0.2], [311.13, 0.2], [261.63, 0.35]], 0.5)


func tocar(nome: String) -> void:
	if not _sons.has(nome):
		return
	for p in _players:
		if not p.playing:
			p.stream = _sons[nome]
			p.play()
			return
	_players[0].stream = _sons[nome]
	_players[0].play()


## Sequência de tons senoidais [freq, duração].
func _tom(notas: Array, volume: float) -> AudioStreamWAV:
	var amostras := PackedFloat32Array()
	for nota in notas:
		var freq: float = nota[0]
		var dur: float = nota[1]
		var n := int(dur * MIX_RATE)
		for i in n:
			var t := float(i) / MIX_RATE
			var env := 1.0 - float(i) / n  # decaimento linear por nota
			amostras.append(sin(TAU * freq * t) * env * volume)
	return _para_wav(amostras)


func _varredura(f0: float, f1: float, dur: float, volume: float) -> AudioStreamWAV:
	var amostras := PackedFloat32Array()
	var n := int(dur * MIX_RATE)
	var fase := 0.0
	for i in n:
		var frac := float(i) / n
		var freq := lerpf(f0, f1, frac)
		fase += TAU * freq / MIX_RATE
		amostras.append(sin(fase) * (1.0 - frac) * volume)
	return _para_wav(amostras)


func _ruido(dur: float, volume: float) -> AudioStreamWAV:
	var amostras := PackedFloat32Array()
	var n := int(dur * MIX_RATE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in n:
		var env := pow(1.0 - float(i) / n, 2.0)
		amostras.append(rng.randf_range(-1.0, 1.0) * env * volume)
	return _para_wav(amostras)


func _para_wav(amostras: PackedFloat32Array) -> AudioStreamWAV:
	var dados := PackedByteArray()
	dados.resize(amostras.size() * 2)
	for i in amostras.size():
		var v := int(clampf(amostras[i], -1.0, 1.0) * 32767.0)
		dados.encode_s16(i * 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.data = dados
	return wav
