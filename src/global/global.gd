extends Node

# MileTux

# Global - Global variables along with saving and loading.
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

# The saving / loading stuff is from Tux Mystery, which is why AnatolyStev 
# is credited above, as he did all that I think.

# Level
var level_width = 100
var tile_size = 32
var level_song = ""
var level_name = ""
var level_author = ""
var checkpoint_reached = false
var checkpoint_position = Vector2(0, 0)
var completed_levels = []
var current_level:String

# Tux
var coins:int = 0
var tux_star_invincible = false
var tux_reached_end = false
var tux_state = TuxManager.current_state

# It exists!
var first_worldmap = "res://src/levels/world1/worldmap.tscn"

# Worldmap
var worldmap_name:String
var width_of_worldmap = 0
var height_of_worldmap = 0
var dot_level_name:String
var global_spawn_name = "main"
var use_spawn_point = false
var completed_worldmaps = []
var current_worldmap:String

# Worldmap Tux
var tux_wm_x = 0.0
var tux_wm_y = 0.0

# Options
var particles = true
var level_hud = true
var debug:bool = false:
	set(value):
		debug = value
		set_debug()
var music_playing = true
var sounds = true

## Used instead of get_tree().paused in most cases because it allows animations to continue.
## [br]
## Don't use for worldmap stuff yet.
var paused = false # TODO: Find out why Tux's animations stop when he reaches the goal, likely has something to do with this function.

# Save file
var save_version = 1
var save_path = "user://save.json"

func _ready() -> void:
	load_data()

func set_debug():
	if debug:
		print("debug: " + str(debug))
		OS.alert("Debug Mode is enabled!\nRead the GitHub repository's wiki for more information.", "Debug Mode")
	else:
		print("debug: " + str(debug)) # there will be more stuff here soon

func _process(_delta: float) -> void:
	if debug:
		if Input.is_action_just_pressed("save_debug"):
			save_data()
		if Input.is_action_just_pressed("load_debug"):
			load_data()

func save_data():
	var data = {
		"completed_levels": completed_levels,
		"coins": coins,
		"current_worldmap": current_worldmap,
		"completed_worldmaps": completed_worldmaps,
		"tux_wm_x": tux_wm_x,
		"tux_wm_y": tux_wm_y,
		"particles": particles,
		"level_hud": level_hud,
		"debug": debug,
		"music_playing": music_playing,
		"sounds": sounds,
		"save_version": save_version,
		"tux_state": tux_state
	}
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	
	if file:
		var json_string = JSON.stringify(data)
		file.store_string(json_string)
		file.close()
		print("Game saved!")

func load_data():
	if not FileAccess.file_exists(save_path):
		return
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var data = json.get_data()
			if data.has("completed_levels"):
				completed_levels = data["completed_levels"]
			if data.has("coins"):
				coins = data["coins"]
			if data.has("current_worldmap"):
				current_worldmap = data["current_worldmap"]
			if data.has("completed_worldmaps"):
				completed_worldmaps = data["completed_worldmaps"]
			if data.has("tux_wm_x"):
				tux_wm_x = data["tux_wm_x"]
			if data.has("tux_wm_y"):
				tux_wm_y = data["tux_wm_y"]
			if data.has("particles"):
				particles = data["particles"]
			if data.has("level_hud"):
				level_hud = data["level_hud"]
			if data.has("debug"):
				debug = data["debug"]
			if data.has("music_playing"):
				music_playing = data["music_playing"]
			if data.has("sounds"):
				sounds = data["sounds"]
			if data.has("save_version"):
				save_version = data["save_version"]
			if data.has("tux_state"):
				tux_state = data["tux_state"]
				TuxManager.current_state = tux_state
			
			print("Game loaded!")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Global.tux_state = TuxManager.current_state
		get_tree().quit()
