extends CharacterBody2D

# This variable will hold a reference to your AnimatedSprite2D node
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@onready var coyote_timer: Timer = $CoyoteTimer
@onready var wall_jump_timer: Timer = $WallJumpTimer
@onready var wall_coyote_timer: Timer = $WallCoyoteTimer
@onready var muzzle = $Muzzle

@export var bullet_scene: PackedScene

const SPEED = 300.0
const JUMP_VELOCITY = -850.0
const WALL_JUMP_VELOCITY = 400.0
const MAX_WALL_SLIDE_VELOCITY = 50.0
const JUMP_DAMPEN_FACTOR = 0.4
const MAX_JUMPS_ALLOWED = 2
const COYOTE_TIMER_WAIT_SECONDS = 0.15
const WALL_COYOTE_TIMER_WAIT_SECONDS = 0.15
const WALL_JUMP_TIMER_WAIT_SECONDS = 0.05
const FIRE_FRAME_OF_SHOOT_ANIM = 1
const SHOOT_COOLDOWN = 0.05
const MAX_BULLETS_ON_SCREEN = 3


var alive = true
var shoot_cooldown_remaining = 0.0
var active_bullets = []
var can_move = true
var number_of_jumps_used = 0
var was_on_floor = false
var is_wall_sliding = false
var last_wall_normal = 0.0
var wants_to_fire = false


func _physics_process(delta: float) -> void:
	if !alive:
		return

	if can_move:

		# Get the input direction
		var direction := Input.get_axis("left", "right")

		_update_wall_state(direction)
		_apply_gravity(delta)
		_handle_jump()
		_handle_movement(direction)
		_handle_combat(delta)
		move_and_slide()
		_handle_air_transitions()
		_update_animations()


func _update_wall_state(direction) -> void:
	if is_on_wall_only():
		last_wall_normal = get_wall_normal()
		var is_pushing_into_wall = (direction != 0 and sign(direction) != sign(last_wall_normal.x))
		is_wall_sliding = is_on_wall_only() and is_pushing_into_wall

		if is_wall_sliding:
			number_of_jumps_used = 0
			wall_coyote_timer.start(WALL_COYOTE_TIMER_WAIT_SECONDS)
	else:
		is_wall_sliding = false

	if not is_on_floor() and not is_wall_sliding: 
		if wall_coyote_timer.is_stopped() and coyote_timer.is_stopped():
			if number_of_jumps_used == 0:
				number_of_jumps_used = 1


func _apply_gravity(delta) -> void:
	if is_on_floor():
		number_of_jumps_used = 0
		coyote_timer.stop()
	else:
		# Add the gravity.
		velocity += get_gravity() * delta
		
		if is_wall_sliding:
			if velocity.y > 0:
				velocity.y = min(velocity.y, MAX_WALL_SLIDE_VELOCITY)


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		if not wall_coyote_timer.is_stopped():
			velocity.x = last_wall_normal.x * WALL_JUMP_VELOCITY
			velocity.y = JUMP_VELOCITY
			number_of_jumps_used += 1
			wall_jump_timer.start(WALL_JUMP_TIMER_WAIT_SECONDS)
			wall_coyote_timer.stop()
		elif is_on_floor() or not coyote_timer.is_stopped() or number_of_jumps_used < MAX_JUMPS_ALLOWED:
			velocity.y = JUMP_VELOCITY
			SoundManager.play_sound("player-jump", global_position)
			number_of_jumps_used += 1
			coyote_timer.stop()


	# Appropriate Height logic for jump
	if Input.is_action_just_released("jump") and velocity.y < 0:
		# Multiply by dampening factor to 'dampen' the jump mid-air
		velocity.y *= JUMP_DAMPEN_FACTOR


func _handle_movement(direction) -> void:
	# If the timer is effectively over, perform regular movement/deceleration.
	if wall_jump_timer.is_stopped():
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		# Dampen the effect of the force from the wall jump.
		# While the wall jump timer is running, we allow the player to steer.
		# If they hold the opposite direction, they can cancel the push faster.
		if direction:
			velocity.x = move_toward(velocity.x, direction * SPEED, 20)


func _handle_combat(delta: float) -> void:
	_handle_projectiles(delta)


func _handle_projectiles(delta: float) -> void:
	# Clean up freed bullets from tracking
	for i in range(active_bullets.size() - 1, -1, -1):
		if active_bullets[i] == null:
			active_bullets.remove_at(i)

	# Decrement shoot cooldown
	if shoot_cooldown_remaining > 0:
		shoot_cooldown_remaining -= delta

	if Input.is_action_just_pressed("shoot"):
		if shoot_cooldown_remaining <= 0 and active_bullets.size() < MAX_BULLETS_ON_SCREEN:
			wants_to_fire = true
			animated_sprite_2d.play("shoot")
			animated_sprite_2d.frame = 0 # This ensures we don't skip frame 0


func _on_animated_sprite_2d_frame_changed() -> void:
	# Frame 1 is the "Fire" frame in your 0, 1, 2, 3 sequence
	if animated_sprite_2d != null and animated_sprite_2d.animation == "shoot" and animated_sprite_2d.frame == FIRE_FRAME_OF_SHOOT_ANIM:
		if wants_to_fire:
			_spawn_bullet()
			wants_to_fire = false


func _spawn_bullet() -> void:
	var bullet = bullet_scene.instantiate()

	# Set the bullet's starting position to the player's hand/muzzle
	bullet.global_position = muzzle.global_position

	# Tell the bullet which way to go based on the player's flip state
	bullet.direction = 1 if animated_sprite_2d.flip_h == false else -1
	
	# Add it to the MAIN level scene, not as a child of the player
	# (Otherwise, if the player moves, the bullets will move with them!)
	get_tree().current_scene.add_child(bullet)
	
	# Track the bullet for limiting on-screen count
	active_bullets.append(bullet)
	
	# Play the shoot sound
	SoundManager.play_sound("player-shoot", global_position, -10.0)
	
	# Set the cooldown between shots
	shoot_cooldown_remaining = SHOOT_COOLDOWN


func _handle_air_transitions() -> void:
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		coyote_timer.start(COYOTE_TIMER_WAIT_SECONDS)

	was_on_floor = is_on_floor()


func _update_animations() -> void:
	# Get the last frame index of the current animation
	var last_frame = animated_sprite_2d.sprite_frames.get_frame_count("shoot") - 1

	# Only 'return' if we are shooting AND haven't finished the animation
	if animated_sprite_2d.animation == "shoot" and animated_sprite_2d.frame < last_frame:
		return

	if is_on_floor():
		if velocity.x > 1 or velocity.x < -1:
			animated_sprite_2d.animation = "running"
		else:
			animated_sprite_2d.animation = "idle"
	else:
		if is_wall_sliding:
			if animated_sprite_2d.animation != "wall_sliding":
				animated_sprite_2d.animation = "wall_sliding"
		elif number_of_jumps_used < MAX_JUMPS_ALLOWED:
			if animated_sprite_2d.animation != "jumping":
				animated_sprite_2d.animation = "jumping"
		else:
			if animated_sprite_2d.animation != "double_jumping":
				animated_sprite_2d.animation = "double_jumping"

	if velocity.x > 0:
		animated_sprite_2d.flip_h = false
	if velocity.x < 0:
		animated_sprite_2d.flip_h = true

	var direction := Input.get_axis("left", "right")
	if direction > 0:
		muzzle.position.x = 15
	elif direction < 0:
		muzzle.position.x = -15

func die() -> void:
	SoundManager.play_sound("player-death", global_position)
	animated_sprite_2d.animation = "dying"
	alive = false


func _on_coyote_timer_timeout() -> void:
	if not is_on_floor() and not is_wall_sliding:
		if number_of_jumps_used == 0:
			number_of_jumps_used = 1
