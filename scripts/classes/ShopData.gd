extends Node

# Tabela de skins
var skins = {
	"Default": {
		"Title": "Padrão",
		"Price": 0,
		"Icon": "res://assets/images/background/padrao.png",
	},
	"Frost": {
		"Title": "Frost",
		"Price": 10,
		"Icon": "res://assets/images/background/frost.png",
	},
	"Shadow": {
		"Title": "Shadow",
		"Price": 15,
		"Icon": "res://assets/images/background/shadow.png",
	},
	"Gold": {
		"Title": "Gold",
		"Price": 30,
		"Icon": "res://assets/images/background/gold1.png",
	},
	"Pirate": {
		"Title": "Pirate",
		"Price": 50,
		"Icon": "res://assets/images/background/gold1.png",
	}
}

# Retorna um dicionário com nome
func get_skin_info(skin_name: String) -> Dictionary:
	if skins.has(skin_name):
		return skins[skin_name].duplicate() # duplica para não modificar o original
	return {} # dicionário vazio
	
