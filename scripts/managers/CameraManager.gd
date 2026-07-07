extends Node

## Referência à câmera – deve ser definida via set_camera()
@export var camera: Camera2D

func _ready():
	# Não busca automaticamente, aguarda definição via set_camera()
	print("CameraManager: aguardando definição da câmera via set_camera().")

## Define a câmera manualmente
func set_camera(new_camera: Camera2D) -> void:
	camera = new_camera
	if camera:
		if camera.is_inside_tree():
			camera.make_current()
		print("CameraManager: câmera atualizada para: ", camera.name)
	else:
		push_warning("CameraManager: tentativa de definir câmera nula.")

## Define os limites da câmera a partir do nome do nível (usando CameraData)
func set_limits_from_level(level_name: String, transition_duration: float = 0.0) -> void:
	if not camera:
		push_warning("CameraManager: câmera nula, não foi possível definir limites.")
		return
	
	var limits = CameraData.get_limits_for_level(level_name)
	# Monta o dicionário completo (left/top geralmente 0)
	var final_limits = {
		"left": limits.get("left", 0),
		"top": limits.get("top", 0),
		"right": limits.get("right", 0),
		"bottom": limits.get("bottom", 0)
	}
	
	if transition_duration > 0:
		print(final_limits)
		transition_to_limits(final_limits, transition_duration)
	else:
		print(final_limits)
		set_limits(final_limits)

## Ajusta a câmera para mostrar exatamente a área de uma sala definida no CameraData
func set_camera_to_room(room_name: String, duration: float = 0.0, mode: String = "fill") -> void:
	var limits = CameraData.get_limits_for_level(room_name)
	if limits.is_empty():
		push_error("CameraManager: sala '", room_name, "' não encontrada no CameraData.")
		return
	
	var left = limits.get("left", 0)
	var top = limits.get("top", 0)
	var right = limits.get("right", 0)
	var bottom = limits.get("bottom", 0)
	
	# Chama a função interna que faz o trabalho
	_set_camera_to_area(left, top, right, bottom, duration, mode)

## Função interna que aplica os limites e ajusta o zoom/posição
func _set_camera_to_area(left: float, top: float, right: float, bottom: float, duration: float = 0.0, mode: String = "fit", padding: float = 0.0) -> void:
	if not camera:
		push_warning("CameraManager: câmera nula.")
		return
	
	# Define os limites da câmera – conversão para int para evitar NARROWING_CONVERSION
	camera.limit_left = int(left)
	camera.limit_top = int(top)
	camera.limit_right = int(right)
	camera.limit_bottom = int(bottom)
	
	# Calcula o zoom
	var viewport_size = get_viewport().get_visible_rect().size
	var area_width = right - left + padding * 2
	var area_height = bottom - top + padding * 2
	
	var zoom_x = viewport_size.x / area_width
	var zoom_y = viewport_size.y / area_height
	
	var new_zoom: float
	if mode == "fit":
		new_zoom = min(zoom_x, zoom_y)   # mostra tudo, sobra espaço
	else: # "fill"
		new_zoom = max(zoom_x, zoom_y)   # preenche a tela, corta bordas
	
	# Aplica transição
	if duration > 0:
		var tween = create_tween()
		tween.set_parallel(true)
		# tween.tween_property(camera, "global_position", center, duration)
		tween.tween_property(camera, "zoom", Vector2(new_zoom, new_zoom), duration)
	else:
		# camera.global_position = center
		camera.zoom = Vector2(new_zoom, new_zoom)

## Define os limites imediatamente – conversão para int
func set_limits(limits: Dictionary) -> void:
	if not camera:
		push_warning("CameraManager: câmera nula, não foi possível definir limites.")
		return
	camera.limit_left = int(limits.get("left", 0))
	camera.limit_top = int(limits.get("top", 0))
	camera.limit_right = int(limits.get("right", 0))
	camera.limit_bottom = int(limits.get("bottom", 0))

## Aplica transição suave dos limites – garantindo valores int
func transition_to_limits(limits: Dictionary, duration: float = 1.0) -> void:
	if not camera:
		push_warning("CameraManager: câmera nula, não foi possível aplicar transição.")
		return
	
	# Mata qualquer tween anterior
	if camera.has_meta("camera_tween"):
		var old_tween = camera.get_meta("camera_tween")
		if old_tween and old_tween.is_valid() and old_tween.is_running():
			old_tween.kill()
	
	var tween = create_tween()
	tween.set_parallel(true)
	camera.set_meta("camera_tween", tween)
	
	# Obtém os valores atuais (já são int)
	var current_left = camera.limit_left
	var current_top = camera.limit_top
	var current_right = camera.limit_right
	var current_bottom = camera.limit_bottom
	
	if limits.has("left"):
		tween.tween_property(camera, "limit_left", int(limits["left"]), duration).from(int(current_left))
	if limits.has("top"):
		tween.tween_property(camera, "limit_top", int(limits["top"]), duration).from(int(current_top))
	if limits.has("right"):
		tween.tween_property(camera, "limit_right", int(limits["right"]), duration).from(int(current_right))
	if limits.has("bottom"):
		tween.tween_property(camera, "limit_bottom", int(limits["bottom"]), duration).from(int(current_bottom))

## Aplica um shake à câmera
func shake(duration: float = 0.3, intensity: float = 5.0) -> void:
	if not camera:
		return
	var original_offset = camera.offset
	var tween = create_tween()
	var elapsed = 0.0
	var step = 0.02
	
	while elapsed < duration:
		var random_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(camera, "offset", original_offset + random_offset, step).set_trans(Tween.TRANS_SINE)
		elapsed += step
		await tween.finished
		tween.kill()
		tween = create_tween()
	
	tween.tween_property(camera, "offset", original_offset, 0.1).set_trans(Tween.TRANS_SINE)
	await tween.finished
