extends CharacterBody2D

# -- Constants
const BASE_SPEED = 600.0
const JUMP_VELOCITY = -1000.0
const GRAVITY = 2000.0
@export var player_knockback_strength = 400.0  # Adjust for your desired push
@export var knockback_duration = 0.2           # Seconds of knockback effect

# Child node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var slash_area: Area2D = $SlashArea2D
@onready var slash_collision: CollisionShape2D = $SlashArea2D/CollisionShape2D

# Forms
enum Form { BASIC, FIRST_TRANSFORMATION, SECOND_TRANSFORMATION }
var current_form: Form = Form.BASIC

# State
var is_transforming: bool = false
var is_jumping: bool = false
var is_attacking: bool = false

# HP
var hp = 3

# -- Knockback timer
var knockback_time = 0.0

func _ready():
	print("Player ready. Node name:", name)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	slash_area.body_entered.connect(_on_slash_body_entered)
	slash_collision.disabled = true

func _process(delta: float) -> void:
	# Transformation
	if Input.is_action_just_pressed("FirstForme") and not is_transforming and not is_attacking:
		trigger_transformation()

	# Attack
	if Input.is_action_just_pressed("attack") and not is_attacking:
		handle_attack()

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	# Flip the slash area
	if animated_sprite.flip_h:
		slash_area.scale.x = -1
	else:
		slash_area.scale.x = 1

	# If we have knockback time remaining, skip normal movement
	if knockback_time > 0:
		knockback_time -= delta
		move_and_slide()
		return

	# If transforming or attacking, skip normal movement
	if is_transforming or is_attacking:
		move_and_slide()
		return

	# Normal movement
	handle_movement()
	move_and_slide()

func handle_movement():
	var direction = Input.get_axis("move left", "move right")

	# Flip sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# Anim selection
	var idle_anim = ""
	var run_anim = ""
	var jump_anim = ""

	match current_form:
		Form.BASIC:
			idle_anim = "basic_idle"
			run_anim = "basic_run"
			jump_anim = "basic_jump"
		Form.FIRST_TRANSFORMATION:
			idle_anim = "first_transformation_idle"
			run_anim = "first_transformation_run"
			jump_anim = "first_transformation_jump"
		Form.SECOND_TRANSFORMATION:
			idle_anim = "second_transformation_idle"
			run_anim = "second_transformation_run"
			jump_anim = ""

	# Jump if not second form
	if current_form != Form.SECOND_TRANSFORMATION:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			is_jumping = true
			if jump_anim != "":
				animated_sprite.play(jump_anim)
		elif is_on_floor():
			is_jumping = false
	else:
		if is_on_floor():
			is_jumping = false

	# Idle/run anim
	if not is_jumping:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play(idle_anim)
			else:
				animated_sprite.play(run_anim)

	# Horizontal speed
	var speed = BASE_SPEED
	if current_form == Form.SECOND_TRANSFORMATION:
		speed *= 0.6

	if direction != 0:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

func handle_attack():
	if is_attacking:
		return

	match current_form:
		Form.FIRST_TRANSFORMATION:
			is_attacking = true
			velocity.x = 0
			slash_collision.disabled = false
			animated_sprite.play("slash")

		Form.SECOND_TRANSFORMATION:
			is_attacking = true
			velocity.x = 0
			slash_collision.disabled = false
			animated_sprite.play("bonk")

func trigger_transformation():
	if is_transforming:
		return
	is_transforming = true
	velocity.x = 0
	match current_form:
		Form.BASIC:
			animated_sprite.play("transformation_to_first")
			current_form = Form.FIRST_TRANSFORMATION
		Form.FIRST_TRANSFORMATION:
			animated_sprite.play("transformation_to_second")
			current_form = Form.SECOND_TRANSFORMATION
		Form.SECOND_TRANSFORMATION:
			animated_sprite.play("transformation_to_basic")
			current_form = Form.BASIC

func _on_animation_finished():
	if is_transforming:
		is_transforming = false
	if is_attacking:
		is_attacking = false
		slash_collision.disabled = true
	if animated_sprite.animation in ["basic_jump", "first_transformation_jump"]:
		if not is_on_floor():
			return
	match current_form:
		Form.BASIC:
			animated_sprite.play("basic_idle")
		Form.FIRST_TRANSFORMATION:
			animated_sprite.play("first_transformation_idle")
		Form.SECOND_TRANSFORMATION:
			animated_sprite.play("second_transformation_idle")

func _on_slash_body_entered(body: Node) -> void:
	if not is_attacking:
		return
	# If second form, can break boxes
	if current_form == Form.SECOND_TRANSFORMATION and body.has_method("break_box"):
		body.break_box()
		return
	# Else if it has die(), do enemy logic
	if body.has_method("die"):
		body.die()

func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	print("player took damage! HP:", hp)

	if attacker_pos != Vector2.ZERO:
		apply_knockback(attacker_pos)

	if hp <= 0:
		print("player HP <= 0, reloading scene.")
		get_tree().reload_current_scene()

func apply_knockback(attacker_pos: Vector2) -> void:
	# Calculate direction away from attacker
	var dir = (global_position - attacker_pos).normalized()
	velocity = dir * player_knockback_strength

	# Set knockback_time so we skip normal movement
	knockback_time = knockback_duration
