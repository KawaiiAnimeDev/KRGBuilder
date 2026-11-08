class_name SceneMgr
extends Node



func _additive_load(scene_path : String) -> Node:
	
	var scene : PackedScene = load(scene_path)
	if not scene:
		print("[SceneManager]: Failed to load " + scene_path + " .")
		return null
	
	var loaded : Node = scene.instantiate()
	
	get_tree().root.add_child(loaded)
	return loaded

func _additive_load_async(scene_path : String) -> Node:
	var error = ResourceLoader.load_threaded_request(scene_path)
	if error != OK:
		print("[SceneManager]: Failed to start async load for " + scene_path)
		return null
	
	while true:
		await get_tree().process_frame
		
		var progress = []
		var status = ResourceLoader.load_threaded_get_status(scene_path, progress)
		
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				break
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				pass
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				print("[SceneManager]: Async load failed or resource is invalid for " + scene_path)
				return null

	var scene : PackedScene = ResourceLoader.load_threaded_get(scene_path)
	
	var loaded : Node = scene.instantiate()
	get_tree().root.add_child(loaded)
	
	return loaded
