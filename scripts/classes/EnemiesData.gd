extends Node

# Tabela de estatísticas baseadas no nome do inimigo
var stats = {
	"Slime": {
		"speed": 100,
		"health": 100
	},
	"Goblin": {
		"speed": 120,
		"health": 150
	},
	"Orc": {
		"speed": 80,
		"health": 200
	}
}

# Retorna as estatísticas para um determinado nome
func get_stats(objname: String) -> Dictionary:
	if stats.has(objname):
		return stats[objname].duplicate() # duplica para não modificar o original
	return {} # ou um valor padrão
