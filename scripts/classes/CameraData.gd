extends Node

# Dicionário com os limites de cada nível
var limits = {
	"Level1": {
		"left": 0,
		"top": 0,
		"right": 2496,
		"bottom": 1088,
		"soundtrack": "res://assets/sounds/levels/Level 1 Soundtrack.mp3",
	},
	"BossRoom1": {
		"left": 2432,
		"top": 0,
		"right": 3968,
		"bottom": 1536,
		"soundtrack": "res://assets/sounds/bosses/Golem/GolemSoundtrack.mp3",
	},
	"Level2": {
		"left": 0,
		"top": 0,
		"right": 2496,
		"bottom": 1088,
		"soundtrack": "res://assets/sounds/levels/Level 2 Soundtrack.mp3",
	},
	"BossRoom2": {
		"left": 320,
		"top": 1064,
		"right": 1856,
		"bottom": 2560,
		"soundtrack": "res://assets/sounds/bosses/ByBy/ByBySoundtrack.mp3",
	},
	"Level3": {
		"left": 0,
		"top": 0,
		"right": 2496,
		"bottom": 1088,
		"soundtrack": "res://assets/sounds/levels/Level 3 Soundtrack.mp3",
	},
	"BossRoom3": {
		"left": 320,
		"top": 1064,
		"right": 1856,
		"bottom": 2560,
		"soundtrack": "res://assets/sounds/bosses/Cartagon/CartagonSoundtrack.mp3",
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

func get_soundtrack(level_name: String) -> String:
	if limits.has(level_name) and limits[level_name]["soundtrack"]:
		return limits[level_name]["soundtrack"]
	else:
		return "res://assets/sounds/bosses/Golem/GolemSoundtrack.mp3"
