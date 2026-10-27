extends Badguy
class_name FlyingSnowball

# MileTux

# Flying Snowball - A basic badguy that moves up and down in the air.
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

var flight_tween:Tween
var tween_paused = false
var finished_starting_move = false # I dont even know what im doing anymore

func _ready() -> void:
	$TuxDetector.connect("area_entered", _on_tux_detector_area_entered)
	$TuxDetector.connect("body_entered", _on_tux_detector_body_entered)
	
	$TuxLeftDetector.connect("body_entered", _on_tld_body_entered)
	$TuxRightDetector.connect("body_entered", _on_trd_body_entered)
	
	$Image.play("flying")
	
	if direction == 1:
		$Image.flip_h = true
	else:
		$Image.flip_h = false
		
	move()
	
	super()

func _physics_process(delta: float) -> void:
	if current_state == BadguyStates.DEAD:
		stop_flight_tween()
	
	if Global.paused:
		velocity = Vector2.ZERO
		return
	
	if current_state == BadguyStates.DEAD:
		if not is_on_floor():
			velocity += get_gravity() * delta
		
		move_and_slide()
	else:
		velocity.y = 0

func flip_direction():
	direction = -direction

func move():
	if current_state == BadguyStates.DEAD:
		return
	
	var start_pos = global_position
	var tween = create_tween()
	flight_tween = tween
	
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_method(move_to_tween_position, start_pos, start_pos + Vector2(0, -64), 0.75)
	
	await tween.finished
	
	if current_state == BadguyStates.DEAD:
		return
	
	var tween_2 = create_tween()
	flight_tween = tween_2
	tween_2.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween_2.set_trans(Tween.TRANS_SINE)
	tween_2.set_ease(Tween.EASE_IN_OUT)
	tween_2.set_loops()
	
	tween_2.tween_method(move_to_tween_position, start_pos + Vector2(0, -64), start_pos + Vector2(0, 64), 1.5)
	tween_2.tween_method(move_to_tween_position, start_pos + Vector2(0, 64), start_pos + Vector2(0, -64), 1.5)

func move_to_tween_position(target: Vector2):
	if current_state == BadguyStates.DEAD:
		stop_flight_tween()
		return
	
	var motion = target - global_position
	
	if not motion.is_zero_approx():
		move_and_collide(motion)

func stop_flight_tween():
	if flight_tween != null and flight_tween.is_valid():
		flight_tween.kill()
	
	flight_tween = null

func _on_tux_detector_area_entered(area):
	if Global.paused:
		return
	
	if area.is_in_group("Stomp"):
		if current_state == BadguyStates.DEAD:
			return
		
		if not Global.tux_star_invincible:
			if get_tux_stomp(area.get_parent(), true):
				bouncybouncebouncingsnowball = true
				area.get_parent().position.y -= 1
				$TuxDetector.set_deferred("monitoring", false)
				area.get_parent().stomp_bounce()
				death_squish()
				set_deferred("bouncybouncebouncingsnowball", false)
		else:
			death_fall(false)

func _on_tux_detector_body_entered(body):
	if current_state == BadguyStates.DEAD or Global.paused:
		return
	
	if body.is_in_group("Player"):
		await get_tree().create_timer(0.02).timeout # HACK: HACK: HACK: HACK
		interact(body)
	
	if body.is_in_group("Badguy"):
		if not body == self:
			if body.kill_other_enemies:
				death_fall(false)
			if body.kill_self_on_touching_enemy:
				body.death_fall(true)

func death_squish():
	if current_state == BadguyStates.DEAD or Global.paused:
		return
	
	current_state = BadguyStates.DEAD
	$TuxDetector.set_deferred("monitoring", false)
	$TuxDetector.set_deferred("monitorable", false)
	$TuxLeftDetector.set_deferred("monitoring", false)
	$TuxLeftDetector.set_deferred("monitorable", false)
	$TuxRightDetector.set_deferred("monitoring", false)
	$TuxRightDetector.set_deferred("monitorable", false)
	set_collision_layer_value(4, true)
	set_collision_layer_value(3, false)
	set_collision_mask_value(3, false)
	velocity.y = 0
	$Squish.play()
	$Image.play("squished")
	await get_tree().create_timer(death_time).timeout
	queue_free()

func interact(tux):
	if current_state == BadguyStates.DEAD or Global.paused or bouncybouncebouncingsnowball:
		return
	
	if not Global.tux_star_invincible and not get_tux_stomp(tux, false):
		held_badguy_check(true, tux)
	elif Global.tux_star_invincible and not get_tux_stomp(tux, false):
		death_fall(false)
	elif not Global.tux_star_invincible and get_tux_stomp(tux, false):
		death_squish()

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
