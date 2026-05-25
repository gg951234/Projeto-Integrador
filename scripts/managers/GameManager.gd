extends Node

# Dados que não precisam ser salvos
var currentlevel: int = 1
var gamescore: int = 0

# Dados para serem salvos
var playername: String = ""
var maxscore: int = 0
var coins: int = 0
var unlockedlevels: Array = [1]

var currentlevelroot: Node = null

func _ready() -> void:
	await get_tree().process_frame
	currentlevelroot = get_tree().root.find_child("LevelRoot", true, false)

func load_level(levelnumber: int = 0) -> bool:
	if levelnumber <= 0:
		print("Sem levelnumber")
		levelnumber = currentlevel
	
	if currentlevelroot:
		print("Queue Free")
		currentlevelroot.queue_free()
	
	# Mudar fase se ela existir
	var levelpath = "res://scenes/levels/level_%s.tscn" % levelnumber
	if ResourceLoader.exists(levelpath):
		currentlevelroot = load(levelpath).instantiate()
		add_child(currentlevelroot)
		currentlevelroot.name = "LevelRoot"
		return 1
	else:
		print("A fase " + str(levelnumber) + " não existe")
		return 0

func unlocknextlevel() -> void:
	if not (currentlevel + 1) in unlockedlevels:
		unlockedlevels.append(currentlevel+1)

func add_coins(amount: int) -> void:
	coins += amount
