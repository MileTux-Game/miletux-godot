extends Node2D
class_name Level

# MileTux

# Level - A scene where the player jumps and runs across platforms.

# Copyright (C) 2006 Matthias Braun <matze@braunis.de>
# Copyright (C) 2026 Sophie Ball <sophieballvaesea@proton.me>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the license or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should've received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

var last_tux_x = 0.0 # float

@export_file("*.ogg") var music = "res://data/music/chipdisko.ogg"

@export var width = 100

@export var level_name = "No Name"
@export var level_creator = "No Author"
@export var main_spawnpoint = "main"

@export var manual_camera = false
@export var autoscroll_speed = 80

@export var snow = false
@export var clouds = false

const hud = preload("res://src/hud/hud.tscn")

func _ready() -> void:
	Fade.turn_invisible()
	find_spawnpoint()
	TuxManager.current_state = Global.tux_state
	Global.level_song = music
	var hud_2 = hud.instantiate()
	get_tree().current_scene.add_child(hud_2)
	Global.level_width = width * Global.tile_size
	$Camera.limit_left = 0
	$Camera.limit_top = 0
	$Camera.limit_bottom = 480
	$Camera.limit_right = Global.level_width
	
	if manual_camera:
		$Camera.global_position.x = get_window().size.x * 0.5
	else:
		$Camera.global_position = $Tux.global_position
	
	Signals.connect("level_finished", _on_level_finished)
	
	last_tux_x = $Tux.global_position.x
	
	if snow:
		if not get_node_or_null("Snow") == null:
			$Snow.visible = true
			$Snow.global_position.x = $Camera.global_position.x
	if clouds:
		if not get_node_or_null("Clouds") == null:
			$Clouds.visible = true
			$Clouds.global_position.x = $Camera.global_position.x

func find_spawnpoint():
	if not Global.checkpoint_reached or Global.coins <= 25:
		for spawn in get_tree().get_nodes_in_group("TuxSpawnpoint"):
			if spawn.spawnpoint_name == main_spawnpoint:
				$Tux.global_position = spawn.global_position + Vector2(13, -8)
	else:
		$Tux.global_position = Global.checkpoint_position - Vector2(13, -8)

func _physics_process(delta: float) -> void:
	if Global.paused:
		return
	
	# TODO: Move this code to the camera's script.
	if not get_node_or_null("Tux") == null:
		if not manual_camera:
			var player_delta_x = $Tux.global_position.x - last_tux_x
			last_tux_x = $Tux.global_position.x
			
			var max_look_ahead = minf(maxf($Camera.look_ahead, 0.0), get_viewport_rect().size.x * 0.1)
			
			$Camera.current_look_ahead = clampf($Camera.current_look_ahead + player_delta_x * 0.8, -max_look_ahead, max_look_ahead)
			$Camera.global_position.x = ($Tux.global_position.x + $Camera.current_look_ahead)
		else:
			$Camera.global_position.x += autoscroll_speed * delta
	
	if snow:
		if not get_node_or_null("Snow") == null:
			$Snow.global_position.x = $Camera.global_position.x
	if clouds:
		if not get_node_or_null("Clouds") == null:
			$Clouds.global_position.x = $Camera.global_position.x

func _on_level_finished():
	Global.paused = false
	Engine.time_scale = 1.0
	Global.tux_star_invincible = false
	Global.checkpoint_reached = false
	Global.tux_reached_end = false
	if scene_file_path not in Global.completed_levels:
		Global.completed_levels.append(scene_file_path)
	
	if Global.current_worldmap == "":
		get_tree().change_scene_to_file("res://src/menu/main_menu.tscn")
	else:
		get_tree().change_scene_to_file(Global.current_worldmap)
