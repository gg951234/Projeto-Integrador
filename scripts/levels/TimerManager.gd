extends Node

signal tempo_esgotado

const TEMPO_LIMITE := 300.0
var tempo_restante: float = TEMPO_LIMITE
var _ativo: bool = false

func iniciar() -> void:
	tempo_restante = TEMPO_LIMITE
	_ativo = true

func pausar() -> void:
	_ativo = false

func _process(delta: float) -> void:
	if not _ativo:
		return
	tempo_restante -= delta
	if tempo_restante <= 0.0:
		tempo_restante = 0.0
		_ativo = false
		emit_signal("tempo_esgotado")

func get_formatado() -> String:
	var m := int(tempo_restante) / 60
	var s := int(tempo_restante)  60
	return ""C:\Users\newst\OneDrive\Documentos\TERCEIRO PERIODO\PI 1\setup_heroi_maze.bat"2d:"C:\Users\newst\OneDrive\Documentos\TERCEIRO PERIODO\PI 1\setup_heroi_maze.bat"2d"  [m, s]
