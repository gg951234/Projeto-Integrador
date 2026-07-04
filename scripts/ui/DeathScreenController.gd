extends CanvasLayer

func _ready():
	$Buttons/Retry.pressed.connect(_on_retry_pressed)
	$Buttons/Back.pressed.connect(_on_back_pressed)

func _on_retry_pressed():
	AudioManager.tocar_sfxglobal("res://assets/sounds/UI/ButtonPress.mp3")
	GameManager.fade_in(0.5, func():
		queue_free() # Remove a tela de morte
		GameManager.load_level() # Recarrega a fase atual
		GameManager.fade_out(0.5)
	)

func _on_back_pressed():
	AudioManager.tocar_sfxglobal("res://assets/sounds/UI/ButtonPress.mp3")
	AudioManager.tocar_musica("res://assets/sounds/UI/Menu SoundTrack - Moment of Peace.mp3")
	GameManager.fade_in(0.5, func():
		# Remove a fase atual (LevelRoot)
		GameManager.delete_level()
		
		# Mostra o MainMenuCanvas e esconde outros menus
		var ui = get_tree().root.find_child("UI", true, false)
		if ui:
			var main_menu = ui.find_child("MainMenuCanvas", true, false)
			if main_menu:
				main_menu.visible = true
			
			var level_selection = ui.find_child("LevelSelectionCanvas", true, false)
			if level_selection:
				level_selection.visible = false
		queue_free() # Remove a tela de morte
		GameManager.fade_out(0.5)
	)
