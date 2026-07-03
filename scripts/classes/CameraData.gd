extends Node

# Dicionário com os limites de cada nível
var limits = {
	"Level1": {
		"left": 0,
		"top": 0,
		"right": 2496,
		"bottom": 1024,
	},
	"BossRoom1": {
		"left": 2432,
		"top": -172,
		"right": 3968,
		"bottom": 1536,
	},
	"Level2": {
		"left": 0,
		"top": 0,
		"right": 2496,
		"bottom": 1088,
	},
	"BossRoom2": {
		"left": 2432,
		"top": -172,
		"right": 3968,
		"bottom": 1536,
	},
	# Adicione mais níveis conforme necessário
}

# Função para obter os limites de um nível
func get_limits_for_level(level_name: String) -> Dictionary:
	if limits.has(level_name):
		return limits[level_name]
	else:
		push_error("CameraData: limites não encontrados para o nível ", level_name)
		# Retorna um fallback (ex: 0,0)
		return { "right": 0, "bottom": 0 }
