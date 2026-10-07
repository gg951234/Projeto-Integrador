extends Node

# Sinais para avisar as telas (UI) quando algo acontecer
signal login_concluido(sucesso: bool, mensagem: String)
signal cadastro_concluido(sucesso: bool, mensagem: String)
signal dados_nuvem_carregados(sucesso: bool)
signal dados_nuvem_salvos(sucesso: bool)
signal senha_alterada(sucesso: bool, mensagem: String)

# Sinal interno usado pela ponte JavaScript (não usar na UI)
signal _js_resposta_pronta(status: int, corpo: String)

# CONFIGURAÇÕES DO SEU FIREBASE (carregadas do arquivo .env na raiz do projeto, nunca commitadas)
var API_KEY: String = ""
var PROJECT_ID: String = ""

# Fallback embutido para quando o .env/index.env NÃO é empacotado no export
const API_KEY_EMBUTIDA := "AIzaSyDIi6fr8gyHo29BtkudWlgYMCHySaBjm1M"
const PROJECT_ID_EMBUTIDO := "heroi-maze"

# Variáveis de sessão do jogador logado
var auth_token: String = ""
var refresh_token: String = ""
var user_id: String = ""
var email_usuario: String = ""

# Callback JS registrado uma única vez (evita recriar a cada requisição)
var _js_callback: JavaScriptObject = null


func _ready() -> void:
	_carregar_variaveis_de_ambiente()
	if OS.has_feature("web"):
		_js_callback = JavaScriptBridge.create_callback(_on_js_xhr_concluido)
		JavaScriptBridge.get_interface("window").godot_xhr_callback = _js_callback


func _carregar_variaveis_de_ambiente() -> void:
	var caminho_env := "res://.env"
	if not FileAccess.file_exists(caminho_env):
		caminho_env = "res://index.env"

	if FileAccess.file_exists(caminho_env):
		var arquivo = FileAccess.open(caminho_env, FileAccess.READ)
		if arquivo:
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

	if API_KEY.is_empty():
		API_KEY = API_KEY_EMBUTIDA
	if PROJECT_ID.is_empty():
		PROJECT_ID = PROJECT_ID_EMBUTIDO

	if API_KEY.is_empty() or PROJECT_ID.is_empty():
		push_error("Firebase sem chaves!")

# ==================== 🔐 AUTENTICAÇÃO ====================

func cadastrar_com_email(email: String, senha: String) -> void:
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + API_KEY
	var body = JSON.stringify({
		"email": email,
		"password": senha,
		"returnSecureToken": true
	})
	var headers = {
		"Content-Type": "application/json",
		"Accept": "application/json"
	}
	var resposta = await _fazer_requisicao_http(url, headers, HTTPClient.METHOD_POST, body)
	if resposta.has("localId"):
		user_id = resposta["localId"]
		auth_token = resposta["idToken"]
		refresh_token = resposta.get("refreshToken", "")
		email_usuario = resposta["email"]
		emit_signal("cadastro_concluido", true, "Conta criada com sucesso!")
	else:
		emit_signal("cadastro_concluido", false, _traduzir_erro_firebase(resposta))


func fazer_login_com_email(email: String, senha: String) -> void:
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + API_KEY
	var body = JSON.stringify({
		"email": email,
		"password": senha,
		"returnSecureToken": true
	})
	var headers = {
		"Content-Type": "application/json",
		"Accept": "application/json"
	}
	var resposta = await _fazer_requisicao_http(url, headers, HTTPClient.METHOD_POST, body)
	if resposta.has("localId"):
		user_id = resposta["localId"]
		auth_token = resposta["idToken"]
		refresh_token = resposta.get("refreshToken", "")
		email_usuario = resposta["email"]
		emit_signal("login_concluido", true, "Login efetuado com sucesso!")
	else:
		emit_signal("login_concluido", false, _traduzir_erro_firebase(resposta))


func alterar_senha(nova_senha: String) -> void:
	if auth_token.is_empty():
		emit_signal("senha_alterada", false, "Você precisa estar logado.")
		return
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:update?key=" + API_KEY
	var body = JSON.stringify({
		"idToken": auth_token,
		"password": nova_senha,
		"returnSecureToken": true
	})
	var headers = {
		"Content-Type": "application/json",
		"Accept": "application/json"
	}
	var resposta = await _fazer_requisicao_http(url, headers, HTTPClient.METHOD_POST, body)
	if resposta.has("idToken"):
		auth_token = resposta["idToken"]
		if resposta.has("refreshToken"):
			refresh_token = resposta["refreshToken"]
		emit_signal("senha_alterada", true, "Senha alterada com sucesso!")
	else:
		emit_signal("senha_alterada", false, _traduzir_erro_firebase(resposta))


func restaurar_sessao(token: String) -> bool:
	if token.is_empty() or API_KEY.is_empty():
		return false
	var url = "https://securetoken.googleapis.com/v1/token?key=" + API_KEY
	var headers = {
		"Content-Type": "application/x-www-form-urlencoded",
		"Accept": "application/json"
	}
	var body = "grant_type=refresh_token&refresh_token=" + token.uri_encode()
	var resposta = await _fazer_requisicao_http(url, headers, HTTPClient.METHOD_POST, body)
	if resposta.has("id_token") and resposta.has("user_id"):
		auth_token = resposta["id_token"]
		user_id = resposta["user_id"]
		refresh_token = resposta.get("refresh_token", token)
		return true
	return false


func fazer_logout() -> void:
	auth_token = ""
	refresh_token = ""
	user_id = ""
	email_usuario = ""

# ==================== ☁️ FIRESTORE ====================

func baixar_dados_do_firestore() -> void:
	if user_id.is_empty(): return
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/usuarios/%s" % [PROJECT_ID, user_id]
	var headers = {
		"Authorization": "Bearer " + auth_token,
		"Accept": "application/json"
	}
	var resposta = await _fazer_requisicao_http(url, headers, HTTPClient.METHOD_GET)
	if resposta.has("fields"):
		var dados_limpos = _firestore_para_dicionario(resposta)
		PlayerData.atualizar_dados_da_nuvem(dados_limpos)
		emit_signal("dados_nuvem_carregados", true)
	elif _documento_nao_existe(resposta):
		print("Documento não encontrado. Criando primeiro registro...")
		await enviar_dados_para_o_firestore(PlayerData.gerar_dicionario_completo())
		emit_signal("dados_nuvem_carregados", true)
	else:
		emit_signal("dados_nuvem_carregados", false)


func _documento_nao_existe(resposta: Dictionary) -> bool:
	if not resposta.has("error"):
		return false
	var err = resposta["error"]
	if err is Dictionary:
		return err.get("status", "") == "NOT_FOUND" or int(err.get("code", 0)) == 404
	return false

func enviar_dados_para_o_firestore(dados_godot: Dictionary) -> bool:
	if user_id.is_empty() or auth_token.is_empty():
		emit_signal("dados_nuvem_salvos", false)
		return false
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/usuarios/%s" % [PROJECT_ID, user_id]
	var headers = {
		"Authorization": "Bearer " + auth_token,
		"Content-Type": "application/json",
		"Accept": "application/json"
	}
	var dados_formatados = _dicionario_para_firestore(dados_godot)
	var body = JSON.stringify(dados_formatados)
	var resposta = await _fazer_requisicao_http(url, headers, HTTPClient.METHOD_PATCH, body)
	if resposta.has("fields"):
		emit_signal("dados_nuvem_salvos", true)
		return true
	else:
		emit_signal("dados_nuvem_salvos", false)
		return false

# ==================== 🏆 RANKING ====================

func enviar_ranking_da_fase(fase_id: String, score: int, tempo: int) -> bool:
	if user_id.is_empty() or auth_token.is_empty():
		print("⚠️ Ranking não enviado: jogador não está logado.")
		return false
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/ranking_%s/%s" % [PROJECT_ID, fase_id, user_id]
	var headers = {
		"Authorization": "Bearer " + auth_token,
		"Content-Type": "application/json",
		"Accept": "application/json"
	}
	var dados = {
		"username": PlayerData.username,
		"score": score,
		"tempo": tempo
	}
	var body = JSON.stringify(_dicionario_para_firestore(dados))
	var resposta = await _fazer_requisicao_http(url, headers, HTTPClient.METHOD_PATCH, body)
	return resposta.has("fields")


func buscar_ranking_da_fase(fase_id: String, limite: int = 7) -> Array:
	if auth_token.is_empty(): return []
	var buffer := maxi(limite * 4, 20)
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents:runQuery" % PROJECT_ID
	var headers = {
		"Authorization": "Bearer " + auth_token,
		"Content-Type": "application/json",
		"Accept": "application/json"
	}
	var query = {
		"structuredQuery": {
			"from": [{"collectionId": "ranking_" + fase_id}],
			"orderBy": [{"field": {"fieldPath": "score"}, "direction": "DESCENDING"}],
			"limit": buffer
		}
	}
	var body = JSON.stringify(query)
	var resposta = await _fazer_requisicao_http(url, headers, HTTPClient.METHOD_POST, body)
	if typeof(resposta) != TYPE_ARRAY:
		return []
	var ranking: Array = []
	for item in resposta:
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


func _comparar_posicao_ranking(a: Dictionary, b: Dictionary) -> bool:
	var score_a = a.get("score", 0)
	var score_b = b.get("score", 0)
	if score_a != score_b:
		return score_a > score_b
	return a.get("tempo", 0) < b.get("tempo", 0)

# ==================== 🛠️ REQUISIÇÃO HTTP ====================

func _fazer_requisicao_http(url: String, headers: Dictionary, metodo: int, body: String = "") -> Variant:
	# Se estiver rodando no navegador, usa JavaScript/XHR (evita bloqueios de CORS/gzip do HTTPRequest nativo em WASM)
	if OS.has_feature("web"):
		return await _fazer_requisicao_http_js(url, headers, metodo, body)
	else:
		return await _fazer_requisicao_http_godot(url, headers, metodo, body)


# Versão usando HTTPRequest do Godot (funciona no desktop, Android, etc)
func _fazer_requisicao_http_godot(url: String, headers: Dictionary, metodo: int, body: String = "") -> Variant:
	var http_node = HTTPRequest.new()
	add_child(http_node)

	var header_array: Array = []
	for key in headers.keys():
		header_array.append(key + ": " + headers[key])

	var erro = http_node.request(url, header_array, metodo, body)
	if erro != OK:
		http_node.queue_free()
		return {"error": {"message": "Erro interno na requisição. Código: " + str(erro)}}

	var resultado = await http_node.request_completed
	http_node.queue_free()

	var status = resultado[1]
	var response_body = resultado[3].get_string_from_utf8()

	if response_body.is_empty():
		return {"error": {"message": "Resposta vazia do servidor (Status " + str(status) + ")"}}

	var json_parsed = JSON.parse_string(response_body)
	if json_parsed != null:
		return json_parsed
	else:
		return {"error": {"message": "Resposta não-JSON: " + response_body}}


# Versão usando XMLHttpRequest via JavaScriptBridge (para exports HTML5/web)
# Usa um callback registrado (não Promise) para que o `await` do GDScript
# realmente espere a resposta chegar, evitando ler dados antes da hora.
func _fazer_requisicao_http_js(url: String, headers: Dictionary, metodo: int, body: String = "") -> Variant:
	var method_str = _metodo_para_string(metodo)

	var js_code = """
		(function() {
			var xhr = new XMLHttpRequest();
			xhr.open('%s', '%s', true);
			var headers = %s;
			for (var key in headers) {
				if (headers.hasOwnProperty(key)) {
					xhr.setRequestHeader(key, headers[key]);
				}
			}
			xhr.onload = function() {
				window.godot_xhr_callback(xhr.status, xhr.responseText);
			};
			xhr.onerror = function() {
				window.godot_xhr_callback(0, '');
			};
			xhr.send(%s);
		})();
	""" % [method_str, url, JSON.stringify(headers), JSON.stringify(body)]

	JavaScriptBridge.eval(js_code)

	# Espera o sinal real disparado pelo callback do JS (garante ordem correta)
	var resultado = await self._js_resposta_pronta
	var status: int = resultado[0]
	var body_str: String = resultado[1]

	if body_str.is_empty():
		return {"error": {"message": "Resposta vazia (Status " + str(status) + ")"}}

	var json_parsed = JSON.parse_string(body_str)
	if json_parsed != null:
		return json_parsed
	else:
		return {"error": {"message": "Resposta não-JSON: " + body_str}}


func _on_js_xhr_concluido(args: Array) -> void:
	var status: int = int(args[0])
	var corpo: String = str(args[1])
	_js_resposta_pronta.emit(status, corpo)


func _metodo_para_string(metodo: int) -> String:
	match metodo:
		HTTPClient.METHOD_GET: return "GET"
		HTTPClient.METHOD_POST: return "POST"
		HTTPClient.METHOD_PUT: return "PUT"
		HTTPClient.METHOD_PATCH: return "PATCH"
		HTTPClient.METHOD_DELETE: return "DELETE"
		_: return "GET"

# ==================== UTILITÁRIOS ====================

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
	elif f_val.has("arrayValue"):
		var arr: Array = []
		if f_val["arrayValue"].has("values"):
			for v in f_val["arrayValue"]["values"]:
				arr.append(_limpar_valor_firestore(v))
		return arr
	elif f_val.has("mapValue"):
		var res = {}
		if f_val["mapValue"].has("fields"):
			var m_fields = f_val["mapValue"]["fields"]
			for k in m_fields.keys():
				res[k] = _limpar_valor_firestore(m_fields[k])
		return res
	return null


func _dicionario_para_firestore(dict_godot: Dictionary) -> Dictionary:
	var fields = {}
	for k in dict_godot.keys():
		fields[k] = _envelopar_valor_firestore(dict_godot[k])
	return {"fields": fields}

func _envelopar_valor_firestore(val):
	if typeof(val) == TYPE_STRING: return {"stringValue": val}
	elif typeof(val) == TYPE_INT: return {"integerValue": str(val)}
	elif typeof(val) == TYPE_FLOAT: return {"doubleValue": val}
	elif typeof(val) == TYPE_BOOL: return {"booleanValue": val}
	elif typeof(val) == TYPE_ARRAY:
		var vals: Array = []
		for item in val:
			vals.append(_envelopar_valor_firestore(item))
		return {"arrayValue": {"values": vals}}
	elif typeof(val) == TYPE_DICTIONARY:
		var map_fields = {}
		for k in val.keys():
			map_fields[k] = _envelopar_valor_firestore(val[k])
		return {"mapValue": {"fields": map_fields}}
	return {"nullValue": null}
