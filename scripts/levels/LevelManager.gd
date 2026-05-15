extends Node

const FASES := [
	"res://scenes/levels/Level01_Geografia.tscn",
	"res://scenes/levels/Level02_Fisica.tscn",
	"res://scenes/levels/Level03_Matematica.tscn",
	"res://scenes/levels/Level04_Historia.tscn",
	"res://scenes/levels/Level05_Biologia.tscn",
	"res://scenes/levels/Level06_Filosofia.tscn",
	"res://scenes/levels/Level07_EducacaoFisica.tscn",
	"res://scenes/levels/Level08_Artes.tscn",
	"res://scenes/levels/Level09_Quimica.tscn",
	"res://scenes/levels/Level10_Portugues.tscn",
]

func carregar_fase(numero: int) -> void:
	var index := numero - 1
	if index >= 0 and index < FASES.size():
		get_tree().change_scene_to_file(FASES[index])

func proxima_fase() -> void:
	GameManager.avancar_fase()
	carregar_fase(GameManager.fase_atual)
