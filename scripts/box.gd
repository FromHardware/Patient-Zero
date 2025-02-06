extends StaticBody2D

var hp = 2
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func break_box():
	hp -= 1
	if hp == 1:
		sprite.frame = 1  # half box
	elif hp <= 0:
		queue_free()      # remove the box
