extends CanvasLayer

signal finished # not needed but nice to have, remove later?

# Whether the level start thing has appeared / is on screen or not
var appeared = false

# Whether the player can leave this screen or not
var player_can_leave = false

# Here so exiting works
var level_variable:PackedScene

# The music (gets set to level music)
var music:String

# Just making sure it's not visible when the game loads...
func _ready() -> void:
	visible = false
	set_tux_animation()

func start_level(level:PackedScene):
	# Check if the level is null, if it is, return :)
	if level == null:
		print("level is null... returning!")
		return
	
	print("Levelstart called")
	
	# Set level_variable to level just so exiting this screen can be done
	level_variable = level
	
	# Instantiate level just to read stuff from it
	var level_thing = level.instantiate()
	
	# Read stuff from level_thing
	Global.level_name = level_thing.level_name
	Global.level_author = level_thing.level_creator
	music = level_thing.music
	
	# Goodbye!
	level_thing.free()
	
	# Set texts
	$LevelName.text = Global.level_name
	$LevelAuthor.text = Global.level_author
	Music.play_song(music)
	
	# Final few things
	appeared = true
	visible = true
	Fade.fade_out(1)
	await Fade.finished
	player_can_leave = true

# Makes it so the player can leave at any time
func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("menu_exit") and player_can_leave:
		player_can_leave = false
		appeared = false
		visible = false
		finished.emit()
		get_tree().call_deferred("change_scene_to_packed", level_variable)

# Just sets the Tux animation
func set_tux_animation():
	if TuxManager.current_state == TuxManager.TuxStates.SMALL:
		$Tux.play("small")
	elif TuxManager.current_state == TuxManager.TuxStates.BIG:
		$Tux.play("big")
	elif TuxManager.current_state == TuxManager.TuxStates.FIRE:
		$Tux.play("fire")
