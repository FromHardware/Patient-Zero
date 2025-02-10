extends Node

var tuto_bgm = load("res://assests/sound/tuto_bgm.mp3")
var lv1_bgm = load("res://assests/sound/lv1_bgm.mp3")

func _ready() -> void:
	pass # Replace with function body.

func play_tuto():
	$Music.stream = tuto_bgm
	$Music.play()
	
func play_lv1():
	$Music.stream = lv1_bgm
	$Music.play()
