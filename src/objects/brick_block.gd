@tool
extends Block

# MileTux

# Brick Block - The script used by all brick blocks.
# Copyright (C) 2009 Ingo Ruhnke <grumbel@gmail.com> (Adding him to the 
# credits part just to be safe as he was in the SuperTux brick.cpp 
# copyright header)
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

@export var empty_brick = true:
	set(value):
		empty_brick = value
		reload_graphics()

@export var how_many_hits = 5
@export var snow = false:
	set(value):
		snow = value
		reload_graphics()

func _ready() -> void:
	if not Engine.is_editor_hint():
		brick = true
		reload_graphics()
		super()

func reload_graphics():
	if snow:
		$Image.play("snow")
	else:
		$Image.play("normal")
	
	if Engine.is_editor_hint():
		if empty_brick:
			$CoinImage.visible = false
		else:
			$CoinImage.visible = true
	else:
		$CoinImage.visible = false

func _physics_process(_delta: float) -> void:
	if not empty_brick and how_many_hits <= 0 and not Engine.is_editor_hint():
		if Global.paused:
			return
		
		$Image.play("empty")

# TODO: Update this code to the way Bonus Blocks work (Must be done before beta 2 release!)
# Reason why I'm not doing it right now: I'm lazy :3
func _on_dd_body_entered(body):
	if not Engine.is_editor_hint():
		if Global.paused:
			return
		
		if body.is_in_group("Player") and not body.dead:
			if body.dead:
				return
			
			if empty_brick:
				$BrickSound.play()
				if TuxManager.current_state == TuxManager.TuxStates.SMALL:
					$Animation.play("up_down")
					bump = true
					detect_enemies()
				else:
					$Animation.play("up_gone")
					bump = true
					detect_enemies()
			else:
				$BrickSound.play()
				if how_many_hits > 0:
					$Animation.play("up_down")
					how_many_hits -= 1
					spawn_item(ItemDirections.LEFT)
					bump = true
					detect_enemies()

func _on_dl_body_entered(body):
	if Global.paused or Engine.is_editor_hint():
		return
	
	if body.is_in_group("Badguy"):
		if body.kill_other_enemies and not body.current_iceblock_state == body.IceblockStates.HELD:
			$BrickSound.play()
			
			if empty_brick:
				$Animation.play("up_gone")
				bump = true
				detect_enemies()
			else:
				if how_many_hits > 0:
					$Animation.play("up_down")
					how_many_hits -= 1
					spawn_item(ItemDirections.LEFT)
					bump = true
					detect_enemies()

func _on_dr_body_entered(body):
	if Global.paused or Engine.is_editor_hint():
		return
	
	if body.is_in_group("Badguy"):
		if body.kill_other_enemies and not body.current_iceblock_state == body.IceblockStates.HELD:
			$BrickSound.play()
			
			if empty_brick:
				$Animation.play("up_gone")
				bump = true
				detect_enemies()
			else:
				if how_many_hits > 0:
					$Animation.play("up_down")
					how_many_hits -= 1
					spawn_item(ItemDirections.LEFT)
					bump = true
					detect_enemies()

func spawn_item(_direction:ItemDirections):
	if Global.paused:
		return
	
	if content == 0: # Coin
		spawn_coin()
	else:
		print("Can't do that.")

func spawn_brick_particles():
	if Global.paused:
		return
	
	var brick_particles = brick_particles_scene.instantiate()
	
	if snow:
		brick_particles.snow = true
	
	get_tree().current_scene.call_deferred("add_child", brick_particles)
	brick_particles.global_position = self.global_position
