extends CanvasLayer

@onready var health_bar: AnimatedSprite2D = $HealthBar

func update_health_bar(new_hp: int):
	# If you have 3 HP max, frames might be 0..3. 
	# If new_hp is 3 => show frame 3, if HP is 2 => show frame 2, etc.
	health_bar.frame = clamp(new_hp, 0, 3)
