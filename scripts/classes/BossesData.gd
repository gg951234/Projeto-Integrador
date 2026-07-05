extends Node

var stats = {
	"Golem": {
		"health": 500, # Vida (ex: 800)
		"skill_pattern": [1], # Ordem das skills (ex: [1,2,1,2,3])
		"diesound": "res://assets/sounds/bosses/Golem/GolemDie.mp3",
		"skills": { # Skills e seus parâmetros { id: { parâmetros necessários } }
			1: {
				"cooldown": 5.0,
				"damage": 20, # Dano
				"knockback": 150, # Knockback
				"count": 16, # Quantidade
				"square_size": 1300, # Distância máxima
				"delay": 1.0, # Delay pra spawnar após o preview
				"impact_scale": 3.0, # Tamanho
			}
		}
	},
	"ByBy": {
		"health": 500, # Vida (ex: 800)
		"skill_pattern": [1], # Ordem das skills (ex: [1,2,1,2,3])
		"diesound": "res://assets/sounds/bosses/ByBy/ByByDie.mp3",
		"skills": { # Skills e seus parâmetros { id: { parâmetros necessários } }
			1: {
				"cooldown": 5.0,
				"damage": 20, # Dano
				"knockback": 150, # Knockback
				"count": 16, # Quantidade
				"square_size": 1300, # Distância máxima
				"delay": 1.0, # Delay pra spawnar após o preview
				"impact_scale": 3.0, # Tamanho
			}
		}
	},
	"Cartagon": {
		"health": 500, # Vida (ex: 800)
		"skill_pattern": [1], # Ordem das skills (ex: [1,2,1,2,3])
		"diesound": "res://assets/sounds/bosses/Cartagon/CartagonDie.mp3",
		"skills": { # Skills e seus parâmetros { id: { parâmetros necessários } }
			1: {
				"cooldown": 5.0,
				"damage": 20, # Dano
				"knockback": 150, # Knockback
				"count": 16, # Quantidade
				"square_size": 1300, # Distância máxima
				"delay": 1.0, # Delay pra spawnar após o preview
				"impact_scale": 3.0, # Tamanho
			}
		}
	},
}

# Retorna as estatísticas para um determinado nome
func get_stats(objname: String) -> Dictionary:
	if stats.has(objname):
		return stats[objname].duplicate(true) # duplica para não modificar o original (true pra deep copy)
	return {} # ou um valor padrão
