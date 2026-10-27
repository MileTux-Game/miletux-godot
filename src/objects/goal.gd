extends Area2D

# MileTux

# Goal - Starts a cutscene when the player touches it or half-pauses 
# the game. Both things end the level after the music is done.

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

@export_enum("End Sequence", "Stop Tux") var type = 0
@export_file("*.ogg") var leveldone_song = "res://data/music/leveldone.ogg"

func _ready() -> void:
	connect("body_entered", _on_something_detected)

func _on_something_detected(body):
	if not body.is_in_group("Player"):
		return
	
	match(type):
		0: # End Sequence
			if not Global.tux_reached_end:
				Global.tux_reached_end = true
				body.in_cutscene = true
				body.auto_walk = true
				body.auto_walk_speed = body.walk_speed
				body.velocity.x = body.walk_speed # HACK because I just want to fix this problem quickly because all my other attempts have failed
				print(body.auto_walk_speed)
				print(body.walk_speed)
				print(body.velocity.x)
				body.duck = false
				body.skid = false
				body.can_take_damage = false
				body.get_star_lite()
				body.stop_star_music()
				body.change_image_direction(1)
				Music.stream = load(leveldone_song)
				Music.play()
				Global.level_song = leveldone_song # HACK that will probably break something in the future
				Engine.time_scale = 0.5
				await Music.finished
				Signals.level_finished.emit()
		1: # Stop Tux
			if not Global.tux_reached_end:
				Global.tux_reached_end = true
				body.get_star_lite()
				Global.paused = true
				body.velocity = Vector2.ZERO
				Music.stream = load(leveldone_song)
				Music.play()
				Global.level_song = leveldone_song # Again, HACK!!!!!
				await Music.finished
				Signals.level_finished.emit()
			else:
				Global.paused = true
				body.velocity = Vector2.ZERO
