extends Node

# Tabela de inimigos por nível com quantidades
var enemies = {
	"Level1": {
		"Slime": 1,
	},
	"Level2": {
		"Slime": 2,
	},
	"Level3": {
		"Slime": 3,
	}
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
