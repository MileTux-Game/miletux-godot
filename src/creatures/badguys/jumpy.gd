extends Badguy
class_name Jumpy

# MileTux

# Jumpy - A badguy that jumps when it hits the floor.
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

var bounce_height = 600

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$TuxDetector.connect("body_entered", _on_tux_detector_body_entered)
	$TuxLeftDetector.connect("body_entered", _on_tld_body_entered)
	$TuxRightDetector.connect("body_entered", _on_trd_body_entered)
	$Image.play("bounce")
	jumpy = true
	super()

func _physics_process(delta: float) -> void:
	if Global.paused:
		velocity = Vector2.ZERO
		return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if is_on_floor():
		velocity.y = -bounce_height
		$Image.play("bounce")
	
	move_and_slide()

func death():
	if current_state == BadguyStates.DEAD or Global.paused:
		return
	
	current_state = BadguyStates.DEAD
	$TuxDetector.set_deferred("monitoring", false)
	$TuxDetector.set_deferred("monitorable", false)
	$TuxLeftDetector.set_deferred("monitoring", false)
	$TuxLeftDetector.set_deferred("monitorable", false)
	$TuxRightDetector.set_deferred("monitoring", false)
	$TuxRightDetector.set_deferred("monitorable", false)
	velocity.x = 0
	velocity.y = 0
	$Collision.set_deferred("disabled", true)
	$Image.flip_v = true
	$Fall.play()

func _on_tux_detector_body_entered(body):
	if Global.paused:
		return
	
	if body.is_in_group("Player"):
		if not Global.tux_star_invincible:
			held_badguy_check(false, body)
		else:
			death_fall(false)
	if body.is_in_group("Badguy"):
		if not body == self:
			if body.kill_other_enemies:
				death_fall(false)
			if body.kill_self_on_touching_enemy:
				body.death_fall(true)

func _on_tld_body_entered(body):
	if Global.paused or current_state == BadguyStates.DEAD:
		return
	
	if body.is_in_group("Player"):
		$Image.flip_h = false

func _on_trd_body_entered(body):
	if Global.paused or current_state == BadguyStates.DEAD:
		return
	
	if body.is_in_group("Player"):
		$Image.flip_h = true
