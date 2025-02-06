extends CharacterBody2D

const SPEED = 600.0
const JUMP_VELOCITY = -1000.0
const GRAVITY = 2000.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

enum Form { BASIC, FIRST_TRANSFORMATION, SECOND_TRANSFORMATION }
var current_form: Form = Form.BASIC  
var is_transforming: bool = false  
var is_jumping: bool = false  
var is_attacking: bool = false

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("FirstForme") and not is_transforming and not is_attacking:
		trigger_transformation()
	
	if Input.is_action_just_pressed("attack") and not is_attacking:
		handle_attack()

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	
	if is_transforming or is_attacking:
		move_and_slide()
		return
	
	handle_movement()

func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func handle_movement():
	var direction := Input.get_axis("move left", "move right")

	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

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
			jump_anim = "second_transformation_jump"

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = true  
		animated_sprite.play(jump_anim)  
	elif is_on_floor():
		is_jumping = false  

	if not is_jumping:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play(idle_anim)
			else:
				animated_sprite.play(run_anim)

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func handle_attack():
	if current_form == Form.FIRST_TRANSFORMATION:
		is_attacking = true
		velocity.x = 0  # Stop movement while attacking
		animated_sprite.play("slash")

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
	
	match current_form:
		Form.BASIC:
			animated_sprite.play("basic_idle")
		Form.FIRST_TRANSFORMATION:
			animated_sprite.play("first_transformation_idle")
		Form.SECOND_TRANSFORMATION:
			animated_sprite.play("second_transformation_idle")
