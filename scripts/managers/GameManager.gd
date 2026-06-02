extends Node

# Dados que não precisam ser salvos
var currentlevel: int = 1
var gamescore: int = 0
var currentlevelroot: Node = null
var currentlevelpath: String = ""

# Dados para serem salvos
var playername: String = ""
var maxscore: int = 0
var coins: int = 0
var unlockedlevels: Array = [1, 2]

func _ready() -> void:
	await get_tree().process_frame
	# ADD FUNÇÃO PARA CARREGAR DADOS DO BANCO DE DADOS
	currentlevelroot = get_tree().root.find_child("LevelRoot", true, false)

func check_level(levelnumber: int = 0) -> bool:
	if levelnumber <= 0:
		print("Sem levelnumber")
		levelnumber = currentlevel
	
	if levelnumber in unlockedlevels:
		# Achar o caminho da fase se o player tiver ela desbloqueada
		currentlevelpath = "res://scenes/levels/level_%s.tscn" % levelnumber
		# Mudar fase se ela existir
		if ResourceLoader.exists(currentlevelpath):
			return 1
		else:
			print("A fase " + str(levelnumber) + " não existe")
	else:
		print("O jogador ainda não desbloqueou a fase " + str(levelnumber))
	
	return 0

func load_level(levelnumber: int = 0) -> bool:
	if levelnumber <= 0:
		print("Sem levelnumber")
		levelnumber = currentlevel
		
	if currentlevelroot:
		print("Queue Free")
		currentlevelroot.queue_free()
		
	if check_level(levelnumber):
		currentlevelroot = load(currentlevelpath).instantiate()
		add_child(currentlevelroot)
		currentlevelroot.name = "LevelRoot"
		print("Fase " + str(levelnumber) + " carregada com sucesso")
		return 1
	else:
		print("Falha ao carregar a fase " + str(levelnumber))
		return 0


func unlocknextlevel() -> void:
	if not (currentlevel + 1) in unlockedlevels:
		unlockedlevels.append(currentlevel+1)

func add_coins(amount: int) -> void:
	coins += amount
	print(coins)
