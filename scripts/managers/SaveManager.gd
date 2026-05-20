extends Node

const SAVE_PATH := "user://save.json"

func salvar() -> void:
	var dados := {
		"jogador_nome": GameManager.jogador_nome,
		"fase_atual": GameManager.fase_atual,
		"moedas": GameManager.moedas,
		"fases_desbloqueadas": GameManager.fases_desbloqueadas
	}
	var arquivo := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(JSON.stringify(dados))
		arquivo.close()

func carregar() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var arquivo := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if arquivo:
		var dados = JSON.parse_string(arquivo.get_as_text())
		arquivo.close()
		if dados:
			GameManager.jogador_nome = dados.get("jogador_nome", "")
			GameManager.fase_atual   = dados.get("fase_atual", 1)
			GameManager.moedas       = dados.get("moedas", 0)
			GameManager.fases_desbloqueadas = dados.get("fases_desbloqueadas", [1])
