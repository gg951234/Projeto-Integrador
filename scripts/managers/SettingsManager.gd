extends CanvasLayer

# --- Configurações ---
const SETTINGS_PATH := "res://data/settings_default.json"
@onready var main_menu_canvas: CanvasLayer = $"../MainMenuCanvas"

var volumesfx: float = 1.0
var volumemusic: float = 1.0
var brightness: float = 1.0

# --- UI ---
@onready var voltar = $Voltar

var hover_scale: Vector2 = Vector2(1.1, 1.1)
var original_scale: Vector2 = Vector2(1, 1)
var animation_duration: float = 0.2
var tween_type: Tween.EaseType = Tween.EASE_OUT
var tween_trans: Tween.TransitionType = Tween.TRANS_BACK

func _ready() -> void:
	# Carrega as configurações salvas
	carregar()

	# Configura o botão (pivot e sinais de mouse)
	voltar.pivot_offset = voltar.size / 2
	voltar.mouse_entered.connect(_on_button_mouse_entered.bind(voltar))
	voltar.mouse_exited.connect(_on_button_mouse_exited.bind(voltar))
	# O sinal "pressed" do botão deve estar conectado no editor ou pode ser conectado aqui:
	voltar.pressed.connect(_on_voltar_pressed)

# --- Persistência ---
func salvar() -> void:
	var dados := {
		"volumesfx": volumesfx,
		"volumemusic": volumemusic,
		"brightness": brightness,
	}
	var arquivo := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(JSON.stringify(dados))
		arquivo.close()

func carregar() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		print("Arquivo de configurações não existe")
		return
	var arquivo := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if arquivo:
		var dados = JSON.parse_string(arquivo.get_as_text())
		arquivo.close()
		if dados:
			volumesfx = dados.get("volumesfx", 1.0)
			volumemusic = dados.get("volumemusic", 1.0)
			brightness = dados.get("brightness", 1.0)

func get_configs() -> Dictionary:
	return {
		"volumesfx": volumesfx,
		"volumemusic": volumemusic,
		"brightness": brightness,
	}

# --- Animações do botão ---
func _on_button_mouse_entered(button: Button) -> void:
	animate_scale(button, hover_scale)

func _on_button_mouse_exited(button: Button) -> void:
	animate_scale(button, original_scale)

func animate_scale(button: Button, target_scale: Vector2) -> void:
	var buttontween = create_tween()
	buttontween.set_ease(tween_type)
	buttontween.set_trans(tween_trans)
	buttontween.tween_property(button, "scale", target_scale, animation_duration)

# --- Ação do botão Voltar ---
func _on_voltar_pressed() -> void:
	visible = false
	main_menu_canvas.visible = true
