extends RichTextLabel
class_name TextScroll

# It's a class because I'm lazy.

@export var text_speed = 30
@export var add_remove_speed = 5
@export var position_to_change_scene = -608
@export var unique_scene = true

## Only applies to text_scrolls with unique_scene being true.
@export_file("*.tscn") var scene_to_change_to = "res://src/menu/main_menu.tscn"

func _process(delta: float) -> void:
	global_position.y -= text_speed * delta
	
	# TODO: Move input stuff to _input function (v0.1.0 rc 1?)
	if Input.is_action_pressed("player_down"):
		text_speed += add_remove_speed
	elif Input.is_action_pressed("player_up"):
		text_speed -= add_remove_speed
	
	if Input.is_action_just_pressed("player_jump") or global_position.y <= position_to_change_scene:
		if unique_scene:
			get_tree().change_scene_to_file(scene_to_change_to)
		else:
			if Global.current_worldmap == "":
				get_tree().change_scene_to_file(Global.first_worldmap)
			else:
				get_tree().change_scene_to_file(Global.current_worldmap)
	
	if global_position.y >= 500:
		global_position.y = 500
