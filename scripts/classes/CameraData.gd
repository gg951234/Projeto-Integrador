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
		"right": 4544,
		"bottom": 1984,
		"soundtrack": "res://assets/sounds/levels/Level 3 Soundtrack.mp3",
	},
	"BossRoom3": {
		"left": 1216,
		"top": 1920,
		"right": 2752,
		"bottom": 3456,
		"soundtrack": "res://assets/sounds/bosses/Cartagon/CartagonSoundtrack.mp3",
	},
		"Level4": {
		"left": 0,
		"top": 0,
		"right": 3328,
		"bottom": 1984,
		"soundtrack": "res://assets/sounds/levels/Level 4 Soundtrack.mp3",
	},
	"BossRoom4": {
		"left": 3264,
		"top": 448,
		"right": 4800,
		"bottom": 1984,
		"soundtrack": "res://assets/sounds/bosses/Anubis/AnubisSoundtrack.mp3",
	},
		"Level5": {
		"left": 0,
		"top": 0,
		"right": 3904,
		"bottom": 1984,
		"soundtrack": "res://assets/sounds/levels/Level 5 Soundtrack.mp3",
	},
	"BossRoom5": {
		"left": -1472,
		"top": 896,
		"right": 64,
		"bottom": 2432,
		"soundtrack": "res://assets/sounds/bosses/Corona/CoronaSoundtrack.mp3",
	},
		"Level6": {
		"left": 0,
		"top": 0,
		"right": 4608,
		"bottom": 2368,
		"soundtrack": "res://assets/sounds/levels/Level 6 Soundtrack.mp3",
	},
	"BossRoom6": {
		"left": 1984,
		"top": 2304,
		"right": 3520,
		"bottom": 3840,
		"soundtrack": "res://assets/sounds/bosses/Ares/AresSoundtrack.mp3",
	},
		"Level7": {
		"left": 0,
		"top": 0,
		"right": 3456,
		"bottom": 1792,
		"soundtrack": "res://assets/sounds/levels/Level 7 Soundtrack.mp3",
	},
	"BossRoom7": {
		"left": 2368,
		"top": 1728,
		"right": 832,
		"bottom": 3264,
		"soundtrack": "res://assets/sounds/bosses/Kobe/KobeSoundtrack.mp3",
	},
		"Level8": {
		"left": 0,
		"top": 0,
		"right": 7744,
		"bottom": 2880,
		"soundtrack": "res://assets/sounds/levels/Level 8 Soundtrack.mp3",
	},
	"BossRoom8": {
		"left": 7616,
		"top": 768,
		"right": 9152,
		"bottom": 2304,
		"soundtrack": "res://assets/sounds/bosses/Risadinha/RisadinhaSoundtrack.mp3",
	},
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
