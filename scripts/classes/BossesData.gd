extends Node

var stats = {
	"Golem": {
		"speed": 200, # Velocidade (ex: 100.0)
		"health": 500, # Vida (ex: 800)
		"skill_pattern": [1], # Ordem das skills (ex: [1,2,1,2,3])
		"skills": { # Skills e seus parâmetros { id: { parâmetros necessários } }
			1: {
				"cooldown": 5.0,
				"rock_damage": 20, # Dano
				"rock_knockback": 150, # Knockback
				"rock_count": 16, # Quantidade de pedras
				"square_size": 1300, # Distância máxima das pedras
				"fall_delay": 1.0, # Delay pra spawnar as pedras após o preview
				"impact_scale": 3.0, # Tamanho da pedra
			}
		}
	},
	# Futuros bosses podem ser adicionados aqui
}

# Retorna as estatísticas para um determinado nome
func get_stats(objname: String) -> Dictionary:
	if stats.has(objname):
		return stats[objname].duplicate(true) # duplica para não modificar o original (true pra deep copy)
	return {} # ou um valor padrão
