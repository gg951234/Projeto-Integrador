extends Node

# Tabela de inimigos por nível com quantidades
var enemies = {
	"Level1": {
		"Weak Book": 6,
	},
	"Level2": {
		"Weak Book": 4,
		"Novice Book": 2,
	},
	"Level3": {
		"Novice Book": 1,
		#"Adept Book": 2,
	},
	"Level4": {
		"Novice Book": 2,
		"Adept Book": 4,
	},
	"Level5": {
		"Adept Book": 4,
		"Expert Book": 2,
	},
	"Level6": {
		"Expert Book": 2,
		"Master Book": 4,
	},
	"Level7": {
		"Expert Book": 4,
		"Master Book": 2,
	},
	"Level8": {
		"Legend Book": 6,
	},
}

# Retorna um dicionário com nome -> quantidade para um nível
func get_enemies_for_level(level_name: String) -> Dictionary:
	if enemies.has(level_name):
		return enemies[level_name].duplicate() # duplica para não modificar o original
	return {} # dicionário vazio

# (Opcional) Retorna a quantidade de um inimigo específico em um nível
func get_enemy_amount(level_name: String, enemy_name: String) -> int:
	var level_data = get_enemies_for_level(level_name)
	if level_data.has(enemy_name):
		return level_data[enemy_name]
	return 0 # retorna 0 se não existir
