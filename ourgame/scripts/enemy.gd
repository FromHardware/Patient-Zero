extends CharacterBody2D

@export var gravity = 2000.0
@export var move_speed = 200.0
@export var knockback_strength = 300.0
@export var hp = 3
@export var chase_range = 600.0  # how close player must be to chase
@export var knockback_duration = 0.2
@onready var sfx_slashing: AudioStreamPlayer2D = $sfx_slashing

var player: Node2D
var knockback_time = 0.0
var is_attacking = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	print("Enemy script ready. Node name:", name)
	# Connect the HitboxArea body_entered signal
	$HitboxArea.body_entered.connect(_on_HitboxArea_body_entered)

	# Connect animation_finished signal so we know when "attack" ends
	animated_sprite.animation_finished.connect(_on_animation_finished)

	# Attempt to find the player in "PlayerGroup"
	var players = get_tree().get_nodes_in_group("PlayerGroup")
	if players.size() > 0:
		player = players[0] as Node2D
		print("Enemy found a player:", player.name)
	else:
		print("No player found in group 'PlayerGroup'")

func _physics_process(delta: float) -> void:
	apply_gravity(delta)

	# 1) If knockback_time > 0, we're "stunned" and skip chase
	if knockback_time > 0:
		knockback_time -= delta
		move_and_slide()
		return

	# 2) If currently attacking, skip chase logic
	if is_attacking:
		move_and_slide()
		return

	# 3) Otherwise, chase the player
	if player and is_instance_valid(player):
		chase_player(delta)
	else:
		velocity.x = 0

	# 4) Decide animations: if moving horizontally, play "run", else "idle"
	if velocity.x != 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")

	move_and_slide()

func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

func chase_player(delta: float):
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= chase_range:
		var direction = sign(player.global_position.x - global_position.x)
		velocity.x = direction * move_speed
	else:
		velocity.x = 0

func _on_HitboxArea_body_entered(body: Node):
	print("HitboxArea triggered by:", body, ", name:", body.name)
	# If 'body' is our player, do damage
	if body.name == "player" and body.has_method("take_damage"):
		print("Enemy collided with player's body => damage!")
		
		# Only do the attack animation if not already attacking
		if not is_attacking:
			is_attacking = true
			animated_sprite.play("attack")
		
		# Deal damage to the player immediately
		body.take_damage(1, global_position)
		
		

func die():
	hp -= 1
	sfx_slashing.play()
	print("Enemy took a slash! HP:", hp)
	if hp <= 0:
		print("Enemy HP=0 => queue_free()")
		queue_free()
	else:
		apply_knockback()

func apply_knockback():
	if not player or not is_instance_valid(player):
		return
	var dir = (global_position - player.global_position).normalized()
	velocity = dir * knockback_strength
	knockback_time = knockback_duration

func _on_animation_finished():
	# If we just finished the "attack" animation and we're attacking, reset state
	if animated_sprite.animation == "attack" and is_attacking:
		is_attacking = false
