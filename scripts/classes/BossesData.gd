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
		"skill_pattern": [2,1,1], # Ordem das skills (ex: [1,2,1,2,3])
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
			},
			2: {
				"cooldown": 6.0,
				"lines": 6,
				"damage": 15,
				"knockback": 65,
				"square_size": 1048,
				"delay": 1.5,
				"line_thickness": 32
			}
		}
	},
	"Anubis": {
		"health": 500, # Vida (ex: 800)
		"skill_pattern": [1,2], # Ordem das skills (ex: [1,2,1,2,3])
		"diesound": "res://assets/sounds/bosses/Anubis/AnubisDie.mp3",
		"skills": { # Skills e seus parâmetros { id: { parâmetros necessários } }
			1: {
				"length": 2000.0,
				"thickness": 32.0, # Largura da textura
				"damage": 20,
				"knockback": 300,
				"spin_speed": 40.0,
				"duration": 4.0,
				"hit_interval": 0.2,
				"cooldown": 0.0,
			},
			2: {
				"cooldown": 0.0,
				"damage": 20, # Dano
				"knockback": 150, # Knockback
				"count": 4, # Quantidade
				"square_size": 1300, # Distância máxima
				"delay": 1.0, # Delay pra spawnar após o preview
				"impact_scale": 3.0, # Tamanho
				"skill_duration": 15 # Tempo de duração
			},
		}
	},
	"Corona": {
		"health": 500, # Vida (ex: 800)
		"skill_pattern": [1,2], # Ordem das skills (ex: [1,2,1,2,3])
		"diesound": "res://assets/sounds/bosses/Corona/CoronaDie.mp3",
		"skills": { # Skills e seus parâmetros { id: { parâmetros necessários } }
			1: {
				"cooldown": 1.0,
				"damage": 20, # Dano
				"knockback": 150, # Knockback
				"count": 16, # Quantidade
				"square_size": 1300, # Distância máxima
				"delay": 1.0, # Delay pra spawnar após o preview
				"impact_scale": 3.0, # Tamanho
			},
			2: {
				"cooldown": 0.0,
				"damage": 20, # Dano
				"knockback": 150, # Knockback
				"count": 4, # Quantidade
				"square_size": 1300, # Distância máxima
				"delay": 1.0, # Delay pra spawnar após o preview
				"impact_scale": 3.0, # Tamanho
				"skill_duration": 15 # Tempo de duração
			},
		}
	},
	"Ares": {
		"health": 500, # Vida (ex: 800)
		"skill_pattern": [1], # Ordem das skills (ex: [1,2,1,2,3])
		"diesound": "res://assets/sounds/bosses/Ares/AresDie.mp3",
		"skills": { # Skills e seus parâmetros { id: { parâmetros necessários } }
			1: {
				"cooldown": 5.0,
				"damage": 20, # Dano
				"knockback": 150, # Knockback
				"count": 20, # Quantidade
				"square_size": 1300, # Distância máxima
				"delay": 1.0, # Delay pra spawnar após o preview
				"impact_scale": 3.0, # Tamanho
				"skill_duration": 10 # Tempo de duração
			},
		}
	},
	"Kobe": {
		"health": 500, # Vida (ex: 800)
		"skill_pattern": [1,2], # Ordem das skills (ex: [1,2,1,2,3])
		"diesound": "res://assets/sounds/bosses/Kobe/KobeDie.mp3",
		"skills": { # Skills e seus parâmetros { id: { parâmetros necessários } }
			1: {
				"length": 2000.0,
				"thickness": 32.0, # Largura da textura
				"damage": 20,
				"knockback": 300,
				"spin_speed": 65.0,
				"duration": 4.0,
				"hit_interval": 0.2,
				"cooldown": 0.0,
			},
			2: {
				"cooldown": 0.0,
				"damage": 20, # Dano
				"knockback": 150, # Knockback
				"count": 16, # Quantidade
				"square_size": 1300, # Distância máxima
				"delay": 1.0, # Delay pra spawnar após o preview
				"impact_scale": 3.0, # Tamanho
			}
		}
	},
	"Risadinha": {
		"health": 500, # Vida (ex: 800)
		"skill_pattern": [1], # Ordem das skills (ex: [1,2,1,2,3])
		"diesound": "res://assets/sounds/bosses/Risadinha/RisadinhaDie.mp3",
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
