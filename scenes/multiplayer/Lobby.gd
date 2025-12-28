extends Control

@export var ip_input: LineEdit

func _on_host_pressed():
	HighLevelNetworkHandler.start_server()
	get_tree().change_scene_to_file("res://scenes/maps/Arena01.tscn")

func _on_join_pressed():
	HighLevelNetworkHandler.start_client(ip_input.text)
	get_tree().change_scene_to_file("res://scenes/maps/Arena01.tscn")
