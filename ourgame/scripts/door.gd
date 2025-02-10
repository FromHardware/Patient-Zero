extends Area2D

@export var next_scene_path: String = "res://scenes/game_2.tscn"

func _ready():
	# Connect the body_entered signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	# Check if the colliding body is the player
	if body.name == "player": 
		# Load the specified scene
		get_tree().change_scene_to_file(next_scene_path)
