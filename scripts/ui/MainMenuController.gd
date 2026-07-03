extends Control

@onready var hud: CanvasLayer = $HUD
@onready var health_bar: TextureProgressBar = $HUD/HealthBar

@onready var start: Button = $MainMenuCanvas/Buttons/Start
@onready var options: Button = $MainMenuCanvas/Buttons/Options
@onready var quit: Button = $MainMenuCanvas/Buttons/Quit
@onready var main_menu_canvas: CanvasLayer = $MainMenuCanvas
@onready var level_selection_canvas: CanvasLayer = $LevelSelectionCanvas
@onready var cadastro: CanvasLayer = $Cadastro
@onready var level_selection_buttons: GridContainer = $LevelSelectionCanvas/Buttons/GridContainer

@onready var sound_button: Button = $MainMenuCanvas/Som
@onready var help: Button = $MainMenuCanvas/Help
@onready var back: Button = $LevelSelectionCanvas/Back
@onready var loja: Button = $LevelSelectionCanvas/Loja
@onready var profile: Button = $LevelSelectionCanvas/Profile
@onready var menu_sprite: AnimatedSprite2D = $MainMenuCanvas/AnimatedSprite2D
@onready var instrucoes: Panel = $MainMenuCanvas/Instrucoes
@onready var fechar: Button = $MainMenuCanvas/Instrucoes/Fechar
@onready var next: Button = $TelaVitoria/HBoxContainer/ProximaFase
@onready var menu: Button = $TelaVitoria/HBoxContainer/Menu
@onready var ranking: Button = $LevelSelectionCanvas/Ranking
@onready var voltar_loja: Button = $Loja/VoltarLoja
@onready var back_ranking: Button = $Ranking/BackRanking
@onready var equipado: Button = $Loja/HBoxContainer/Roupa1/Equipado
@onready var roupa4: Button = $Loja/HBoxContainer/Roupa4/Coins
@onready var roupa2: Button = $Loja/HBoxContainer/Roupa2/Coins
@onready var roupa3: Button = $Loja/HBoxContainer/Roupa3/Coins
@onready var fechar_perfil: Button = $LevelSelectionCanvas/Perfil/FecharPerfil
@onready var perfil: Panel = $LevelSelectionCanvas/Perfil
@onready var login: Panel = $LevelSelectionCanvas/Login
@onready var cadastrar: Button = $Cadastro/Cadastrar
@onready var voltar_cadastro: Button = $Cadastro/VoltarCadastro
@onready var entrar: Button = $LevelSelectionCanvas/Login/Entrar
@onready var tela_cadastro: Button = $LevelSelectionCanvas/Login/BtnTelaCadastro
@onready var fechar_login: Button = $LevelSelectionCanvas/Login/FecharLogin
@onready var alterar_senha: Button = $LevelSelectionCanvas/Perfil/Senha
@onready var fechar_senha: Button = $LevelSelectionCanvas/Perfil/AlterarSenha/FecharSenha
@onready var confirmar: Button = $LevelSelectionCanvas/Perfil/AlterarSenha/Confirmar
@onready var tela_alterar_senha: Panel = $LevelSelectionCanvas/Perfil/AlterarSenha
@onready var settings: CanvasLayer = $Settings

var sound_on_icon = preload("res://assets/images/background/icon_som.png")
var sound_off_icon = preload("res://assets/images/background/icon_sem_som.png")

var sound_muted: bool = false

var hover_scale: Vector2 = Vector2(1.1, 1.1)
var animation_duration: float = 0.2
var tween_type: Tween.EaseType = Tween.EASE_OUT
var tween_trans: Tween.TransitionType = Tween.TRANS_BACK

var original_scale: Vector2 = Vector2(1, 1)
var buttontween: Tween

var levels_setup_done: bool = false

var player
var max_health

# --------------
# FUNÇÕES DE INÍCIO (PADRÃO GODOT)
# --------------
func _ready() -> void:  # Executa quando o nó é criado
	# Aguarda um frame para o VBoxContainer ajustar os tamanhos
	await get_tree().process_frame
	setup_main_buttons()
	
	change_idle()
	
	sound_button.pressed.connect(_on_som_pressed)
	fechar.pressed.connect(_on_fechar_pressed)
	help.pressed.connect(_on_help_pressed)

# --------------
# SETAR PLAYER
# --------------
func set_player(p) -> void:
	player = p
	if player:
		hud.visible = true
		max_health = player.health
		player.health_changed.connect(_update_health)
		player.died.connect(_hide_HUD)
		_update_health(player.health)

func _hide_HUD() -> void:
	hud.visible = false

func _update_health(new_health) -> void:
	health_bar.value = new_health
	health_bar.max_value = max_health

func _update_coins(amount) -> void:
	health_bar.value = amount
	health_bar.max_value = max_health

# --------------
# ANIMAÇÃO DE HOVER
# --------------
func _on_button_mouse_entered(button: Button) -> void:
	animate_scale(button, hover_scale)

func _on_button_mouse_exited(button: Button) -> void:
	animate_scale(button, original_scale)

func animate_scale(button: Button, target_scale: Vector2) -> void:
	buttontween = create_tween()
	buttontween.set_ease(tween_type)
	buttontween.set_trans(tween_trans)
	buttontween.tween_property(button, "scale", target_scale, animation_duration)
	buttontween.finished.connect(buttontween.kill)

func setup_main_buttons() -> void:
	# Conecta todos os botões do menu de uma vez
	for button in [start, options, quit, sound_button, help, back, loja, profile, fechar, next, menu, ranking, voltar_loja, back_ranking, roupa4, roupa2, roupa3, fechar_perfil, cadastrar, voltar_cadastro, fechar_login, tela_cadastro, entrar, alterar_senha, equipado, confirmar, fechar_senha]:
		button.pivot_offset = button.size / 2 # Define o pivot para o centro do botão
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
		button.mouse_exited.connect(_on_button_mouse_exited.bind(button))

func setup_levels_selection() -> void:
	var template = level_selection_buttons.get_node("Level")
	if not template:
		push_error("Template 'Level' não encontrado em level_selection_buttons.")
		return
	
	# Remove todos os botões existentes (exceto o template)
	for child in level_selection_buttons.get_children():
		if child != template:
			child.queue_free()
	
	await get_tree().process_frame
	
	# Cria 10 botões clonando o template
	for i in range(1, 11):
		var btn = template.duplicate()
		btn.visible = true
		btn.name = "Level" + str(i)
		btn.text = str(i)
		
		# Verifica se o nível está desbloqueado
		if i in GameManager.unlockedlevels:
			btn.disabled = false
		else:
			btn.disabled = true
		
		level_selection_buttons.add_child(btn)
		
		btn.pivot_offset = btn.size / 2
		btn.mouse_entered.connect(_on_button_mouse_entered.bind(btn))
		btn.mouse_exited.connect(_on_button_mouse_exited.bind(btn))
		btn.pressed.connect(_on_level_pressed.bind(btn))

# --------------
# MAIN MENU
# --------------
func _on_start_pressed() -> void:
	main_menu_canvas.visible = false
	level_selection_canvas.visible = true
	
	# Configura apenas se ainda não foi feito
	await get_tree().process_frame
	setup_levels_selection()
	levels_setup_done = true

func _on_options_pressed() -> void:
	main_menu_canvas.visible = false
	settings.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()

# --------------
# SELEÇÃO DE FASES
# --------------
func _on_back_pressed() -> void:
	main_menu_canvas.visible = true
	level_selection_canvas.visible = false

func _on_level_pressed(button: Button) -> void:
	if GameManager.check_level(int(button.name)): # Pega o número da fase e verifica se ela existe
		GameManager.fade_in(1, func():
			GameManager.load_level(int(button.name)) # Pega o número da fase e tenta carregar
			level_selection_canvas.visible = false
			hud.visible = true
			GameManager.fade_out(0.5)
		)

func _on_som_pressed() -> void:
	sound_muted = !sound_muted

	var master_bus = AudioServer.get_bus_index("Master")

	if sound_muted:
		AudioServer.set_bus_mute(master_bus, true)
		sound_button.icon = sound_off_icon
	else:
		AudioServer.set_bus_mute(master_bus, false)
		sound_button.icon = sound_on_icon

func change_idle():
	while true:
		menu_sprite.flip_h = false
		menu_sprite.play("idle_side")
		await get_tree().create_timer(2.0).timeout
		
		menu_sprite.play("idle_down")
		await get_tree().create_timer(2.0).timeout

		menu_sprite.flip_h = true
		menu_sprite.play("idle_side")
		await get_tree().create_timer(2.0).timeout

func _on_help_pressed() -> void:
	instrucoes.visible = true

func _on_fechar_pressed() -> void:
	instrucoes.visible = false

func _on_loja_pressed() -> void:
	$LevelSelectionCanvas.visible = false
	$Loja.visible = true

func _on_voltar_loja_pressed() -> void:
	$Loja.visible = false
	$LevelSelectionCanvas.visible = true

func _on_ranking_pressed() -> void:
	$LevelSelectionCanvas.visible = false
	$Ranking.visible = true

func _on_back_ranking_pressed() -> void:
	$Ranking.visible = false
	$LevelSelectionCanvas.visible = true

func _on_profile_pressed() -> void:
	perfil.visible = true

func _on_fechar_perfil_pressed() -> void:
	perfil.visible = false

func _on_btn_tela_cadastro_pressed() -> void:
	cadastro.visible = true
	
func _on_entrar_pressed() -> void:
	pass # Replace with function body.

func _on_fechar_senha_pressed() -> void:
	tela_alterar_senha.visible = false

func _on_senha_pressed() -> void:
	tela_alterar_senha.visible = true
