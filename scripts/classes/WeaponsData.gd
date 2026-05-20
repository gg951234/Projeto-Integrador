extends Node

# Tabela de estatísticas baseadas no nome da arma
var stats = {
	"Bat": {
		"damage": 10,
		"kb": 100
	},
	"Sword": {
		"damage": 20,
		"kb": 100
	},
}

# Retorna as estatísticas para um determinado nome
func get_stats(objname: String) -> Dictionary:
	if stats.has(objname):
		return stats[objname].duplicate() # duplica para não modificar o original
	return {} # ou um valor padrão
