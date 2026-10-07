extends BossManager

@export var boss_type_override: String = "Risadinha"
@onready var skill1sound: String = "res://assets/sounds/bosses/Risadinha/Laugh.mp3"
var levelroot = null

func _ready():
	skill_executors[1] = _skill_1
	boss_type = boss_type_override
	super._ready()
	await get_tree().process_frame
	
	if str(get_tree().root) == "LevelRoot":
		levelroot = get_tree().root
	else:
		levelroot = GameManager.currentlevelroot

func _skill_1() -> void:
	if not levelroot:
		print("No Levelroot")
		return
	# Toca animação correspondente (skill_<id>)
	var anim_name = "skill_2"
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		var frame_count = animated_sprite.sprite_frames.get_frame_count(anim_name)
		var fps = animated_sprite.sprite_frames.get_animation_speed(anim_name)
		var anim_length = frame_count / fps if fps > 0 else 1.0
		
		# Aguarda o tempo exato da animação com Timer
		await get_tree().create_timer(anim_length).timeout
		
		if currentstate == States.SKILL_ACTIVE:
			animated_sprite.play("idle_down")
	else:
		push_warning("Animação ", anim_name, " não encontrada para o boss ", boss_type)
		
	AudioManager.tocar_sfxglobal(skill1sound)
