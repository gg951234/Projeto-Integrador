extends Node

# Tabela de estatísticas baseadas no nome do inimigo
var stats = {
	"Weak Book": {
		"scene": "res://scenes/enemies/weakbook.tscn",
		"speed": 100,
		"health": 30,
		"damage": 5,
		"kb": 100,
		"attackcd": 2.0,
	},
	"Novice Book": {
		"scene": "res://scenes/enemies/novicebook.tscn",
		"speed": 105,
		"health": 55,
		"damage": 10,
		"kb": 120,
		"attackcd": 1.8,
	},
	"Adept Book": {
		"scene": "res://scenes/enemies/adeptbook.tscn",
		"speed": 110,
		"health": 85,
		"damage": 15,
		"kb": 150,
		"attackcd": 1.6,
	},
	"Expert Book": {
		"scene": "res://scenes/enemies/expertbook.tscn",
		"speed": 115,
		"health": 125,
		"damage": 20,
		"kb": 180,
		"attackcd": 1.4,
	},
	"Master Book": {
		"scene": "res://scenes/enemies/masterbook.tscn",
		"speed": 120,
		"health": 180,
		"damage": 30,
		"kb": 220,
		"attackcd": 1.2,
	},
	"Legend Book": {
		"scene": "res://scenes/enemies/legendbook.tscn",
		"speed": 125,
		"health": 250,
		"damage": 50,
		"kb": 280,
		"attackcd": 1.0,
	},
}

# Retorna as estatísticas para um determinado nome
func get_stats(objname: String) -> Dictionary:
	if stats.has(objname):
		return stats[objname].duplicate() # duplica para não modificar o original
	return {} # ou um valor padrão
