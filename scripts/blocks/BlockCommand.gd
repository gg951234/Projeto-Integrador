extends Node

enum TipoComando { MOVER, GIRAR, REPETIR }

var tipo: TipoComando
var valor: int = 1

func executar(jogador: CharacterBody2D) -> void:
	pass
