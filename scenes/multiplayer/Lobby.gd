extends Control

@export var ipInput: LineEdit

func _on_host_pressed():
	NetworkManager._start_server()
	get_tree().change_scene_to_file("res://scenes/maps/Arena01.tscn")

func _on_join_pressed():
	NetworkManager._start_client(ipInput.text)
	get_tree().change_scene_to_file("res://scenes/maps/Arena01.tscn")
