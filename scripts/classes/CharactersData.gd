extends Node

# Tabela de estatísticas baseadas no nome da arma
var stats = {
	"Default": {
		"health": 100,
		"speed": 300,
		"damage": 10,
		"kb": 100,
		"hitbox": {
				"Down":  { "pos": Vector2(0,  -8), "size": Vector2(128, 64) },
				"Up":    { "pos": Vector2(0, -12), "size": Vector2(128, 64) },
				"Right": { "pos": Vector2(4, -20), "size": Vector2(120, 72) },
				"Left":  { "pos": Vector2(-4, -20), "size": Vector2(120, 72) },
		}
	},
	"Frost": {
		"health": 200,
		"speed": 350,
		"damage": 20,
		"kb": 100,
		"hitbox": {
				"Down":  { "pos": Vector2(0,  32), "size": Vector2(128, 64) },
				"Up":    { "pos": Vector2(0, -12), "size": Vector2(128, 64) },
				"Right": { "pos": Vector2(4, 20), "size": Vector2(120, 72) },
				"Left":  { "pos": Vector2(-4, 20), "size": Vector2(120, 72) },
		}
	},
	"Shadow": {
		"health": 300,
		"speed": 400,
		"damage": 30,
		"kb": 100,
		"hitbox": {
				"Down":  { "pos": Vector2(0,  32), "size": Vector2(128, 64) },
				"Up":    { "pos": Vector2(0, -12), "size": Vector2(128, 64) },
				"Right": { "pos": Vector2(4, 20), "size": Vector2(120, 72) },
				"Left":  { "pos": Vector2(-4, 20), "size": Vector2(120, 72) },
		}
	},
	"Gold": {
		"health": 500,
		"speed": 450,
		"damage": 50,
		"kb": 100,
		"hitbox": {
				"Down":  { "pos": Vector2(0,  32), "size": Vector2(128, 64) },
				"Up":    { "pos": Vector2(0, -12), "size": Vector2(128, 64) },
				"Right": { "pos": Vector2(4, 20), "size": Vector2(120, 72) },
				"Left":  { "pos": Vector2(-4, 20), "size": Vector2(120, 72) },
		}
	},
}

# Retorna as estatísticas para um determinado nome
func get_stats(objname: String) -> Dictionary:
	if stats.has(objname):
		return stats[objname].duplicate() # duplica para não modificar o original
	return {} # ou um valor padrão

# Retorna as estatísticas da hitbox para um determinado nome
func get_hitbox(objname: String) -> Dictionary:
	if stats.has(objname):
		return stats[objname]["hitbox"].duplicate() # duplica para não modificar o original
	return {} # ou um valor padrão
