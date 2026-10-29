# MileTux

# Worldmap - An RPG-like worldmap scene where the player enters different levels.

# Copyright (C) 2006 Matthias Braun <matze@braunis.de>
# Copyright (C) 2026 Sophie Ball <sophieballvaesea@proton.me>
# Copyright (C) 2026 AnatolyStev

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

extends Node2D
class_name Worldmap

@export var license = "CC-BY-SA 4.0"
@export var worldmap_width = 100
@export var worldmap_height = 100
@export_file("*.ogg") var music = "res://data/music/salcon.ogg"

var levels:Array = []
var rocks:Array = []

const hud = preload("res://src/hud/worldmap_hud.tscn")

# for the level node
@onready var tux = $WorldmapTux

func _ready() -> void:
	Global.current_worldmap = scene_file_path
	
	Global.width_of_worldmap = worldmap_width * Global.tile_size
	Global.height_of_worldmap = worldmap_height * Global.tile_size
	
	$WorldmapTux/Camera2D.limit_bottom = Global.height_of_worldmap
	$WorldmapTux/Camera2D.limit_right = Global.width_of_worldmap
	
	Music.stream = load(music)
	Music.play()
	
	tux.current_state = Global.tux_state
	tux.reload_player()
	
	var hud_2 = hud.instantiate()
	get_tree().current_scene.add_child(hud_2)
	
	levels = get_tree().get_nodes_in_group("Level")
	rocks = get_tree().get_nodes_in_group("Rock")
	
	# this seems a little weird but i'm tired
	if Global.use_spawn_point:
		if get_spawn_point(Global.global_spawn_name):
			if Global.current_worldmap == scene_file_path:
				tux.position = get_spawn_point(Global.global_spawn_name).position
			else:
				set_tux_position_after_check()
		else:
			set_tux_position_after_check()
		
		Global.use_spawn_point = false
	else:
		set_tux_position_after_check()
	
	check_rock_unlocks() # The Rock
	check_levels_completed() # The Level

func section_completed(section:int):
	for level in levels:
		if level.level_section == section and not level.level_scene.resource_path in Global.completed_levels: # Breaking rules
			return false
	
	return true

func check_rock_unlocks():
	for rock in rocks:
		if rock.gone:
			continue
		
		if section_completed(rock.rock_section):
			rock.remove_rock()

# TODO: rename
func check_levels_completed():
	for level in levels:
		if level.level_scene.resource_path in Global.completed_levels:
			level.complete_level()

# SPAWN
func get_spawn_point(name_of_spawn:String):
	for spawn in get_tree().get_nodes_in_group("Spawnpoint"):
		if spawn.spawn_name == name_of_spawn:
			return spawn
	
	return null

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Global.tux_state = TuxManager.current_state
		
		Global.tux_wm_x = tux.position.x
		Global.tux_wm_y = tux.position.y
		
		Global.save_data()
		
		get_tree().quit()

func set_tux_position_after_check():
	if Global.tux_wm_x == 0 and Global.tux_wm_y == 0:
		tux.position = Vector2($MainWorldmapSpawnPoint.position.x, $MainWorldmapSpawnPoint.position.y)
	else:
		tux.position = Vector2(Global.tux_wm_x, Global.tux_wm_y)
