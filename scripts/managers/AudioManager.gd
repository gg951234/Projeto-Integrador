extends Node

var _musica_player: AudioStreamPlayer

func _ready() -> void:
	_musica_player = AudioStreamPlayer.new()
	add_child(_musica_player)

func tocar_musica(faixa: AudioStream) -> void:
	if _musica_player.stream == faixa:
		return
	_musica_player.stream = faixa
	_musica_player.play()

func parar_musica() -> void:
	_musica_player.stop()

func tocar_sfx(pos: Vector2, audio_path: String, _properties: Dictionary = {}) -> void:
	# Carrega o recurso de áudio a partir do caminho
	var sfx: AudioStream = load(audio_path)
	if sfx == null:
		push_error("Áudio não encontrado: ", audio_path)
		return
	
	# Cria container e posiciona
	var container := Node2D.new()
	container.position = pos
	
	var audio := AudioStreamPlayer2D.new()
	audio.stream = sfx
	
	if _properties.get("Volume"):
		audio.volume_db = _properties.get("Volume")
	if _properties.get("Pitch"):
		audio.pitch_scale = _properties.get("Pitch")
	
	audio.volume_db = get_volumesfx_db()
	
	container.add_child(audio)
	add_child(container)
	
	audio.play()
	audio.finished.connect(func():
		audio.queue_free()
		container.queue_free()
	)

func get_volumesfx_db() -> float:
	var ganho_linear = get_volumesfx() / 5.0
	if ganho_linear <= 0.0:
		return -80.0   # silêncio prático
	return linear_to_db(ganho_linear)

func get_volumesfx() -> float:
	return SettingsManager.get_configs()["volumesfx"]
