extends Control
# -- CANVAS --
@onready var main_menu_canvas: CanvasLayer = $MainMenuCanvas
@onready var level_selection_canvas: CanvasLayer = $LevelSelectionCanvas
@onready var cadastro: CanvasLayer = $Cadastro
@onready var settings: CanvasLayer = $Settings

# -- MAIN MENU --
@onready var start: Button = $MainMenuCanvas/Buttons/Start
@onready var options: Button = $MainMenuCanvas/Buttons/Options
@onready var quit: Button = $MainMenuCanvas/Buttons/Quit
@onready var sound_button: Button = $MainMenuCanvas/Som
@onready var help: Button = $MainMenuCanvas/Help
@onready var menu_sprite: AnimatedSprite2D = $MainMenuCanvas/AnimatedSprite2D

# -- FASES --
@onready var level_selection_buttons: GridContainer = $LevelSelectionCanvas/Buttons/GridContainer
@onready var back: Button = $LevelSelectionCanvas/Back
@onready var loja: Button = $LevelSelectionCanvas/Loja
@onready var profile: Button = $LevelSelectionCanvas/Profile
@onready var ranking: Button = $LevelSelectionCanvas/Ranking
@onready var show_coins: Button = $LevelSelectionCanvas/ShowCoins

# -- INSTRUÇÕES --
@onready var instrucoes: Panel = $MainMenuCanvas/Instrucoes
@onready var fechar: Button = $MainMenuCanvas/Instrucoes/Fechar

# -- LOJA --
@onready var voltar_loja: Button = $Loja/VoltarLoja
@onready var roupa_container: HBoxContainer = $Loja/ScrollContainer/MarginContainer/HBoxContainer
@onready var roupa_template: Panel = $Loja/ScrollContainer/MarginContainer/HBoxContainer/Template
@onready var loja_saldo: Button = $Loja/Coins

# -- LOGIN --
@onready var login: Panel = $LevelSelectionCanvas/Login
@onready var entrar: Button = $LevelSelectionCanvas/Login/Entrar
@onready var login_email: LineEdit = $LevelSelectionCanvas/Login/Informacoes/LabelEmail
@onready var login_senha: LineEdit = $LevelSelectionCanvas/Login/Informacoes/LabelSenha
@onready var login_status: Label = $LevelSelectionCanvas/Login/StatusLabel
@onready var tela_cadastro: Button = $LevelSelectionCanvas/Login/BtnTelaCadastro
@onready var fechar_login: Button = $LevelSelectionCanvas/Login/FecharLogin

# -- CADASTRO --
@onready var cadastro_username: LineEdit = $Cadastro/Panel2/LabelUserName
@onready var cadastro_email: LineEdit = $Cadastro/Panel2/LabelEmail
@onready var cadastro_senha: LineEdit = $Cadastro/Panel2/LabelSenha
@onready var cadastro_pais: OptionButton = $Cadastro/Panel2/LabelPais
@onready var cadastro_data_nascimento: LineEdit = $Cadastro/Panel2/LabelDataNascimento
@onready var cadastro_status: Label = $Cadastro/StatusLabel
@onready var cadastrar: Button = $Cadastro/Cadastrar
@onready var voltar_cadastro: Button = $Cadastro/VoltarCadastro

# -- PERFIL --
@onready var fechar_perfil: Button = $LevelSelectionCanvas/Perfil/FecharPerfil
@onready var perfil: Panel = $LevelSelectionCanvas/Perfil
@onready var alterar_senha: Button = $LevelSelectionCanvas/Perfil/Senha
@onready var fechar_senha: Button = $LevelSelectionCanvas/Perfil/AlterarSenha/FecharSenha
@onready var confirmar: Button = $LevelSelectionCanvas/Perfil/AlterarSenha/Confirmar
@onready var tela_alterar_senha: Panel = $LevelSelectionCanvas/Perfil/AlterarSenha
@onready var nova_senha: LineEdit = $LevelSelectionCanvas/Perfil/AlterarSenha/Informacoes/NovaSenha
@onready var senha_status: Label = $LevelSelectionCanvas/Perfil/AlterarSenha/StatusLabel
@onready var sair: Button = $LevelSelectionCanvas/Perfil/Sair
@onready var perfil_username: LineEdit = $LevelSelectionCanvas/Perfil/Informacoes/LabelUserName
@onready var perfil_email: Label = $LevelSelectionCanvas/Perfil/Informacoes/LabelEmail
@onready var perfil_data_criacao: Label = $LevelSelectionCanvas/Perfil/Informacoes/LabelDataCriacao
@onready var perfil_pais: Label = $LevelSelectionCanvas/Perfil/Informacoes/LabelPais
@onready var perfil_data_nascimento: Label = $LevelSelectionCanvas/Perfil/Informacoes/LabelDataNascimento
@onready var perfil_icon: TextureRect = $LevelSelectionCanvas/Perfil/IconPanel/ProfileSkin

# -- RANKING --
@onready var ranking_fase_anterior: Button = $Ranking/Estatisticas/SeletorFase/FaseAnterior
@onready var ranking_fase_proxima: Button = $Ranking/Estatisticas/SeletorFase/FaseProxima
@onready var ranking_fase_label: Label = $Ranking/Estatisticas/SeletorFase/FaseLabel
@onready var ranking_moedas: Label = $Ranking/Estatisticas/MoedasColetadas
@onready var ranking_posicao: Label = $Ranking/Estatisticas/PosicaoGeral
@onready var ranking_linhas: Node = $Ranking/Ranking
@onready var back_ranking: Button = $Ranking/BackRanking

const RANKING_FASE_MAX: int = 8
var ranking_fase_atual: int = 1

var skin_panels := {}

var _formatando_data_nascimento: bool = false

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
	setup_skins_buttons()
	_atualizar_tela_loja()
	change_idle()
	
	# CONEXÕES DE SINAIS (TODOS OS BOTÕES POR SCRIPT)
	var botoes_e_metodos = [
		[start, _on_start_pressed],
		[options, _on_options_pressed],
		[quit, _on_quit_pressed],
		[sound_button, _on_som_pressed],
		[help, _on_help_pressed],
		[fechar, _on_fechar_pressed],
		[back, _on_back_pressed],
		[loja, _on_loja_pressed],
		[profile, _on_profile_pressed],
		[ranking, _on_ranking_pressed],
		[voltar_loja, _on_voltar_loja_pressed],
		[back_ranking, _on_back_ranking_pressed],
		[ranking_fase_anterior, _on_fase_anterior_pressed],
		[ranking_fase_proxima, _on_fase_proxima_pressed],
		[fechar_perfil, _on_fechar_perfil_pressed],
		[alterar_senha, _on_senha_pressed],
		[fechar_senha, _on_fechar_senha_pressed],
		[confirmar, _on_confirmar_pressed],
		[sair, _on_sair_pressed],
		[tela_cadastro, _on_btn_tela_cadastro_pressed],
		[fechar_login, _on_fechar_login_pressed],
		[entrar, _on_entrar_pressed],
		[voltar_cadastro, _on_voltar_cadastro_pressed],
		[cadastrar, _on_cadastrar_pressed],
	]
	
	for par in botoes_e_metodos:
		var botao = par[0]
		var metodo = par[1]
		if botao and metodo:
			if botao.pressed.is_connected(metodo):
				botao.pressed.disconnect(metodo)
			botao.pressed.connect(metodo)
	
	# Lógica específica para mobile
	if OS.get_name() == "Android" or OS.get_name() == "iOS" or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		show_coins.visible = true
		show_coins.pressed.connect(_on_showcoins_pressed)
	
	FirebaseManager.login_concluido.connect(_on_login_concluido)
	FirebaseManager.cadastro_concluido.connect(_on_cadastro_concluido)
	FirebaseManager.senha_alterada.connect(_on_senha_alterada)
	PlayerData.sessao_restaurada.connect(_on_sessao_restaurada)
	cadastro_data_nascimento.text_changed.connect(_on_data_nascimento_text_changed)
	
	# Se o login automático (persistente) já concluiu antes desta tela existir,
	# reflete o estado logado agora.
	if not FirebaseManager.user_id.is_empty():
		_on_sessao_restaurada(true)

	# Conecta todos os botões ao som
	_connect_all_buttons_to_sound()

# --------------
# SOM EM TODOS OS BOTÕES
# --------------
func _play_button_sound() -> void:
	AudioManager.tocar_sfxglobal("res://assets/sounds/UI/ButtonPress.mp3")

func _connect_all_buttons_to_sound() -> void:
	_add_buttons_from_node(self)

func _add_buttons_from_node(node: Node) -> void:
	for child in node.get_children():
		if child == $HUDMobile/ActionButton:
				return
		if child is Button:
			# Conecta o sinal pressed à função de som (não remove outras conexões)
			child.pressed.connect(_play_button_sound)
		# Continua recursivamente
		_add_buttons_from_node(child)

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
	for button in [start, options, quit, sound_button, help, back, loja, profile, fechar, ranking, voltar_loja, back_ranking, fechar_perfil, cadastrar, voltar_cadastro, fechar_login, tela_cadastro, entrar, alterar_senha, confirmar, fechar_senha, ranking_fase_anterior, ranking_fase_proxima, sair, show_coins]:
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
	for i in range(1, 9):
		var btn = template.duplicate()
		var btntext = btn.get_node("LevelNumber")
		btn.visible = true
		btn.name = "Level" + str(i)
		btntext.text = str(i)
		# Verifica se o nível está desbloqueado
		if GameManager.fase_desbloqueada(i):
			btn.disabled = false
			btntext.add_theme_color_override("font_color", Color("#ffffff"))
		else:
			btn.disabled = true
			btntext.add_theme_color_override("font_color", Color("#7d7d7d"))
		
		level_selection_buttons.add_child(btn)
		
		btn.pivot_offset = btn.size / 2
		btn.mouse_entered.connect(_on_level_entered.bind(btn, i))
		btn.mouse_exited.connect(_on_level_exited.bind(btn, i))
		btn.pressed.connect(_play_button_sound)
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
			GameManager.fade_out(0.5)
		)

func _on_level_entered(button: Button, number: int) -> void:
	animate_scale(button, hover_scale)
	if button.disabled:
		return
	var btntext: Label = button.get_node("LevelNumber")
	var btncoin: AnimatedSprite2D = button.get_node("CoinSprite")
	if GameManager.check_level(int(button.name)) and btncoin and btntext: # Pega o número da fase e verifica se ela existe
		btncoin.visible = true
		btncoin.play("default")
		btntext.text = str(GameManager.fase_moedascoletadas(number)) + "/10"

func _on_level_exited(button: Button, number: int) -> void:
	animate_scale(button, original_scale)
	if button.disabled:
		return
	var btntext = button.get_node("LevelNumber")
	var btncoin: AnimatedSprite2D = button.get_node("CoinSprite")
	if GameManager.check_level(int(button.name)) and btncoin and btntext: # Pega o número da fase e verifica se ela existe
		btncoin.stop()
		btncoin.visible = false
		btntext.text = str(number)

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
	_atualizar_tela_loja()
	$LevelSelectionCanvas.visible = false
	$Loja.visible = true

func _on_voltar_loja_pressed() -> void:
	$Loja.visible = false
	$LevelSelectionCanvas.visible = true

# --------------
# LOJA DE SKINS
# --------------
# Cria um botão para cada skin definida em ShopData
func setup_skins_buttons() -> void:
	# Limpa os botões antigos (caso seja chamado novamente)
	for child in roupa_container.get_children():
		child.queue_free()
	skin_panels.clear()

	for skin_name in ShopData.skins.keys():
		var info: Dictionary = ShopData.get_skin_info(skin_name)
		# Duplica o template
		var panel: Panel = roupa_template.duplicate()
		panel.visible = true

		var btn: Button = panel.get_node("Coins")
		btn.pivot_offset = btn.size / 2

		var icon: TextureRect = panel.get_node("Padrao")  # ajuste o nome do nó
		if icon:
			var icon_path: String = info["Icon"]
			if not icon_path.is_empty():
				icon.texture = load(icon_path)
		var title: Label = panel.get_node("Label")
		if title:
			title.text = info["Title"]
		# Conecta os sinais
		btn.mouse_entered.connect(_on_button_mouse_entered.bind(btn))
		btn.mouse_exited.connect(_on_button_mouse_exited.bind(btn))
		# Conecta o pressed para comprar/equipar
		btn.pressed.connect(_on_skin_button_pressed.bind(skin_name))
		# Adiciona ao container
		roupa_container.add_child(panel)
		skin_panels[skin_name] = panel

	# Oculta o template original (não usado)
	roupa_template.visible = false

func _on_showcoins_pressed() -> void:
	# Itera sobre todos os filhos do container
	for btn in level_selection_buttons.get_children():
		# Verifica se é um botão e se está habilitado
		if btn is Button and not btn.disabled:
			var btntext: Label = btn.get_node("LevelNumber")
			var btncoin: AnimatedSprite2D = btn.get_node("CoinSprite")
			# Extrai o número do nível a partir do nome do botão
			var level_number = int(btn.name.replace("Level", ""))
			
			# Verifica se o nível existe (opcional, mas seguro)
			if not GameManager.check_level(level_number):
				continue
			
			# Alterna a visibilidade da moeda e atualiza o texto
			if btncoin.visible:
				# Moeda visível → oculta e mostra o número
				btncoin.stop()
				btncoin.visible = false
				btntext.text = str(level_number)
			else:
				# Moeda oculta → mostra e exibe a quantidade de moedas
				btncoin.visible = true
				btncoin.play("default")
				var moedas = GameManager.fase_moedascoletadas(level_number)
				btntext.text = str(moedas) + "/10"

# Callback para o pressed de cada botão de skin
func _on_skin_button_pressed(skin_name: String) -> void:
	_comprar_ou_equipar_skin(skin_name)

# Função existente, mas com pequena adaptação para tratar erro se não achar o preço
func _comprar_ou_equipar_skin(skin_id: String) -> void:
	var info = ShopData.get_skin_info(skin_id)
	if info.is_empty():
		print("Skin não encontrada: ", skin_id)
		return
	var preco: int = info["Price"]
	if PlayerData.comprar_e_equipar_skin(skin_id, preco):
		_atualizar_tela_loja()
	else:
		print("Moedas insuficientes para comprar a skin ", skin_id)

# Atualiza todos os botões dinâmicos
func _atualizar_tela_loja() -> void:
	var equipada := PlayerData.obter_skin_equipada()
	loja_saldo.text = " %d" % PlayerData.moedas_coletadas
	
	# Atualiza cada botão de skin
	for skin_name in skin_panels.keys():
		var panel: Panel = skin_panels[skin_name]
		_atualizar_botao_skin(panel, skin_name, equipada)

# Função auxiliar que atualiza um botão específico
func _atualizar_botao_skin(panel: Panel, skin_id: String, skin_equipada: String) -> void:
	var info: Dictionary = PlayerData.skins_inventario.get(skin_id, {})
	var botao: Button = panel.get_node("Coins")
	var coinicon: TextureRect = botao.get_node("TextureRect")
	if info.get("comprada", false):
		coinicon.visible = false
		if skin_equipada == skin_id:
			botao.text = "EQUIPADO"
			botao.disabled = true
		else:
			botao.text = "EQUIPAR"
			botao.disabled = false
	else:
		# Mostra o preço (obtido do ShopData)
		coinicon.visible = true
		var preco = ShopData.get_skin_info(skin_id).get("Price", 0)
		botao.text = "  %d" % preco
		botao.disabled = false

func _on_ranking_pressed() -> void:
	$LevelSelectionCanvas.visible = false
	$Ranking.visible = true
	# Abre no ranking da ÚLTIMA fase jogada (não sempre na fase 1) — assim, logo
	# depois de concluir uma fase, o jogador vê o ranking DELA (e a própria entrada).
	ranking_fase_atual = clampi(GameManager.currentlevel, 1, RANKING_FASE_MAX)
	_carregar_ranking_da_fase(ranking_fase_atual)

func _on_back_ranking_pressed() -> void:
	$Ranking.visible = false
	$LevelSelectionCanvas.visible = true

func _on_fase_anterior_pressed() -> void:
	ranking_fase_atual = max(1, ranking_fase_atual - 1)
	_carregar_ranking_da_fase(ranking_fase_atual)

func _on_fase_proxima_pressed() -> void:
	ranking_fase_atual = min(RANKING_FASE_MAX, ranking_fase_atual + 1)
	_carregar_ranking_da_fase(ranking_fase_atual)

# Busca o ranking da fase selecionada no Firebase e preenche a tabela
func _carregar_ranking_da_fase(numero_fase: int) -> void:
	ranking_fase_label.text = "FASE %02d" % numero_fase
	ranking_moedas.text = str(PlayerData.moedas_coletadas)

	var fid := GameManager.fase_id(numero_fase)
	var resultados: Array = await FirebaseManager.buscar_ranking_da_fase(fid, 7)

	var minha_posicao := "-"
	for i in range(7):
		var pos_label: Label = ranking_linhas.get_node("Pos%d" % (i + 1)) as Label
		var name_label: Label = ranking_linhas.get_node("Name%d" % (i + 1)) as Label
		var score_label: Label = ranking_linhas.get_node("Score%d" % (i + 1)) as Label
		var tempo_label: Label = ranking_linhas.get_node("Tempo%d" % (i + 1)) as Label

		if i < resultados.size():
			var entrada: Dictionary = resultados[i]
			pos_label.text = "#%d" % (i + 1)
			name_label.text = String(entrada.get("username", "???"))
			score_label.text = str(int(entrada.get("score", 0)))
			tempo_label.text = _formatar_tempo(float(entrada.get("tempo", 0.0)))

			if not FirebaseManager.user_id.is_empty() and entrada.get("user_id", "") == FirebaseManager.user_id:
				minha_posicao = str(i + 1)
		else:
			pos_label.text = "#%d" % (i + 1)
			name_label.text = "-"
			score_label.text = "-"
			tempo_label.text = "-"

	ranking_posicao.text = minha_posicao

func _formatar_tempo(segundos: float) -> String:
	var total := int(segundos)
	@warning_ignore("integer_division")
	var minutos := total / 60
	var restante := total % 60
	return "%02d:%02d" % [minutos, restante]

func _on_profile_pressed() -> void:
	if FirebaseManager.user_id.is_empty():
		login_status.text = ""
		login.visible = true
	else:
		_atualizar_icone_perfil()
		perfil.visible = true

func _on_fechar_perfil_pressed() -> void:
	perfil.visible = false

func _on_btn_tela_cadastro_pressed() -> void:
	login.visible = false
	cadastro_status.text = ""
	cadastro.visible = true

func _on_fechar_login_pressed() -> void:
	login.visible = false

func _on_voltar_cadastro_pressed() -> void:
	cadastro.visible = false
	login.visible = true

# --------------
# LOGIN / CADASTRO (FIREBASE)
# --------------
func _on_entrar_pressed() -> void:
	var email := login_email.text.strip_edges()
	var senha := login_senha.text

	if email.is_empty() or senha.is_empty():
		login_status.text = "Preencha e-mail e senha!"
		return

	entrar.disabled = true
	login_status.text = "Entrando..."
	FirebaseManager.fazer_login_com_email(email, senha)

# Se restaurou a sessão atualiza as telas pra refletir a conta logada
func _on_sessao_restaurada(sucesso: bool) -> void:
	if sucesso:
		_atualizar_tela_perfil()
		_atualizar_tela_loja()

func _on_login_concluido(sucesso: bool, mensagem: String) -> void:
	entrar.disabled = false
	login_status.text = mensagem

	if sucesso:
		login_status.text = "Sincronizando dados..."
		await PlayerData.sincronizar_apos_login(FirebaseManager.user_id)
		_atualizar_tela_perfil()
		_atualizar_tela_loja()
		setup_levels_selection() # Sem isso, a grade de fases ficava com o estado da conta anterior até voltar ao menu principal
		login_email.text = ""
		login_senha.text = ""
		login_status.text = ""
		login.visible = false

# Aplica a máscara DD/MM/AAAA enquanto o jogador digita a data de nascimento
func _on_data_nascimento_text_changed(new_text: String) -> void:
	if _formatando_data_nascimento:
		return

	var digitos := ""
	for c in new_text:
		if c.is_valid_int():
			digitos += c
	digitos = digitos.substr(0, 8)

	var formatado := digitos
	if digitos.length() > 4:
		formatado = digitos.substr(0, 2) + "/" + digitos.substr(2, 2) + "/" + digitos.substr(4)
	elif digitos.length() > 2:
		formatado = digitos.substr(0, 2) + "/" + digitos.substr(2)

	if formatado != new_text:
		_formatando_data_nascimento = true
		cadastro_data_nascimento.text = formatado
		cadastro_data_nascimento.caret_column = formatado.length()
		_formatando_data_nascimento = false

func _on_cadastrar_pressed() -> void:
	var username := cadastro_username.text.strip_edges()
	var email := cadastro_email.text.strip_edges()
	var senha := cadastro_senha.text
	var data_nascimento := cadastro_data_nascimento.text.strip_edges()

	if username.is_empty() or email.is_empty() or senha.is_empty():
		cadastro_status.text = "Preencha usuário, e-mail e senha!"
		return

	if not data_nascimento.is_empty() and data_nascimento.length() != 10:
		cadastro_status.text = "Data de nascimento inválida! Use DD/MM/AAAA."
		return

	cadastrar.disabled = true
	cadastro_status.text = "Criando conta..."

	var agora := Time.get_datetime_dict_from_system()
	PlayerData.username = username
	PlayerData.pais = cadastro_pais.get_item_text(cadastro_pais.selected)
	PlayerData.data_nascimento = data_nascimento
	PlayerData.data_criacao = "%02d/%02d/%04d" % [agora.day, agora.month, agora.year]

	FirebaseManager.cadastrar_com_email(email, senha)

func _on_cadastro_concluido(sucesso: bool, mensagem: String) -> void:
	cadastrar.disabled = false
	cadastro_status.text = mensagem

	if sucesso:
		cadastro_status.text = "Sincronizando dados..."
		await PlayerData.sincronizar_apos_login(FirebaseManager.user_id)
		_atualizar_tela_perfil()
		_atualizar_tela_loja()
		setup_levels_selection() # Sem isso, a grade de fases ficava com o estado da conta anterior até voltar ao menu principal
		cadastro_username.text = ""
		cadastro_email.text = ""
		cadastro_senha.text = ""
		cadastro_data_nascimento.text = ""
		cadastro_pais.selected = 0
		cadastro_status.text = ""
		cadastro.visible = false
		login.visible = false

# Reflete os dados atuais do PlayerData/FirebaseManager na tela de Perfil
func _atualizar_tela_perfil() -> void:
	perfil_username.text = PlayerData.username
	perfil_email.text = FirebaseManager.email_usuario
	perfil_data_criacao.text = PlayerData.data_criacao if not PlayerData.data_criacao.is_empty() else "00/00/0000"
	perfil_pais.text = PlayerData.pais if not PlayerData.pais.is_empty() else "-"
	perfil_data_nascimento.text = PlayerData.data_nascimento if not PlayerData.data_nascimento.is_empty() else "00/00/0000"
	_atualizar_icone_perfil()

func _atualizar_icone_perfil() -> void:
	var skinequipada = PlayerData.obter_skin_equipada()
	var skinicon = ShopData.get_skin_info(skinequipada).get("Icon", "res://assets/images/background/padrao.png")
	if skinicon:
		perfil_icon.texture = load(skinicon)
	else:
		perfil_icon.texture = load("res://assets/images/background/padrao.png")

func _on_fechar_senha_pressed() -> void:
	tela_alterar_senha.visible = false

func _on_senha_pressed() -> void:
	nova_senha.text = ""
	senha_status.text = ""
	tela_alterar_senha.visible = true

func _on_confirmar_pressed() -> void:
	var senha := nova_senha.text

	if senha.length() < 6:
		senha_status.text = "A senha deve ter pelo menos 6 caracteres!"
		return

	confirmar.disabled = true
	senha_status.text = "Alterando senha..."
	FirebaseManager.alterar_senha(senha)

func _on_senha_alterada(sucesso: bool, mensagem: String) -> void:
	confirmar.disabled = false
	senha_status.text = mensagem

	if sucesso:
		nova_senha.text = ""
		tela_alterar_senha.visible = false

# --------------
# LOGOFF
# --------------
func _on_sair_pressed() -> void:
	# IMPORTANTE: sincroniza ANTES de derrubar a sessão - se limpasse o
	# auth_token primeiro, uma compra/progresso recém-feito (ainda não
	# sincronizado) não teria mais como ser enviado, e vazaria pro próximo
	# login neste mesmo dispositivo.
	await PlayerData.logout_local()
	FirebaseManager.fazer_logout()
	perfil.visible = false
	perfil_username.text = "username"
	perfil_email.text = "email"
	perfil_data_criacao.text = "00/00/0000"
	perfil_pais.text = "país"
	perfil_data_nascimento.text = "00/00/0000"
	# Manda pro menu principal - evita telas (fases, loja, ranking) com o
	# estado da conta que acabou de sair até um novo login as reconstruir.
	level_selection_canvas.visible = false
	main_menu_canvas.visible = true
