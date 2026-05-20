extends Node

const SETTINGS_PATH := "user://settings.json"

var volume: float = 1.0
var brilho: float = 1.0
var idioma: String = "pt_BR"

func _ready() -> void:
	carregar()

func salvar() -> void:
	var dados := {"volume": volume, "brilho": brilho, "idioma": idioma}
	var arquivo := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(JSON.stringify(dados))
		arquivo.close()

func carregar() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var arquivo := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if arquivo:
		var dados = JSON.parse_string(arquivo.get_as_text())
		arquivo.close()
		if dados:
			volume = dados.get("volume", 1.0)
			brilho = dados.get("brilho", 1.0)
			idioma = dados.get("idioma", "pt_BR")
