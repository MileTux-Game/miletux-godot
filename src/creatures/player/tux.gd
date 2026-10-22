extends CharacterBody2D

# MileTux

# Tux - The playable character of MileTux.
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

# Movement
@export var walk_acceleration = 300
@export var run_acceleration = 400
var current_acceleration = 0 # Don't change this! It's automatically set later!
@export var min_jump_height = 512.0 # I turned it into a float. Why? Integer division. Decimal part will be discarded. That's why. (Realized I could get around that with "* 0.5", but it's too late to change that...
@export var max_jump_height = 576
@export var walk_speed = 230
var speed = 0 # Don't change this! It's automatically set later!
@export var run_speed = 320
@export var max_y_speed = 2000
@export var instant_walk_speed = 100
@export var instant_run_speed = 150
var instant_speed = 0 # Don't change this! It's automatically set later!
@export var friction = 1.5

# Skidding
@export var skid_speed = 200
@export var stop_skid_speed = 0
var skid = false

# Ducking
var duck = false

# Held Enemies
var held_object:CharacterBody2D = null
var holding_enemy = false

# Damage
var can_take_damage = true
var inv_frames = 2.0 # TODO: rename to inv_seconds. since it's not frames.
var dead = false
@export var dead_jump = 700
@export var restart_scene_timer = 3.0

# Cutscene
var in_cutscene = false
var auto_walk = false
var auto_walk_speed = 0 # Don't change this! It's automatically set by the things that set auto_walk to true!

# Firebals
@export var max_fireballs_allowed = 2

# Music
@export_file("*.ogg") var invincible_music = "res://data/music/salcon.ogg"

# Other stuff
var was_on_floor = false
var previous_position = Vector2.ZERO

# Collision Shape Stuff
@export_category("Small Tux Collision Shape")
@export var small_collsion_size_y = 29.0
@export var small_collision_position_y = 25.5
@export_category("Big Tux Collision Shape")
@export var big_collision_size_y = 54.0
@export var big_collision_position_y = 13.0

const fire_bullet_scene = preload("res://src/creatures/player/firebullet.tscn")

# For badguys
@onready var stomp_collision = $Stomp/CollisionShape2D
@onready var collision = $Collision

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reload_player()
	play_animation("stand")
	$Animation.play("RESET")
	add_to_group("Player")
	$Stomp.add_to_group("Stomp")
	$StarTimer.connect("timeout", _on_star_timer_timeout)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	previous_position = global_position
	
	# If Tux is not in a cutscene and the game is not paused, stop Tux from going out of bounds through the left of the level.
	if not in_cutscene or not Global.paused:
		if global_position.x < 0:
			global_position.x = 0
	
	# If Tux is not in a cutscene and the game is not paused, if Tux goes below the window size, KILL HIM!!! >:3
	if not in_cutscene or not Global.paused:
		if global_position.y > get_window().size.y:
			die()
	
	# If Tux is not in a cutscene and the game is not paused, stop Tux from going out of bounds through the right of the level.
	if not in_cutscene or not Global.paused:
		if global_position.x > Global.level_width - $Collision.shape.size.x:
			global_position.x = Global.level_width - $Collision.shape.size.x
	
	# If the game is not paused, do gravity stuff (with a few extra checks inside here), if the game is paused, set velocity.y to 0.
	if not Global.paused:
		if (not is_on_floor() and $TileTimer.is_stopped()) or dead: # If Tux isn't on the floor, the tile timer isn't going or Tux is dead, add gravity!
			velocity += get_gravity() * delta
		elif (not is_on_floor() and in_cutscene):
			velocity += get_gravity() * delta # HACK fix for end goals
	else:
		velocity.y = 0
	
	# If Tux isn't dead and is not in a cutscene, move. If the game is not paused, allow Tux to shoot fire. 
	# Also Tux is allowed to do animate function if not dead.
	if not dead:
		if not in_cutscene:
			move() # Has a return just in case Global.paused is true, that's why there's no "if not Global.paused"
			if not Global.paused:
				shoot_fire()
		animate()
	
	# Small check to make sure the correct star particles are emitting when Tux is damaged / grows while he
	# has the star power-up.
	if Global.tux_star_invincible:
		if TuxManager.current_state == TuxManager.TuxStates.SMALL:
			if $LargeStars.emitting:
				$LargeStars.emitting = false
				$SmallStars.emitting = true
		else:
			if $SmallStars.emitting:
				$SmallStars.emitting = false
				$LargeStars.emitting = true
	
	# If the game is not paused, allow Tux to throw the object he's holding.
	if not Global.paused:
		if Input.is_action_just_released("player_action") and not held_object == null and not held_object.held_by == null:
			throw_object()
	
	# If Tux is in a cutscene, force Tux to throw the object he's holding.
	if in_cutscene and not held_object == null and not held_object.held_by == null:
		throw_object()
	
	# Cancels the death transition thing.
	if dead and Input.is_action_just_pressed("menu_exit"):
		get_tree().call_deferred("reload_current_scene")
		Fade.turn_invisible()
	
	# Never understood why Godot forces this function to be called to make the player move...
	move_and_slide()
	
	# If was on floor, but not on floor now and Tux hasn't jumped, start Coyote Timer and Tile Timer.
	if was_on_floor and not is_on_floor() and not Input.is_action_just_pressed("player_jump"):
		$CoyoteTimer.start()
		$TileTimer.start()

# He's dead.
func die():
	# If Tux is already, dead, return!
	if dead:
		return
	
	# Set dead to true.
	dead = true
	
	# This is for later!
	TuxManager.current_state = TuxManager.TuxStates.SMALL
	
	# If Tux is invincible through the power of the stars, remove that invincibility.
	if Global.tux_star_invincible:
		remove_star()
	
	# Stop Tux's velocity.x and make him do the dead jump.
	velocity.x = 0
	velocity.y = -dead_jump
	
	# Play hurt sound.
	$Hurt.play()
	
	# Set Small Tux image to visible, everything else can be invisible.
	$SmallImage.visible = true
	$BigImage.visible = false
	$FireImage.visible = false
	
	# Play the dead animation.
	# Reason why it's not play_animation() or whatever I called it: This only sets Small Tux's animation,
	# which makes it not need that function.
	$SmallImage.play("dead")
	
	# Stop Tux from colliding which basically any solid object, including enemies.
	set_collision_mask_value(1, false)
	set_collision_mask_value(9, false)
	set_collision_mask_value(2, false)
	set_collision_mask_value(4, false)
	
	# Stop Tux from stomping enemies.
	$Stomp.set_deferred("monitorable", false)
	$Stomp.set_deferred("monitoring", false)
	
	# Goodbye coins!
	if Global.coins >= 25:
		Global.coins -= 25
		Signals.coin_collected.emit() # not exactly collected, but...
	
	# do the funny little fade
	Fade.fade_in(0.33)
	# Await restart_scene_timer before reloading scene.
	await get_tree().create_timer(restart_scene_timer).timeout
	get_tree().call_deferred("reload_current_scene")
	Fade.turn_invisible()

# Very fun!
func move():
	# If game is paused, velocity.x should be 0 and Tux shouldn't be able to move!
	if Global.paused:
		velocity.x = 0 # velocity.y is handled in physics process!
		return
	
	# Set was_on_floor.
	was_on_floor = is_on_floor()
	
	# If player is pressing the "action" action, give Tux the ability to run. If player isn't doing that, stop Tux from being able to run.
	#if Input.is_action_pressed("player_action"):
		#speed = run_speed
		#instant_speed = instant_run_speed
		#current_acceleration = run_acceleration
	#else:
		#speed = walk_speed
		#instant_speed = instant_walk_speed
		#current_acceleration = walk_acceleration
	
	# Nevermind
	speed = run_speed
	instant_speed = instant_run_speed
	current_acceleration = run_acceleration
	
	# Duck On Floor variable! Used later.
	var duck_on_floor = duck and is_on_floor()
	
	# Later = Right now
	if not duck_on_floor:
		var move_direction = 0
		
		# Player moving left / right stuff! How fun.
		if Input.is_action_pressed("player_left") and not Input.is_action_pressed("player_right"):
			move_direction = -1
			TuxManager.direction = -1
			change_image_direction(-1) # Just so there isn't 3 "flip_h" functions here. Should this be in animate()?
		elif Input.is_action_pressed("player_right") and not Input.is_action_pressed("player_left"):
			move_direction = 1
			TuxManager.direction = 1
			change_image_direction(1) # Also just so there isn't 3 "flip_h" functions here. Should this be in animate()?
		
		# If the move direction is not 0, do actual move stuff.
		if not move_direction == 0:
			# If velocity.x is below instant_speed, apply instant_speed!
			if abs(velocity.x) < instant_speed:
				velocity.x = move_direction * instant_speed
			
			# Acceleration. Because this is code ported from the old HaxeFlixel version of this game,
			# it needs an acceleration variable thing.
			var acceleration = (current_acceleration * get_physics_process_delta_time())
			
			# Actually set the speed
			velocity.x += move_direction * acceleration
			
			# Skidding stuff
			if (velocity.x < 0 and move_direction > 0) or (velocity.x > 0 and move_direction < 0):
				if is_on_floor():
					if abs(velocity.x) > skid_speed:
						velocity.x += move_direction * acceleration / 2.5
						skid = true
				else:
					velocity.x += move_direction * acceleration / 2
					skid = false
			else:
				skid = false
		else: # I'm tired boss
			if velocity.x > 0:
				velocity.x -= current_acceleration * friction * get_physics_process_delta_time()
			elif velocity.x < 0:
				velocity.x += current_acceleration * friction * get_physics_process_delta_time()
			
			# Stop Tux if velocity is below 5
			if abs(velocity.x) < 5:
				velocity.x = 0
				skid = false
		
		# Stop velocity from going above speed
		velocity.x = clamp(velocity.x, -speed, speed)
	else:
		skid = false
		
		# Duplicated code :(
		if velocity.x > 0:
			velocity.x -= current_acceleration * friction * get_physics_process_delta_time()
		elif velocity.x < 0:
			velocity.x += current_acceleration * friction * get_physics_process_delta_time()
		
		# Duplicated code :(
		if abs(velocity.x) < 5:
			velocity.x = 0
	
	# There's a lot of colors here which has my brain confused. Sorry. This has something to do with ducking.
	if not TuxManager.current_state == TuxManager.TuxStates.SMALL:
		if not duck and is_on_floor() and Input.is_action_pressed("player_down"):
			duck = true
			
			var old_height = $Collision.shape.size.y
			change_collision_shape(false)
			position.y += (old_height - $Collision.shape.size.y) / 2
		elif duck and is_on_floor() and not Input.is_action_pressed("player_down"):
			if not $CeilingDetector.has_overlapping_bodies():
				duck = false
				change_collision_shape(true)
	else: # Thank god I don't have to see all that stuff above. Anyways, duck = false. Obviously.
		duck = false
	
	# Used very soon
	var on_floor_or_coyote = is_on_floor() or not $CoyoteTimer.is_stopped()
	
	# Jumping!
	if Input.is_action_just_pressed("player_jump") and on_floor_or_coyote:
		# SuperTux (at least the versions I've checked) don't actually
		# use Tux's max jump height and minimum jump height for this.
		if abs(velocity.x) > walk_speed:
			velocity.y = -max_jump_height
		else:
			velocity.y = -min_jump_height
		
		# What sound should I play...
		if TuxManager.current_state == TuxManager.TuxStates.SMALL:
			$SmallJump.play()
		else:
			$BigJump.play()
	
	# Variable jump height.
	if velocity.y < 0 and Input.is_action_just_released("player_jump"):
		velocity.y = 0

# Animating!
func animate():
	if Global.paused: # TODO: Remove later.
		return
	
	# If not ducking and not skidding, do stand / walk / jump animation stuff.
	if not duck and not skid:
		if (velocity.x == 0 or is_on_wall()) and is_on_floor():
			play_animation("stand")
		if (not velocity.x == 0 and not is_on_wall()) and is_on_floor():
			play_animation("walk")
		if not is_on_floor():
			play_animation("jump")
	elif duck and not skid: # This isn't play_animation("duck") because Small Tux cannot duck.
		$BigImage.play("duck")
		$FireImage.play("duck")
	elif skid and not duck: # If skidding but not ducking, play skid animation. Why is the sound thing here? Because I don't care anymore, that's why!
		if not $BigImage.animation == "skid":
			play_animation("skid")
			$Skid.play()

# Badguys use this for Tux stomping on them.
func stomp_bounce():
	if Input.is_action_pressed("player_jump"):
		velocity.y = -min_jump_height
	else:
		velocity.y = -min_jump_height / 2

func damage():
	# Two if statements for returning as I don't want to make the if statements too long, otherwise, it'd be weird. I guess.
	if in_cutscene or Global.paused:
		return
	
	# The second one
	if Global.tux_star_invincible or not can_take_damage:
		return

	can_take_damage = false
	if TuxManager.current_state == TuxManager.TuxStates.FIRE:
		TuxManager.current_state = TuxManager.TuxStates.BIG
		$Hurt.play()
		$Animation.play("flicker")
	elif TuxManager.current_state == TuxManager.TuxStates.BIG:
		TuxManager.current_state = TuxManager.TuxStates.SMALL
		$Hurt.play()
		$Animation.play("flicker")
	elif TuxManager.current_state == TuxManager.TuxStates.SMALL:
		die() # Don't play hurt sound, since die() does that. Don't play flicker either. Also, Tux dies :(
	reload_player()
	await get_tree().create_timer(inv_frames).timeout # TODO: rename inv_frames to inv_seconds
	# And finally, Tux can take damage again!
	$Animation.play("RESET")
	can_take_damage = true

func hold_object(object):
	# Don't hold object if the held object isn't null, or if Tux is in a cutscene or if the game is paused.
	if not held_object == null or in_cutscene or Global.paused:
		return
	
	held_object = object
	holding_enemy = true
	object.pick_up(self)

func throw_object():
	if held_object == null or Global.paused: # Even though this should never happen if Global.paused, it's best to be safe.
		return
	
	held_object.throw()
	holding_enemy = false
	held_object = null

# Just to be safe...
func stop_holding():
	holding_enemy = false
	held_object = null

func grow(powerup:String):
	if Global.paused: # Shouldn't happen if paused, but it's best to be safe!
		return
	
	if powerup == "egg":
		TuxManager.current_state = TuxManager.TuxStates.BIG
		$Excellent.play()
		reload_player()
	elif powerup == "fire_flower":
		TuxManager.current_state = TuxManager.TuxStates.FIRE
		$FireFlower.play()
		reload_player()
	else:
		print(powerup + " is not a valid powerup.")

# This function is actually a copy of a function in the book "Discover HaxeFlixel"!
func reload_player():
	if TuxManager.current_state == TuxManager.TuxStates.FIRE: # FIRE TUX
		Global.tux_state = TuxManager.current_state
		$SmallImage.visible = false
		$BigImage.visible = false
		$FireImage.visible = true
		if not duck:
			change_collision_shape(true)
		else:
			print("Tux is ducking! Collision shape should not be changed :(")
	elif TuxManager.current_state == TuxManager.TuxStates.BIG: # Big Tux
		Global.tux_state = TuxManager.current_state
		$SmallImage.visible = false
		$BigImage.visible = true
		$FireImage.visible = false
		if not duck:
			change_collision_shape(true)
		else:
			print("Tux is ducking! Collision shape should not be changed :(")
	elif TuxManager.current_state == TuxManager.TuxStates.SMALL: # small tux
		Global.tux_state = TuxManager.current_state
		$SmallImage.visible = true
		$BigImage.visible = false
		$FireImage.visible = false
		change_collision_shape(false)

func get_star():
	if Global.paused or Global.tux_reached_end:
		return
	
	Global.tux_star_invincible = true
	if TuxManager.current_state == TuxManager.TuxStates.SMALL:
		$SmallStars.emitting = true
	else:
		$LargeStars.emitting = true
	$Star.play()
	Music.stream = load(invincible_music)
	Music.play()
	$StarTimer.start()

# Used by the goal.
func get_star_lite():
	Global.tux_star_invincible = true
	if TuxManager.current_state == TuxManager.TuxStates.SMALL:
		$SmallStars.emitting = true
	else:
		$LargeStars.emitting = true

# Stops star music, used by the goal.
func stop_star_music():
	Music.stream = load(Global.level_song)
	Music.play()

func remove_star():
	if Global.paused or Global.tux_reached_end:
		return
	
	Global.tux_star_invincible = false
	$LargeStars.emitting = false
	$SmallStars.emitting = false
	Music.stream = load(Global.level_song)
	Music.play()

func shoot_fire():
	if TuxManager.current_state == TuxManager.TuxStates.FIRE and Input.is_action_just_pressed("player_action") and not Global.paused: # Too tired to make this be a "return" if statement instead...
		if get_tree().get_nodes_in_group("Firebullet").size() < max_fireballs_allowed:
			var fire_bullet = fire_bullet_scene.instantiate()
			get_tree().current_scene.call_deferred("add_child", fire_bullet)
			$Bullet.play()
			if TuxManager.direction == 1:
				fire_bullet.global_position.x = global_position.x - ($Collision.shape.size.x / 2)
			else:
				fire_bullet.global_position.x = global_position.x - ($Collision.shape.size.x / 2)
			fire_bullet.global_position.y = global_position.y
			fire_bullet.set_direction_speed(self)

func _on_star_timer_timeout():
	remove_star() # Could move the remove_star function stuff here... hmmm...

# Just so I don't write 1000000 lines of code.
func change_collision_shape(big:bool):
	if big:
		$Collision.shape.size.y = big_collision_size_y
		$Collision.position.y = big_collision_position_y
		$CeilingDetector/CollisionShape2D.position.y = -15.5
	else:
		$Collision.shape.size.y = small_collsion_size_y
		$Collision.position.y = small_collision_position_y
		$CeilingDetector/CollisionShape2D.position.y = 9.5

# Just so I don't write 1000000 lines of code.
func change_image_direction(direction:int):
	if direction == -1:
		$SmallImage.flip_h = true
		$BigImage.flip_h = true
		$FireImage.flip_h = true
	else:
		$SmallImage.flip_h = false
		$BigImage.flip_h = false
		$FireImage.flip_h = false

# Just so I don't write 1000000 lines of code.
func play_animation(animation:String):
	$SmallImage.play(animation)
	$BigImage.play(animation)
	$FireImage.play(animation)

# Unused, but I might use it in the future. Hopefully it's correct now.
func get_collision_bottom():
	return global_position.y + $Collision.position.y + ($Collision.shape.size.y / 2)
