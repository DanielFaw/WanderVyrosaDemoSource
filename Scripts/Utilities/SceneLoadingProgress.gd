extends Node


export var loading_progress_bar_path:NodePath
var loading_progress_bar:ProgressBar

func _ready() -> void:
	loading_progress_bar = get_node(loading_progress_bar_path)
	pass


func SetLoadProgress(progress:float = 0):
	loading_progress_bar.value = progress
	pass
