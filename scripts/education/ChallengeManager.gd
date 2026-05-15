extends Node

var perguntas: Array = []
var indice_atual: int = 0

func carregar_fase(materia: String) -> void:
	var caminho := "res://data/questions/ materia
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	if arquivo:
		perguntas = JSON.parse_string(arquivo.get_as_text())
		arquivo.close()
	indice_atual = 0

func proxima_pergunta() -> Dictionary:
	if indice_atual < perguntas.size():
		var p := perguntas[indice_atual]
		indice_atual += 1
		return p
	return {}

func validar_resposta(pergunta: Dictionary, resposta: String) -> bool:
	return pergunta.get("resposta_correta", "") == resposta
