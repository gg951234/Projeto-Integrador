extends Node

# Dados salvos na RAM (Fonte da Verdade do jogo)
var username: String = "Jogador"
var pais: String = ""
var data_nascimento: String = ""
var data_criacao: String = ""
var moedas_coletadas: int = 0
var progresso_fases: Dictionary = {}
var skins_inventario: Dictionary = {
	"Default": {"comprada": true, "equipada": true}
}

# Controle de sincronização offline
var sincronizado: bool = true
var _sincronizando: bool = false

# UID da última conta Firebase que usou este dispositivo (NÃO é enviado para
# o Firestore — é só uma marca local, para nunca confundir progresso de duas
# contas diferentes no mesmo aparelho).
var ultimo_user_id: String = ""

const CAMINHO_SAVE_LOCAL = "user://salvamento_local.json"
const INTERVALO_TENTATIVA_SINCRONIZACAO := 30.0 # segundos entre tentativas automáticas

func _ready() -> void:
	# Sempre que o jogo abrir, tenta resgatar os últimos dados salvos no celular
	carregar_progresso_local()

	# Timer de fundo: se ficar com progresso pendente (ex: sem internet no meio
	# do jogo), continua tentando reenviar periodicamente sem precisar de um
	# novo login — cobre o caso da internet voltar durante a sessão.
	var timer_sincronizacao := Timer.new()
	timer_sincronizacao.wait_time = INTERVALO_TENTATIVA_SINCRONIZACAO
	timer_sincronizacao.autostart = true
	timer_sincronizacao.timeout.connect(_on_timer_sincronizacao_timeout)
	add_child(timer_sincronizacao)

func _on_timer_sincronizacao_timeout() -> void:
	tentar_sincronizar_com_nuvem()

# Gera um pacote compacto contendo todas as variáveis atuais
func gerar_dicionario_completo() -> Dictionary:
	return {
		"username": username,
		"pais": pais,
		"data_nascimento": data_nascimento,
		"data_criacao": data_criacao,
		"moedas_coletadas": moedas_coletadas,
		"progresso_fases": progresso_fases,
		"skins_inventario": skins_inventario
	}

# Recebe os dados brutos vindos da nuvem (Firebase) e atualiza o jogo local
func atualizar_dados_da_nuvem(dados_nuvem: Dictionary) -> void:
	if dados_nuvem.has("username"): username = dados_nuvem["username"]
	if dados_nuvem.has("pais"): pais = dados_nuvem["pais"]
	if dados_nuvem.has("data_nascimento"): data_nascimento = dados_nuvem["data_nascimento"]
	if dados_nuvem.has("data_criacao"): data_criacao = dados_nuvem["data_criacao"]
	if dados_nuvem.has("moedas_coletadas"): moedas_coletadas = dados_nuvem["moedas_coletadas"]
	if dados_nuvem.has("progresso_fases"): progresso_fases = dados_nuvem["progresso_fases"]
	if dados_nuvem.has("skins_inventario"): skins_inventario = dados_nuvem["skins_inventario"]

	_migrar_skins_inventario()
	sincronizado = true
	_gravar_arquivo_no_disco()
	print("✅ RAM e Arquivo Local atualizados com os dados da nuvem!")

# Modifica o progresso de uma fase (Pode ser chamado de dentro de qualquer fase)
# Retorna true se o score desta tentativa é um novo recorde da fase (deve ir pro ranking)
func registrar_fim_de_fase(fase_id: String, moedas_coletadasnafase: int, tempo: float, score: int) -> bool:
	# 1. Verifica se já existe registro dessa fase para manter os melhores recordes
	var melhor_tempo = tempo
	var melhor_score = score
	var eh_novo_recorde = true

	if progresso_fases.has(fase_id):
		var antigo = progresso_fases[fase_id]
		if antigo.has("melhor_tempo") and antigo["melhor_tempo"] > 0 and antigo["melhor_tempo"] < tempo:
			melhor_tempo = antigo["melhor_tempo"] # Mantém o menor tempo
		if antigo.has("melhor_score") and antigo["melhor_score"] > score:
			melhor_score = antigo["melhor_score"] # Mantém o maior score
			eh_novo_recorde = false
		# 2. Atualiza as moedas globais com (Moedas coletadas na fase - Moedas já pegas antes)
		var moedas_ganhas = (moedas_coletadasnafase - antigo.get("moedas_fase", 0))
		if moedas_ganhas < 0:
			moedas_ganhas = 0
		moedas_coletadas += moedas_ganhas
		print("💰 Coletou %d moedas e foram descontadas %d por já ter pego antes" % [moedas_coletadasnafase, antigo.get("moedas_fase", 0)])
	else:
		moedas_coletadas += moedas_coletadasnafase
		print("💰 Coletou %d moedas e nenhuma moeda foi descontada" % [moedas_coletadasnafase])

	progresso_fases[fase_id] = {
		"completada": true,
		"melhor_tempo": melhor_tempo,
		"melhor_score": melhor_score,
		"moedas_fase": moedas_coletadasnafase
	}

	# 3. Altera o status para pendente de sincronização externa
	sincronizado = false
	_gravar_arquivo_no_disco()

	print("🏁 Fim de fase %s: totaldemoedas=%d, score=%d, novo_recorde=%s" % [fase_id, moedas_coletadas, score, eh_novo_recorde])

	# 4. Tenta despachar em segundo plano para o Firebase (falha em silêncio se
	# estiver offline — o timer de fundo e o próximo login tentam de novo)
	tentar_sincronizar_com_nuvem()

	return eh_novo_recorde

# ==================== 🎽 LOJA DE SKINS ====================

# Compra (se ainda não tiver) e equipa uma skin. Retorna false se não tiver
# moedas suficientes — nesse caso nada é alterado.
func comprar_e_equipar_skin(skin_id: String, preco: int) -> bool:
	if not skins_inventario.has(skin_id):
		skins_inventario[skin_id] = {"comprada": false, "equipada": false}

	if not skins_inventario[skin_id].get("comprada", false):
		if moedas_coletadas < preco:
			return false
		moedas_coletadas -= preco
		skins_inventario[skin_id]["comprada"] = true

	for chave in skins_inventario.keys():
		skins_inventario[chave]["equipada"] = false
	skins_inventario[skin_id]["equipada"] = true

	sincronizado = false
	_gravar_arquivo_no_disco()
	tentar_sincronizar_com_nuvem()
	return true

# Retorna o identificador da skin atualmente equipada (ex: "Default", "Gold")
func obter_skin_equipada() -> String:
	for chave in skins_inventario.keys():
		if skins_inventario[chave].get("equipada", false):
			return chave
	return "Default"

# ==================== 🚪 LOGOUT ====================

# Chamado ao clicar em "Sair" — ANTES de derrubar a sessão no FirebaseManager
# (precisa do auth_token ainda válido para conseguir sincronizar). Dá uma
# última chance de enviar qualquer progresso pendente (ex: uma compra feita
# segundos antes, cujo envio em segundo plano ainda não tinha terminado) e só
# então decide: se ficou tudo sincronizado, zera os dados locais — assim
# evitamos que o progresso de um jogador "vaze" para a conta da próxima
# pessoa que fizer login neste mesmo dispositivo. Se mesmo assim não
# conseguir sincronizar (sem internet), mantém os dados locais em vez de
# descartar progresso que ainda não foi salvo em lugar nenhum.
func logout_local() -> void:
	if not sincronizado:
		print("📤 Progresso pendente encontrado no logout — tentando sincronizar antes de sair...")
		await tentar_sincronizar_com_nuvem()

	if sincronizado:
		_resetar_para_padrao()
	else:
		print("⚠️ Logout com progresso pendente (sem internet) — mantendo dados locais até sincronizar.")

func _resetar_para_padrao() -> void:
	username = "Jogador"
	pais = ""
	data_nascimento = ""
	data_criacao = ""
	moedas_coletadas = 0
	progresso_fases = {}
	skins_inventario = {
		"Default": {"comprada": true, "equipada": true}
	}
	sincronizado = true
	ultimo_user_id = ""
	_gravar_arquivo_no_disco()

# Tenta enviar o progresso pendente para o Firestore. Só marca como
# sincronizado se a nuvem realmente confirmar o recebimento — se falhar
# (sem internet, token expirado etc.) o progresso continua marcado como
# pendente e será tentado de novo automaticamente.
func tentar_sincronizar_com_nuvem() -> void:
	if sincronizado:
		return

	# Já existe um envio em andamento (ex: disparado automaticamente ao
	# comprar uma skin) — espera ele terminar em vez de desistir na hora,
	# senão um logout logo em seguida acha (erradamente) que não sincronizou.
	while _sincronizando:
		await get_tree().create_timer(0.2).timeout
	if sincronizado:
		return

	if FirebaseManager.auth_token.is_empty():
		print("📡 Jogador jogando em conta local/offline. Dados salvos apenas no dispositivo.")
		return

	_sincronizando = true
	print("🔄 Tentando enviar progresso pendente para o Firebase...")
	var sucesso = await FirebaseManager.enviar_dados_para_o_firestore(gerar_dicionario_completo())
	if sucesso:
		sincronizado = true
		_gravar_arquivo_no_disco()
		print("✅ Progresso sincronizado com a nuvem!")
	else:
		print("⚠️ Sem conexão com a nuvem agora. Vamos tentar de novo em breve.")
	_sincronizando = false

# ==================== 💾 OPERAÇÕES EM ARQUIVO LOCAL (OFFLINE) ====================

func _gravar_arquivo_no_disco() -> void:
	var arquivo = FileAccess.open(CAMINHO_SAVE_LOCAL, FileAccess.WRITE)
	if arquivo:
		var pacote = {
			"sincronizado": sincronizado,
			"ultimo_user_id": ultimo_user_id,
			"dados": gerar_dicionario_completo()
		}
		arquivo.store_string(JSON.stringify(pacote))
		arquivo.close()

func carregar_progresso_local() -> void:
	if not FileAccess.file_exists(CAMINHO_SAVE_LOCAL):
		print("ℹ️ Nenhum save local encontrado. Iniciando jogo limpo.")
		return
		
	var arquivo = FileAccess.open(CAMINHO_SAVE_LOCAL, FileAccess.READ)
	if arquivo:
		var texto = arquivo.get_as_text()
		arquivo.close()
		
		var pacote = JSON.parse_string(texto)
		if pacote != null and pacote.has("dados"):
			sincronizado = pacote.get("sincronizado", true)
			ultimo_user_id = pacote.get("ultimo_user_id", "")
			var d = pacote["dados"]
			
			if d.has("username"): username = d["username"]
			if d.has("pais"): pais = d["pais"]
			if d.has("data_nascimento"): data_nascimento = d["data_nascimento"]
			if d.has("data_criacao"): data_criacao = d["data_criacao"]
			if d.has("moedas_coletadas"): moedas_coletadas = d["moedas_coletadas"]
			if d.has("progresso_fases"): progresso_fases = d["progresso_fases"]
			if d.has("skins_inventario"): skins_inventario = d["skins_inventario"]

			_migrar_skins_inventario()
			print("💾 Dados locais carregados com sucesso do dispositivo!")

# Corrige saves antigos que usavam "skin_default.png" como chave da skin
# padrão (formato descontinuado) — sem isso, o jogo lê uma skin inexistente
# e o CharactersData não encontra stats, deixando o personagem com SPEED 0.
func _migrar_skins_inventario() -> void:
	if skins_inventario.has("skin_default.png"):
		var info = skins_inventario["skin_default.png"]
		skins_inventario.erase("skin_default.png")
		if not skins_inventario.has("Default"):
			skins_inventario["Default"] = info

# Chamado logo após um login OU cadastro bem-sucedido, com o UID de quem
# acabou de autenticar. Precisa saber QUEM está logando pra não confundir
# contas: se o dispositivo tinha dados pendentes de uma OUTRA conta (ex: o
# jogo foi fechado sem clicar em "Sair"), esses dados NÃO pertencem a quem
# está logando agora — descartamos antes de continuar, em vez de acidentalmente
# enviá-los pra nuvem em nome da conta errada.
# Só tratamos como "progresso offline legítimo pra enviar" quando o dono
# anterior do save local é vazio (nunca logou neste device) ou é a própria
# conta que está logando agora.
func sincronizar_apos_login(novo_user_id: String) -> void:
	if ultimo_user_id != "" and ultimo_user_id != novo_user_id:
		print("⚠️ Este dispositivo tinha dados de outra conta (%s) — descartando antes de continuar com %s." % [ultimo_user_id, novo_user_id])
		_resetar_para_padrao()

	ultimo_user_id = novo_user_id

	if not sincronizado:
		print("📤 Progresso offline pendente encontrado — enviando para a nuvem antes de baixar...")
		await tentar_sincronizar_com_nuvem()
	else:
		await FirebaseManager.baixar_dados_do_firestore()

	_gravar_arquivo_no_disco()
