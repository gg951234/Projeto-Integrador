extends Node

# Tabela de estatísticas baseadas no nome do inimigo
var stats = {
	"Slime": {
		"scene": "res://scenes/enemies/slime.tscn",
		"speed": 100,
		"health": 100,
		"damage": 20,
		"kb": 100,
		"attackcd": 2.0,
	},
	"Goblin": {
		"scene": "res://scenes/enemies/goblin.tscn",
		"speed": 120,
		"health": 150,
		"damage": 25,
		"kb": 100,
		"attackcd": 1.5,
	},
	"Orc": {
		"scene": "res://scenes/enemies/orc.tscn",
		"speed": 80,
		"health": 200,
		"damage": 40,
		"kb": 300,
		"attackcd": 4.0,
	}
}

# Retorna as estatísticas para um determinado nome
func get_stats(objname: String) -> Dictionary:
	if stats.has(objname):
		return stats[objname].duplicate() # duplica para não modificar o original
	return {} # ou um valor padrão
