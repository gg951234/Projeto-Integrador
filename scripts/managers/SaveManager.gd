extends Node

const SAVE_PATH := "user://save.json"

func save() -> void:
	var data := {
		"playername": GameManager.playername,
		"maxscore": GameManager.maxscore,
		"coins": GameManager.coins,
		"unlockedlevels": GameManager.unlockedlevels
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("Arquivo de saves não existe")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		if data:
			GameManager.playername = data.get("playername", "")
			GameManager.maxscore = data.get("maxscore", 0)
			GameManager.coins = data.get("coins", 0)
			GameManager.unlockedlevels = data.get("unlockedlevels", [1])
