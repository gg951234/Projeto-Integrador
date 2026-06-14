extends Node

const SETTINGS_PATH := "user://settings.json"

var volumesfx: float = 1.0
var volumemusic: float = 1.0
var brightness: float = 1.0

func _ready() -> void:
	carregar()

func salvar() -> void:
	var dados := {"volumesfx": volumesfx,
	"volumemusic": volumemusic,
	"brightness": brightness,
	}
	var arquivo := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(JSON.stringify(dados))
		arquivo.close()

func carregar() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		print("Arquivo de configurações não existe")
		return
	var arquivo := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if arquivo:
		var dados = JSON.parse_string(arquivo.get_as_text())
		arquivo.close()
		if dados:
			volumesfx = dados.get("volumesfx", 1.0)
			volumemusic = dados.get("volumemusic", 1.0)
			brightness = dados.get("brightness", 1.0)

func get_configs() -> Dictionary:
	return {
		"volumesfx": volumesfx,
		"volumemusic": volumemusic,
		"brightness": brightness,
	}
