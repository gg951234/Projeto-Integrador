extends Node

var fase_atual: int = 1
var moedas: int = 0
var jogador_nome: String = ""
var fases_desbloqueadas: Array = [1]

func avancar_fase() -> void:
	fase_atual += 1
	if fase_atual not in fases_desbloqueadas:
		fases_desbloqueadas.append(fase_atual)
	SaveManager.salvar()

func adicionar_moedas(quantidade: int) -> void:
	moedas += quantidade
	SaveManager.salvar()
