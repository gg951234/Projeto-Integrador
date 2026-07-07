extends Node

# Emitido após a tentativa de login automático no boot (login persistente).
signal sessao_restaurada(sucesso: bool)

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

# Login persistente: refresh token do Firebase + email, salvos no dispositivo.
# Enquanto houver token_login, o jogo restaura a sessão sozinho ao abrir e
# sincroniza com o Firebase. Só enviamos progresso pra nuvem quando há sessão
# (token) — assim um dispositivo sem login nunca sobrescreve a conta na nuvem.
var token_login: String = ""
var email_login: String = ""

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

	# Login persistente: se há um token salvo, restaura a sessão e sincroniza
	# (merge) automaticamente, sem precisar digitar e-mail/senha de novo.
	if not token_login.is_empty():
		_tentar_login_automatico()

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

# Recebe os dados da nuvem e JUNTA com o local mantendo o MELHOR DE CADA (nunca
# sobrescreve cego) — assim nem o progresso avançado do Firebase nem um avanço
# local offline são perdidos. Não mexe na flag 'sincronizado': quem chama
# (sincronizar_apos_login) decide empurrar o resultado pra nuvem depois.
func atualizar_dados_da_nuvem(dados_nuvem: Dictionary) -> void:
	username = _preferir_nao_vazio(username, str(dados_nuvem.get("username", "")))
	pais = _preferir_nao_vazio(pais, str(dados_nuvem.get("pais", "")))
	data_nascimento = _preferir_nao_vazio(data_nascimento, str(dados_nuvem.get("data_nascimento", "")))
	data_criacao = _preferir_nao_vazio(data_criacao, str(dados_nuvem.get("data_criacao", "")))
	# moedas: fica com o maior saldo
	moedas_coletadas = maxi(moedas_coletadas, int(dados_nuvem.get("moedas_coletadas", 0)))
	# fases: união, o melhor de cada fase
	progresso_fases = _merge_progresso(progresso_fases, dados_nuvem.get("progresso_fases", {}))
	# skins: união (comprada = OR)
	skins_inventario = _merge_skins(skins_inventario, dados_nuvem.get("skins_inventario", {}))

	_migrar_skins_inventario()
	_gravar_arquivo_no_disco()
	print("🔀 Progresso local e da nuvem juntados (o melhor de cada).")

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
	token_login = ""
	email_login = ""
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
			"token_login": token_login,
			"email_login": email_login,
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
			token_login = pacote.get("token_login", "")
			email_login = pacote.get("email_login", "")
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
	# Guarda o token de login (persistência) + email vindos do FirebaseManager.
	token_login = FirebaseManager.refresh_token
	email_login = FirebaseManager.email_usuario

	# SEMPRE baixa a nuvem e JUNTA com o local (merge — ver atualizar_dados_da_nuvem):
	# nunca sobrescreve cego, então o progresso avançado do Firebase nunca é
	# perdido, e avanços feitos offline também são mantidos.
	await FirebaseManager.baixar_dados_do_firestore()

	# Depois do merge, envia o resultado (o melhor de cada) de volta pra nuvem,
	# pra ela também ficar com os avanços locais.
	sincronizado = false
	await tentar_sincronizar_com_nuvem()

	_gravar_arquivo_no_disco()


# ==================== 🔓 LOGIN AUTOMÁTICO (PERSISTENTE) ====================

# Chamado no boot quando há token_login salvo: restaura a sessão no Firebase e
# sincroniza (merge). NÃO apaga o token se falhar (pode ser só falta de internet
# ou token temporariamente inválido) — tenta de novo no próximo boot.
func _tentar_login_automatico() -> void:
	print("🔑 Token de login encontrado — restaurando sessão...")
	var ok := await FirebaseManager.restaurar_sessao(token_login)
	if ok:
		FirebaseManager.email_usuario = email_login
		token_login = FirebaseManager.refresh_token  # o refresh token pode rotacionar
		await sincronizar_apos_login(FirebaseManager.user_id)
		print("✅ Sessão restaurada automaticamente (%s)." % email_login)
		sessao_restaurada.emit(true)
	else:
		print("⚠️ Não deu pra restaurar a sessão (token expirado ou sem internet). Mantendo o token pra tentar depois.")
		sessao_restaurada.emit(false)


# ==================== 🔀 MERGE (JUNTAR O MELHOR DE CADA) ====================

func _preferir_nao_vazio(local: String, nuvem: String) -> String:
	return local if not local.is_empty() else nuvem

# Une o progresso de fases dos dois lados, mantendo o melhor de cada fase.
func _merge_progresso(local: Dictionary, nuvem: Dictionary) -> Dictionary:
	var res: Dictionary = local.duplicate(true)
	for fase in nuvem.keys():
		var c = nuvem[fase]
		if not (c is Dictionary):
			continue
		if not res.has(fase):
			res[fase] = c.duplicate(true)
			continue
		var l: Dictionary = res[fase]
		l["completada"] = bool(l.get("completada", false)) or bool(c.get("completada", false))
		l["melhor_score"] = maxi(int(l.get("melhor_score", 0)), int(c.get("melhor_score", 0)))
		l["melhor_tempo"] = _menor_tempo(int(l.get("melhor_tempo", 0)), int(c.get("melhor_tempo", 0)))
		l["moedas_fase"] = maxi(int(l.get("moedas_fase", 0)), int(c.get("moedas_fase", 0)))
		res[fase] = l
	return res

# Menor tempo é o melhor recorde; 0 significa "sem recorde ainda".
func _menor_tempo(a: int, b: int) -> int:
	if a <= 0: return b
	if b <= 0: return a
	return mini(a, b)

# Une os inventários de skins: uma skin fica "comprada" se comprada em qualquer lado.
func _merge_skins(local: Dictionary, nuvem: Dictionary) -> Dictionary:
	var res: Dictionary = local.duplicate(true)
	for skin in nuvem.keys():
		var c = nuvem[skin]
		if not (c is Dictionary):
			continue
		if not res.has(skin):
			res[skin] = c.duplicate(true)
		else:
			res[skin]["comprada"] = bool(res[skin].get("comprada", false)) or bool(c.get("comprada", false))
	return res
