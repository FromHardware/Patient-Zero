extends Area2D

func _ready():
	# Connect the body_entered signal if not done in the editor
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	# Check if the colliding body is the player
	if body.name == "player":   # or "Player" if your node is capitalized
		# Reload the current scene => "instantly die"
		get_tree().reload_current_scene()
