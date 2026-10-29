# MileTux

# Teleport Dot - When Tux is over it and the player presses enter,
# Tux will be teleported to either a new spawnpoint or a new scene.

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

extends AnimatedSprite2D

# Code is mostly from GodotTux

## Whether the telporter is invisible or not.
@export var invisible:bool = false
## If true, automatically telports Tux when he touches the teleporter.
@export var automatic:bool = false
## Make sure to set this to the worldmap you want! Different export thing than the
## worldmap level dot thing for some reason but I don't want to change it now.
@export_file_path("*.tscn") var worldmap_scene:String
## Message that displays when Tux touches the telporter (unless it's automatic)
@export var message:String = "Where do you want to go today?"
## Make sure to set this to the name of the spawn point you want Tux to go to.
@export var spawn_target:String = "main"

var tux_on_teleporter:bool = false

func _ready() -> void:
	play("default")
	
	$Detector.connect("body_entered", _on_tux_detector_body_entered)
	$Detector.connect("body_exited", _on_tux_detector_body_exited)
	
	if invisible:
		visible = false

func _physics_process(_delta: float) -> void:
	if tux_on_teleporter and not automatic:
		if Input.is_action_just_pressed("menu_accept"):
			teleport()

func _on_tux_detector_body_entered(body) -> void:
	if body.is_in_group("TuxWorldmap"):
		if automatic:
			teleport()
		else:
			tux_on_teleporter = true
			Global.dot_level_name = message # probably a bit of a hack
			Signals.update_level_text.emit()

func _on_tux_detector_body_exited(body) -> void:
	if body.is_in_group("TuxWorldmap") and not automatic:
		tux_on_teleporter = false
		Global.dot_level_name = ""
		Signals.update_level_text.emit()

func teleport():
	Global.global_spawn_name = spawn_target
	Global.use_spawn_point = true
	Global.save_data()
	
	print("Going to new scene: " + worldmap_scene)
	print("Also going to spawn_target: " + spawn_target)
	print("Also, just for fun, here's the Global spawn name. If it's not the same as spawn_target, something's wrong: " + Global.global_spawn_name)
	
	get_tree().change_scene_to_file(worldmap_scene)
