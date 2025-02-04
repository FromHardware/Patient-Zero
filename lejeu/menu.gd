extends Control

func _on_play_pressed() -> void:
	# get_tree().change_scene_to_file("res://game.tscn")
	pass

func _on_option_pressed() -> void:
	get_tree().change_scene_to_file("res://option.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
