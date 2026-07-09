extends Node

# Sinais para avisar as telas (UI) quando algo acontecer
signal login_concluido(sucesso: bool, mensagem: String)
signal cadastro_concluido(sucesso: bool, mensagem: String)
signal dados_nuvem_carregados(sucesso: bool)
signal dados_nuvem_salvos(sucesso: bool)
signal senha_alterada(sucesso: bool, mensagem: String)

# CONFIGURAÇÕES DO SEU FIREBASE (carregadas do arquivo .env na raiz do projeto, nunca commitadas)
var API_KEY: String = ""
var PROJECT_ID: String = ""

# Variáveis de sessão do jogador logado
var auth_token: String = ""       # idToken — expira em ~1h
var refresh_token: String = ""    # token longevo, usado pra restaurar a sessão (login persistente)
var user_id: String = ""
var email_usuario: String = ""

func _ready() -> void:
	_carregar_variaveis_de_ambiente()

# Lê o .env na raiz do projeto e preenche API_KEY/PROJECT_ID.
# O .env nunca é commitado (está no .gitignore) — veja .env.example para o formato esperado.
func _carregar_variaveis_de_ambiente() -> void:
	# Tenta o .env padrão; se não existir (no build web pro itch.io o arquivo
	# precisou ser renomeado para index.env, pois dotfiles não entram no export),
	# cai para o index.env.
	var caminho_env := "res://.env"
	if not FileAccess.file_exists(caminho_env):
		caminho_env = "res://index.env"

	if not FileAccess.file_exists(caminho_env):
		push_error("Nenhum arquivo de ambiente (.env / index.env) encontrado! Copie .env.example e preencha com suas chaves do Firebase.")
		return

	var arquivo = FileAccess.open(caminho_env, FileAccess.READ)
	if not arquivo:
		push_error("Não foi possível abrir o arquivo de ambiente.")
		return

	while not arquivo.eof_reached():
		var linha = arquivo.get_line().strip_edges()
		if linha.is_empty() or linha.begins_with("#"):
			continue

		var partes = linha.split("=", true, 1)
		if partes.size() != 2:
			continue

		var chave = partes[0].strip_edges()
		var valor = partes[1].strip_edges().trim_prefix("\"").trim_suffix("\"")

		match chave:
			"FIREBASE_API_KEY": API_KEY = valor
			"FIREBASE_PROJECT_ID": PROJECT_ID = valor

	arquivo.close()

	if API_KEY.is_empty() or PROJECT_ID.is_empty():
		push_error("FIREBASE_API_KEY ou FIREBASE_PROJECT_ID ausente/vazio no .env!")

# ==================== 🔐 SISTEMA DE AUTENTICAÇÃO ====================

# Função para cadastrar uma nova conta por E-mail e Senha
func cadastrar_com_email(email: String, senha: String) -> void:
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + API_KEY
	var body = JSON.stringify({
		"email": email,
		"password": senha,
		"returnSecureToken": true
	})
	
	var resposta = await _fazer_requisicao_http(url, [], HTTPClient.METHOD_POST, body)
	if resposta.has("localId"): # Se retornou um ID local, deu certo!
		user_id = resposta["localId"]
		auth_token = resposta["idToken"]
		refresh_token = resposta.get("refreshToken", "")
		email_usuario = resposta["email"]
		emit_signal("cadastro_concluido", true, "Conta criada com sucesso!")
	else:
		var erro_msg = _traduzir_erro_firebase(resposta)
		emit_signal("cadastro_concluido", false, erro_msg)

# Função para fazer Login
func fazer_login_com_email(email: String, senha: String) -> void:
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + API_KEY
	var body = JSON.stringify({
		"email": email,
		"password": senha,
		"returnSecureToken": true
	})
	
	var resposta = await _fazer_requisicao_http(url, [], HTTPClient.METHOD_POST, body)
	if resposta.has("localId"):
		user_id = resposta["localId"]
		auth_token = resposta["idToken"]
		refresh_token = resposta.get("refreshToken", "")
		email_usuario = resposta["email"]
		emit_signal("login_concluido", true, "Login efetuado com sucesso!")
	else:
		var erro_msg = _traduzir_erro_firebase(resposta)
		emit_signal("login_concluido", false, erro_msg)

# Altera a senha da conta logada
func alterar_senha(nova_senha: String) -> void:
	if auth_token.is_empty():
		emit_signal("senha_alterada", false, "Você precisa estar logado para alterar a senha.")
		return

	var url = "https://identitytoolkit.googleapis.com/v1/accounts:update?key=" + API_KEY
	var body = JSON.stringify({
		"idToken": auth_token,
		"password": nova_senha,
		"returnSecureToken": true
	})

	var resposta = await _fazer_requisicao_http(url, [], HTTPClient.METHOD_POST, body)
	if resposta.has("idToken"):
		auth_token = resposta["idToken"] # O Firebase invalida o token antigo ao trocar a senha
		if resposta.has("refreshToken"):
			refresh_token = resposta["refreshToken"]
		emit_signal("senha_alterada", true, "Senha alterada com sucesso!")
	else:
		var erro_msg = _traduzir_erro_firebase(resposta)
		emit_signal("senha_alterada", false, erro_msg)

# Restaura a sessão a partir do refresh token salvo no dispositivo (login
# persistente). Troca o refresh token por um idToken novo no endpoint de token
# seguro do Firebase. Retorna true se conseguiu. OBS: essa resposta NÃO traz o
# email — quem chama (PlayerData) restaura o email salvo localmente.
func restaurar_sessao(token: String) -> bool:
	if token.is_empty() or API_KEY.is_empty():
		return false

	var url = "https://securetoken.googleapis.com/v1/token?key=" + API_KEY
	var headers = ["Content-Type: application/x-www-form-urlencoded"]
	var body = "grant_type=refresh_token&refresh_token=" + token.uri_encode()

	var resposta = await _fazer_requisicao_http(url, headers, HTTPClient.METHOD_POST, body)
	if resposta.has("id_token") and resposta.has("user_id"):
		auth_token = resposta["id_token"]
		user_id = resposta["user_id"]
		refresh_token = resposta.get("refresh_token", token)
		return true
	return false

# Encerra a sessão do jogador logado (dados locais/offline permanecem no dispositivo)
func fazer_logout() -> void:
	auth_token = ""
	refresh_token = ""
	user_id = ""
	email_usuario = ""

# ==================== ☁️ SISTEMA DE BANCO DE DADOS (FIRESTORE) ====================

# Baixa as moedas, fases e skins da nuvem e injeta no PlayerData
func baixar_dados_do_firestore() -> void:
	if user_id.is_empty(): return
	
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/usuarios/%s" % [PROJECT_ID, user_id]
	var headers = ["Authorization: Bearer " + auth_token]
	
	var resposta = await _fazer_requisicao_http(url, headers, HTTPClient.METHOD_GET)
	
	if resposta.has("fields"):
		# Converte o formato do Firebase para um Dicionário normal da Godot
		var dados_limpos = _firestore_para_dicionario(resposta)
		PlayerData.atualizar_dados_da_nuvem(dados_limpos)
		emit_signal("dados_nuvem_carregados", true)
	elif _documento_nao_existe(resposta):
		# Conta nova: o documento ainda não existe → cria o primeiro save com o local.
		print("Documento não encontrado. Criando primeiro registro do jogador na nuvem...")
		await enviar_dados_para_o_firestore(PlayerData.gerar_dicionario_completo())
		emit_signal("dados_nuvem_carregados", true)
	else:
		# Erro de rede/permissão (NÃO é "documento inexistente"): NÃO enviamos o
		# local por cima, pra não arriscar sobrescrever um Firebase mais avançado.
		push_warning("FirebaseManager: falha ao baixar da nuvem — envio cancelado pra não sobrescrever o Firebase.")
		emit_signal("dados_nuvem_carregados", false)

# Distingue "documento ainda não existe" (seguro criar o primeiro save) de um
# erro de rede/permissão (onde NÃO se deve enviar o local por cima da nuvem).
# O Firestore devolve 404/NOT_FOUND quando o documento não existe.
func _documento_nao_existe(resposta: Dictionary) -> bool:
	if not resposta.has("error"):
		return false # sem "fields" e sem "error" = resposta inesperada → não arrisca
	var err = resposta["error"]
	if err is Dictionary:
		return err.get("status", "") == "NOT_FOUND" or int(err.get("code", 0)) == 404
	return false

# Envia os dados locais da memória RAM para o Firebase.
# Retorna true só quando a nuvem realmente confirma o recebimento — quem
# controla a flag "sincronizado" (PlayerData) depende desse retorno ser
# confiável para não marcar como sincronizado algo que falhou (ex: offline).
func enviar_dados_para_o_firestore(dados_godot: Dictionary) -> bool:
	if user_id.is_empty() or auth_token.is_empty():
		emit_signal("dados_nuvem_salvos", false)
		return false

	# Usamos o método PATCH com updateMask para atualizar campos existentes ou criar se não existir
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/usuarios/%s" % [PROJECT_ID, user_id]
	var headers = [
		"Authorization: Bearer " + auth_token,
		"Content-Type: application/json"
	]

	# Transforma o dicionário limpo da Godot no formato Tipado do Firebase (NoSQL)
	var dados_formatados = _dicionario_para_firestore(dados_godot)
	var body = JSON.stringify(dados_formatados)

	var resposta = await _fazer_requisicao_http(url, headers, HTTPClient.METHOD_PATCH, body)
	if resposta.has("fields"):
		emit_signal("dados_nuvem_salvos", true)
		return true
	else:
		emit_signal("dados_nuvem_salvos", false)
		return false

# ==================== 🏆 RANKING POR FASE ====================
# Cada fase tem sua própria coleção pública ("ranking_fase_01", "ranking_fase_02"...)
# contendo só username/score/tempo (nunca o documento completo do jogador).

# Grava (sobrescreve) o melhor resultado do jogador logado para uma fase

func enviar_ranking_da_fase(fase_id: String, score: int, tempo: int) -> bool:
	if user_id.is_empty() or auth_token.is_empty():
		print("⚠️ Ranking não enviado: jogador não está logado.")
		return false

	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/ranking_%s/%s" % [PROJECT_ID, fase_id, user_id]
	var headers = [
		"Authorization: Bearer " + auth_token,
		"Content-Type: application/json"
	]
	var dados = {
		"username": PlayerData.username,
		"score": score,
		"tempo": tempo
	}
	var body = JSON.stringify(_dicionario_para_firestore(dados))
	print("📤 Enviando ranking (%s): score=%d tempo=%d..." % [fase_id, score, tempo])
	var resposta = await _fazer_requisicao_http(url, headers, HTTPClient.METHOD_PATCH, body)
	if resposta.has("fields"):
		print("✅ Ranking da %s enviado com sucesso!" % fase_id)
		return true
	else:
		push_error("❌ Falha ao enviar ranking da %s: %s" % [fase_id, JSON.stringify(resposta)])
		return false

# Busca as melhores colocações de uma fase, ordenadas por score (maior
# primeiro) e, em caso de empate, por tempo (menor primeiro).
#
# O desempate por tempo é feito aqui no cliente, não no Firestore: pedir pro
# Firestore ordenar por dois campos (score E tempo) exigiria criar um índice
# composto manualmente no console pra cada coleção "ranking_fase_XX". Em vez
# disso, buscamos um buffer maior que o necessário (só ordenado por score,
# que já tem índice automático) e resolvemos o empate por tempo em GDScript
# antes de cortar pro tamanho pedido.
func buscar_ranking_da_fase(fase_id: String, limite: int = 7) -> Array:
	if auth_token.is_empty(): return []
	
	var buffer := maxi(limite * 4, 20)

	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents:runQuery" % PROJECT_ID
	var headers = [
		"Authorization: Bearer " + auth_token,
		"Content-Type: application/json"
	]
	var query = {
		"structuredQuery": {
			"from": [{"collectionId": "ranking_" + fase_id}],
			"orderBy": [{"field": {"fieldPath": "score"}, "direction": "DESCENDING"}],
			"limit": buffer
		}
	}
	var body = JSON.stringify(query)

	var http_node = HTTPRequest.new()
	add_child(http_node)
	var erro = http_node.request(url, headers, HTTPClient.METHOD_POST, body)
	if erro != OK:
		http_node.queue_free()
		return []

	var resultado = await http_node.request_completed
	http_node.queue_free()

	var response_body = resultado[3].get_string_from_utf8()
	var json_parsed = JSON.parse_string(response_body)
	if typeof(json_parsed) != TYPE_ARRAY:
		push_error("❌ Falha ao buscar ranking da %s. Resposta do Firestore: %s" % [fase_id, response_body])
		return []

	var ranking: Array = []
	for item in json_parsed:
		if not (item is Dictionary) or not item.has("document"):
			continue
		var doc = item["document"]
		var dados = _firestore_para_dicionario(doc)
		var partes_nome = String(doc.get("name", "")).split("/")
		dados["user_id"] = partes_nome[partes_nome.size() - 1]
		ranking.append(dados)
		
	ranking.sort_custom(_comparar_posicao_ranking)
	if ranking.size() > limite:
		ranking = ranking.slice(0, limite)

	return ranking
	
	# Critério de posição: maior score primeiro; em caso de empate, menor tempo primeiro.
func _comparar_posicao_ranking(a: Dictionary, b: Dictionary) -> bool:
	var score_a = a.get("score", 0)
	var score_b = b.get("score", 0)
	if score_a != score_b:
		return score_a > score_b
	return a.get("tempo", 0) < b.get("tempo", 0)

# ==================== 🛠️ FUNÇÕES AUXILIARES / MOTORES INTERNOS ====================

# Motor genérico assíncrono para fazer qualquer requisição de internet na Godot 4
func _fazer_requisicao_http(url: String, headers: Array, metodo: HTTPClient.Method, body: String = "") -> Dictionary:
	var http_node = HTTPRequest.new()
	add_child(http_node)
	
	var erro = http_node.request(url, headers, metodo, body)
	if erro != OK:
		http_node.queue_free()
		return {"error": {"message": "Erro de conexão de rede."}}
		
	var resultado = await http_node.request_completed
	http_node.queue_free()
	
	var response_body = resultado[3].get_string_from_utf8()
	var json_parsed = JSON.parse_string(response_body)
	
	if json_parsed != null:
		return json_parsed
	return {}

# Traduz as mensagens técnicas e chatas do Firebase para o jogador entender
func _traduzir_erro_firebase(resposta: Dictionary) -> String:
	if resposta.has("error") and resposta["error"].has("message"):
		var msg = resposta["error"]["message"]
		if "EMAIL_EXISTS" in msg: return "Este e-mail já está cadastrado!"
		if "INVALID_EMAIL" in msg: return "Formato de e-mail inválido!"
		if "INVALID_LOGIN_CREDENTIALS" in msg: return "E-mail ou senha incorretos!"
		if "WEAK_PASSWORD" in msg: return "A senha deve ter pelo menos 6 caracteres!"
		if "TOKEN_EXPIRED" in msg or "INVALID_ID_TOKEN" in msg: return "Sua sessão expirou. Faça login novamente."
		if "USER_NOT_FOUND" in msg or "USER_DISABLED" in msg: return "Conta não encontrada ou desativada."
		return msg
	return "Erro desconhecido ao conectar com o servidor."

# CONVERSOR: Pega o JSON do Firebase Firestore e limpa em um Dicionário normal do GDScript
func _firestore_para_dicionario(firestore_doc: Dictionary) -> Dictionary:
	var resultado = {}
	if not firestore_doc.has("fields"): return resultado
	var fields = firestore_doc["fields"]
	for k in fields.keys():
		resultado[k] = _limpar_valor_firestore(fields[k])
	return resultado

func _limpar_valor_firestore(f_val: Dictionary):
	if f_val.has("stringValue"): return f_val["stringValue"]
	elif f_val.has("integerValue"): return int(f_val["integerValue"])
	elif f_val.has("doubleValue"): return float(f_val["doubleValue"])
	elif f_val.has("booleanValue"): return bool(f_val["booleanValue"])
	elif f_val.has("mapValue"):
		var res = {}
		if f_val["mapValue"].has("fields"):
			var m_fields = f_val["mapValue"]["fields"]
			for k in m_fields.keys():
				res[k] = _limpar_valor_firestore(m_fields[k])
		return res
	return null

# CONVERSOR: Pega um Dicionário limpo da Godot e envelopa no formato NoSQL Firestore
func _dicionario_para_firestore(dict_godot: Dictionary) -> Dictionary:
	var fields = {}
	for k in dict_godot.keys():
		fields[k] = _envelopar_valor_firestore(dict_godot[k])
	return {"fields": fields}

func _envelopar_valor_firestore(val):
	if typeof(val) == TYPE_STRING: return {"stringValue": val}
	# integerValue precisa ir como STRING no REST do Firestore (int64 em texto);
	# mandar número cru pode ser recusado. Na leitura, int("123") resolve de volta.
	elif typeof(val) == TYPE_INT: return {"integerValue": str(val)}
	elif typeof(val) == TYPE_FLOAT: return {"doubleValue": val}
	elif typeof(val) == TYPE_BOOL: return {"booleanValue": val}
	elif typeof(val) == TYPE_DICTIONARY:
		var map_fields = {}
		for k in val.keys():
			map_fields[k] = _envelopar_valor_firestore(val[k])
		return {"mapValue": {"fields": map_fields}}
	return {"nullValue": null}
