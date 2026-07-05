extends Node

# Dados salvos na RAM (Fonte da Verdade do jogo)
var username: String = "Jogador"
var pais: String = ""
var data_nascimento: String = ""
var data_criacao: String = ""
var moedas_coletadas: int = 0
var progresso_fases: Dictionary = {}
var skins_inventario: Dictionary = {
	"skin_default.png": {"comprada": true, "equipada": true}
}

# Controle de sincronização offline
var sincronizado: bool = true

const CAMINHO_SAVE_LOCAL = "user://salvamento_local.json"

func _ready() -> void:
	# Sempre que o jogo abrir, tenta resgatar os últimos dados salvos no celular
	carregar_progresso_local()

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
	
	sincronizado = true
	_gravar_arquivo_no_disco()
	print("✅ RAM e Arquivo Local atualizados com os dados da nuvem!")

# Modifica o progresso de uma fase (Pode ser chamado de dentro de qualquer fase)
# Retorna true se o score desta tentativa é um novo recorde da fase (deve ir pro ranking)
func registrar_fim_de_fase(fase_id: String, moedas_ganhas: int, tempo: int, score: int) -> bool:
	# 1. Atualiza as moedas globais
	moedas_coletadas += moedas_ganhas

	# 2. Verifica se já existe registro dessa fase para manter os melhores recordes
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

	progresso_fases[fase_id] = {
		"completada": true,
		"melhor_tempo": melhor_tempo,
		"melhor_score": melhor_score,
		"moedas_fase": moedas_ganhas
	}

	# 3. Altera o status para pendente de sincronização externa
	sincronizado = false
	_gravar_arquivo_no_disco()

	# 4. Tenta despachar em segundo plano para o Firebase
	_tentar_sincronizar_com_nuvem()

	return eh_novo_recorde

# Tenta efetuar a sincronização (roda de forma silenciosa)
func _tentar_sincronizar_com_nuvem() -> void:
	if FirebaseManager.auth_token.is_empty():
		print("📡 Jogador jogando em conta local/offline. Dados salvos apenas no dispositivo.")
		return
		
	print("🔄 Tentando enviar progresso para o Firebase...")
	await FirebaseManager.enviar_dados_para_o_firestore(gerar_dicionario_completo())

# ==================== 💾 OPERAÇÕES EM ARQUIVO LOCAL (OFFLINE) ====================

func _gravar_arquivo_no_disco() -> void:
	var arquivo = FileAccess.open(CAMINHO_SAVE_LOCAL, FileAccess.WRITE)
	if arquivo:
		var pacote = {
			"sincronizado": sincronizado,
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
			var d = pacote["dados"]
			
			if d.has("username"): username = d["username"]
			if d.has("pais"): pais = d["pais"]
			if d.has("data_nascimento"): data_nascimento = d["data_nascimento"]
			if d.has("data_criacao"): data_criacao = d["data_criacao"]
			if d.has("moedas_coletadas"): moedas_coletadas = d["moedas_coletadas"]
			if d.has("progresso_fases"): progresso_fases = d["progresso_fases"]
			if d.has("skins_inventario"): skins_inventario = d["skins_inventario"]
			print("💾 Dados locais carregados com sucesso do dispositivo!")

# Função disparada sempre que o jogo detecta que voltou a ter internet após o Login
func verificar_sincronizacao_pendente() -> void:
	if not sincronizado:
		print("🔄 Sincronização pendente detectada no início da sessão. Enviando agora...")
		await FirebaseManager.enviar_dados_para_o_firestore(gerar_dicionario_completo())
		sincronizado = true
		_gravar_arquivo_no_disco()
