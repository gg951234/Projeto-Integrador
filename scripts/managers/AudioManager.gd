extends Node

var _musica_player: AudioStreamPlayer
var _musica_atual_path: String = ""
var _fade_tween: Tween
var _fade_duration: float = 0.5

func _ready() -> void:
	_musica_player = AudioStreamPlayer.new()
	add_child(_musica_player)
	_musica_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_musica_player.finished.connect(_musica_player.play)
	_fade_tween = create_tween()

# ------------------------------------------------------------------
# Música com fade
# ------------------------------------------------------------------
func tocar_musica(audio_path: String) -> void:
	if _musica_atual_path == audio_path and _musica_player.playing:
		return

	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	if _musica_player.playing:
		_fade_out_e_trocar(audio_path)
	else:
		_iniciar_nova_musica(audio_path)

func _fade_out_e_trocar(novo_caminho: String) -> void:
	_fade_tween = create_tween()
	_fade_tween.tween_property(_musica_player, "volume_db", -80.0, _fade_duration)
	_fade_tween.finished.connect(_on_fade_out_finished.bind(novo_caminho), CONNECT_ONE_SHOT)

func _on_fade_out_finished(novo_caminho: String) -> void:
	_musica_player.stop()
	_iniciar_nova_musica(novo_caminho)

func _iniciar_nova_musica(audio_path: String) -> void:
	var musica: AudioStream = load(audio_path)
	if musica == null:
		push_error("Música não encontrada: ", audio_path)
		return

	_musica_player.stream = musica
	_musica_player.volume_db = -80.0
	_musica_player.play()

	var alvo_db = get_volume_db(get_volumemusic())
	_fade_tween = create_tween()
	_fade_tween.tween_property(_musica_player, "volume_db", alvo_db, _fade_duration)

	_musica_atual_path = audio_path

# ------------------------------------------------------------------
#  NOVO: Atualiza o volume da música em tempo real (sem quebrar o fade)
# ------------------------------------------------------------------
func update_music_volume(linear_volume: float) -> void:
	# Só aplica se não houver um fade em andamento
	if _fade_tween == null or not _fade_tween.is_valid() or not _fade_tween.is_running():
		_musica_player.volume_db = get_volume_db(linear_volume)
	# Se houver fade, a atualização é ignorada – o fade termina com o volume corrente

func parar_musica() -> void:
	if _fade_tween and _fade_tween.is_valid(): 
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_musica_player, "volume_db", -80.0, _fade_duration)
	_fade_tween.finished.connect(_musica_player.stop, CONNECT_ONE_SHOT)

# ------------------------------------------------------------------
# SFX com posição
# ------------------------------------------------------------------
func tocar_sfx(pos: Vector2, audio_path: String, _properties: Dictionary = {}) -> void:
	var sfx: AudioStream = load(audio_path)
	if sfx == null:
		push_error("Áudio não encontrado: ", audio_path)
		return

	var container := Node2D.new()
	container.position = pos

	var audio := AudioStreamPlayer2D.new()
	audio.stream = sfx

	if _properties.get("Pitch"):
		audio.pitch_scale = _properties.get("Pitch")

	audio.volume_db = get_volume_db(get_volumesfx())

	container.add_child(audio)
	add_child(container)

	audio.play()
	# Conecta passando audio e container
	audio.finished.connect(_on_sfx_finished.bind(audio, container), CONNECT_ONE_SHOT)

# ------------------------------------------------------------------
# SFX global (sem container)
# ------------------------------------------------------------------
func tocar_sfxglobal(audio_path: String, _properties: Dictionary = {}) -> void:
	var sfx: AudioStream = load(audio_path)
	if sfx == null:
		push_error("Áudio não encontrado: ", audio_path)
		return

	var audio := AudioStreamPlayer.new()
	audio.stream = sfx
	audio.process_mode = Node.PROCESS_MODE_ALWAYS

	if _properties.get("Pitch"):
		audio.pitch_scale = _properties.get("Pitch")

	audio.volume_db = get_volume_db(get_volumesfx())

	add_child(audio)

	audio.play()
	audio.finished.connect(_on_sfx_global_finished.bind(audio), CONNECT_ONE_SHOT)

# ------------------------------------------------------------------
# Callbacks dos SFX
# ------------------------------------------------------------------
func _on_sfx_finished(audio: AudioStreamPlayer2D, container: Node2D) -> void:
	audio.queue_free()
	container.queue_free()

func _on_sfx_global_finished(audio: AudioStreamPlayer) -> void:
	audio.queue_free()

# ------------------------------------------------------------------
# Utilitários de volume
# ------------------------------------------------------------------
func get_volume_db(volume: float) -> float:
	var ganho_linear = volume / 5.0
	if ganho_linear <= 0.0:
		return -80.0
	return linear_to_db(ganho_linear)

func get_volumesfx() -> float:
	return get_tree().root.get_node("Main/UI/Settings").get_configs()["volumesfx"]

func get_volumemusic() -> float:
	return get_tree().root.get_node("Main/UI/Settings").get_configs()["volumemusic"]
