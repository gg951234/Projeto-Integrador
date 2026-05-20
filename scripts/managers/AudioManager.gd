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

func tocar_sfx(sfx: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = sfx
	player.play()
	player.finished.connect(player.queue_free)

func set_volume(volume_db: float) -> void:
	_musica_player.volume_db = volume_db
