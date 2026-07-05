extends Node

# Tabela de estatísticas baseadas no nome da arma
var stats = {
	"Bat": {
		"damage": 10,
		"kb": 100,
		"hitbox": {
				"Down":  { "pos": Vector2(0,  32), "size": Vector2(128, 64) },
				"Up":    { "pos": Vector2(0, -12), "size": Vector2(128, 64) },
				"Right": { "pos": Vector2(4, 20), "size": Vector2(120, 72) },
				"Left":  { "pos": Vector2(-4, 20), "size": Vector2(120, 72) },
		}
	},
	"Sword": {
		"damage": 2000,
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
