extends Node

# Tabela de estatísticas baseadas no nome da arma
var stats = {
	"Default": {
		"health": 100,
		"speed": 300,
	},
	"Gold": {
		"health": 200,
		"speed": 350,
	},
	"Frost": {
		"health": 250,
		"speed": 400,
	},
	"Shadow": {
		"health": 300,
		"speed": 450,
	},
}

# Retorna as estatísticas para um determinado nome
func get_stats(objname: String) -> Dictionary:
	if stats.has(objname):
		return stats[objname].duplicate() # duplica para não modificar o original
	return {} # ou um valor padrão
