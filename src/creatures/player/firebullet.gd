extends CharacterBody2D

# MileTux

# Fire Bullet - A fire bullet that the player shoots. It harms badguys.
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

var speed = 600.0 # float because of warning
var jump_height = 300.0 # float because of warning

var how_many_bounces = 3
var bounces = 0

var direction = 1

var previous_velocity_y = 0.0 # float because of warning
var was_on_floor = false

func _ready() -> void:
	add_to_group("Firebullet")
	$Image.play("default")
	velocity.x = speed * direction
	$Detector.connect("body_entered", _on_something_detected)
	velocity.y = 0

func set_direction_speed(who:CharacterBody2D):
	direction = TuxManager.direction
	if TuxManager.direction == 1:
		if who.velocity.x >= 1:
			speed = speed + who.velocity.x / 2
	else:
		if who.velocity.x <= -1:
			speed = speed - who.velocity.x / 2
	
	if who.velocity.y <= 0:
		speed = speed - who.velocity.y

func _physics_process(delta: float) -> void:
	if Global.paused:
		velocity.x = 0
		velocity.y = 0
		return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if is_on_floor() and not was_on_floor:
		velocity.y = -previous_velocity_y
		bounces += 1
		print(bounces)
	
	if velocity.y > 0:
		previous_velocity_y = velocity.y
	
	was_on_floor = is_on_floor()
	
	if bounces >= how_many_bounces or is_on_wall() or is_on_ceiling() or not $Notifier.is_on_screen():
		queue_free()
	
	move_and_slide()

func _on_something_detected(body):
	if body.is_in_group("Badguy") and not Global.paused:
		if body.flammable and body.current_state == Badguy.BadguyStates.ALIVE:
			if body is Iceblock:
				body.death_fall(true)
			else:
				body.death_fall(false)
		
			queue_free()
