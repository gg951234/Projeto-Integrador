extends CanvasLayer

const SETTINGS_PATH = "user://settings_default.json"
@onready var main_menu_canvas: CanvasLayer = $"../MainMenuCanvas"
@onready var voltar = $Voltar
@onready var music_slider: HSlider = $ConfiguracoesMenu/VBoxContainer/MusicPanel/HSliderMusic
@onready var sfx_slider: HSlider = $ConfiguracoesMenu/VBoxContainer/SFXPanel/HSliderSFX

var volumesfx: float = 1.0
var volumemusic: float = 1.0

var hover_scale: Vector2 = Vector2(1.1, 1.1)
var original_scale: Vector2 = Vector2(1, 1)
var animation_duration: float = 0.2
var tween_type: Tween.EaseType = Tween.EASE_OUT
var tween_trans: Tween.TransitionType = Tween.TRANS_BACK

func _ready() -> void:
	# Carrega as configurações salvas
	carregar()

	# Configura os sliders (max = 1.0, step = 0.1)
	music_slider.max_value = 1.0
	music_slider.step = 0.1
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.1

	# Sincroniza os sliders com os valores carregados
	music_slider.value = volumemusic
	sfx_slider.value = volumesfx

	# --- Conexão dos sinais via script ---
	music_slider.drag_ended.connect(_on_music_slider_ended)
	sfx_slider.drag_ended.connect(_on_sfx_slider_ended)
	music_slider.value_changed.connect(_on_music_slider_value_changed)

	# Configura o botão Voltar (pivot e sinais de mouse)
	voltar.pivot_offset = voltar.size / 2
	voltar.mouse_entered.connect(_on_button_mouse_entered.bind(voltar))
	voltar.mouse_exited.connect(_on_button_mouse_exited.bind(voltar))
	voltar.pressed.connect(_on_voltar_pressed)

# --- Persistência ---
func salvar() -> void:
	var dados := {
		"volumesfx": volumesfx,
		"volumemusic": volumemusic,
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

func get_configs() -> Dictionary:
	return {
		"volumesfx": volumesfx,
		"volumemusic": volumemusic,
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

func _on_voltar_pressed() -> void:
	visible = false
	main_menu_canvas.visible = true

# Music slider: salva apenas se o valor realmente mudou (value_changed == true)
func _on_music_slider_ended(value_changed: bool) -> void:
	if value_changed:
		volumemusic = music_slider.value
		salvar()

# SFX slider: salva apenas se o valor realmente mudou
func _on_sfx_slider_ended(value_changed: bool) -> void:
	if value_changed:
		volumesfx = sfx_slider.value
		salvar()

func _on_music_slider_value_changed(value: float) -> void:
		AudioManager.update_music_volume(value)
