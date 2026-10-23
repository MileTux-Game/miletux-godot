extends StaticBody2D
class_name Block

# MileTux

# Block - The class containing things used by every type of block.
# Copyright (C) 2006 Matthias Braun <matze@braunis.de>
# Copyright (C) 2026 Sophie Ball <sophieballvaesea@proton.me>
#
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

enum ItemDirections
{
	LEFT,
	RIGHT
}

@export_category("Generic")
@export var bonus = false
@export var brick = false
@export_enum("Coin", "Fire Flower", "Tux Doll", "Star", "Nothing") var content = 0
@export var hidden_block = false

var hidden_block_activated = false

@export var empty = false
var bump = false

var tux_on_left = false
var tux_on_right = false

const coin_scene = preload("res://src/objects/coin.tscn")
const egg_scene = preload("res://src/objects/powerup/egg.tscn")
const ff_scene = preload("res://src/objects/powerup/fire_flower.tscn")
const td_scene = preload("res://src/objects/powerup/tux_doll.tscn")
const star_scene = preload("res://src/objects/powerup/star.tscn")

const brick_particles_scene = preload("res://src/particles/brick_particles.tscn")

func _ready() -> void:
	if not brick:
		$Image.play("normal")
	
	if hidden_block:
		$Image.visible = false
		$Collision.one_way_collision = true
		$Collision.one_way_collision_direction = Vector2.UP
	
	if empty:
		$Image.play("empty")
	
	$DetectorLeft.connect("body_entered", _on_dl_body_entered)
	$DetectorRight.connect("body_entered", _on_dr_body_entered)
	$DetectorDown.connect("body_entered", _on_dd_body_entered)
	$Animation.connect("animation_finished", _on_bump_finished)

func _on_dd_body_entered(body):
	if Global.paused:
		return
	
	if body.is_in_group("Player") and not empty and body.velocity.y <= 0:
		if body.previous_position.y <= global_position.y:
			return
		
		if not body.dead or not body.is_on_floor():
			turn_empty("up_down")
			
			if hidden_block:
				$Image.visible = true
				$Collision.set_deferred("one_way_collision", false)
				hidden_block_activated = true
			
			if body.global_position.x < global_position.x + 16:
				spawn_item(ItemDirections.RIGHT)
			elif body.global_position.x > global_position.x + 16:
				spawn_item(ItemDirections.LEFT)
			elif body.global_position.x == global_position.x + 16:
				spawn_item(ItemDirections.RIGHT)
	elif body.is_in_group("Player") and empty and body.velocity.y >= 0 and not body.dead:
		$BrickSound.play()
	
	if body.is_in_group("Badguy") and not empty:
		if body.kill_other_enemies and not body.current_iceblock_state == body.IceblockStates.HELD:
			turn_empty("up_down")
			if body.global_position.x < global_position.x + 16:
				spawn_item(ItemDirections.RIGHT)
			elif body.global_position.x > global_position.x + 16:
				spawn_item(ItemDirections.LEFT)
			elif body.global_position.x == global_position.x + 16:
				spawn_item(ItemDirections.RIGHT)

func _on_dl_body_entered(body):
	if Global.paused:
		return
	
	if hidden_block and not hidden_block_activated:
		return
	
	if body.is_in_group("Badguy") and not empty:
		if body.kill_other_enemies and not body.current_iceblock_state == body.IceblockStates.HELD:
			turn_empty("up_down")
			spawn_item(ItemDirections.RIGHT)
	elif body.is_in_group("Badguy") and empty:
		if body.kill_other_enemies and not body.current_iceblock_state == body.IceblockStates.HELD:
			$BrickSound.play()

func _on_dr_body_entered(body):
	if Global.paused:
		return
	
	if hidden_block and not hidden_block_activated:
		return
	
	if body.is_in_group("Badguy") and not empty:
		if body.kill_other_enemies and not body.current_iceblock_state == body.IceblockStates.HELD:
			turn_empty("up_down")
			spawn_item(ItemDirections.LEFT)
	elif body.is_in_group("Badguy") and empty:
		if body.kill_other_enemies and not body.current_iceblock_state == body.IceblockStates.HELD:
			$BrickSound.play()

func turn_empty(animation_name:String):
	if Global.paused:
		return
	
	bump = true
	$Animation.play(animation_name)
	empty = true
	
	$Image.play("empty")
	
	detect_enemies()

func spawn_item(direction:ItemDirections):
	if Global.paused:
		return
	
	match(content):
		0: # Coin
			spawn_coin()
		1: # Fire Flower
			if TuxManager.current_state == TuxManager.TuxStates.SMALL:
				var egg = egg_scene.instantiate()
				get_tree().current_scene.call_deferred("add_child", egg)
				$Upgrade.play()
				egg.position = self.position + Vector2(16, 16)
				if direction == ItemDirections.LEFT:
					egg.call_deferred("spawn_from_block", -1)
				elif direction == ItemDirections.RIGHT:
					egg.call_deferred("spawn_from_block", 1)
			else:
				spawn_fire_flower()
		2: # Tux Doll
			var tux_doll = td_scene.instantiate()
			get_tree().current_scene.call_deferred("add_child", tux_doll)
			$Upgrade.play()
			tux_doll.global_position = self.global_position - Vector2(0, 32)
			if direction == ItemDirections.LEFT:
				tux_doll.direction = -1
			else:
				tux_doll.direction = 1
		3: # Star
			var star = star_scene.instantiate()
			get_tree().current_scene.call_deferred("add_child", star)
			$Upgrade.play()
			star.global_position = self.global_position - Vector2(0, 32)
			if direction == ItemDirections.LEFT:
				star.call_deferred("spawn_from_block", -1)
			else:
				star.call_deferred("spawn_from_block", 1)
		4: # Nothing
			$BrickSound.play()

func _on_bump_finished(anim_name:StringName):
	if Global.paused:
		return
	
	if anim_name == "up_down":
		bump = false
	elif anim_name == "up_gone":
		spawn_brick_particles()
		queue_free()

func spawn_coin():
	if Global.paused:
		return
	
	var coin = coin_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", coin)
	$Coin.play()
	coin.global_position = self.global_position + Vector2(16, 16)
	coin.set_from_block()

func spawn_fire_flower():
	if Global.paused:
		return
	
	var fire_flower = ff_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", fire_flower)
	$Upgrade.play()
	fire_flower.position = self.position
	fire_flower.call_deferred("spawn_from_block")

# TODO: Fully move this out of this script as Brick Block overrides it for the snow variable!!!!
func spawn_brick_particles():
	if Global.paused:
		return
	
	var brick_particles = brick_particles_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", brick_particles)
	brick_particles.global_position = self.global_position

func detect_enemies():
	if Global.paused or hidden_block:
		return
	
	for body in $DetectorUp.get_overlapping_bodies():
		if body.is_in_group("Badguy"):
			if body is Iceblock:
				body.death_fall(true)
			else:
				body.death_fall(false)
