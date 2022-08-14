#Author Tiny Legions: youtube link https://www.youtube.com/watch?v=TJaeGJ9DADI
#Modifed by ChromiumOS-Guy
#Github https://github.com/ChromiumOS-Guy


extends Node
export var max_load_time = 10000
var thread = Thread.new() # makes new thread
var can_async:bool = ["Windows", "OSX", "UWP", "X11"].has(OS.get_name())

func start_load(path): # example use: SceneChanger.start_load("res://levels/level1.tscn",self)
	if can_async:
		thread.start(self,"goto_scene",[ResourceLoader.load_interactive(path),path],thread.PRIORITY_HIGH) # starts new thread with HIGH Priority
	else:
		print("Error your platform does not support multi threading falling back to main thread")
		get_tree().change_scene(path) # complete fall back 
	

func goto_scene(data): # handels polling and scene switching
	var loader = data[0]
	var path = data[1]
	if can_async: # double check if platform supports aysnc (no fallback if it failes)
		
		if loader == null: # complains about invalid paths
			print("Resource loader unable to load the resource at path")
			return
		
		var t = OS.get_ticks_msec()
		
		while OS.get_ticks_msec() - t < max_load_time: # polling / loading selected scene and updating progress for loading bar
			var err = loader.poll()
			if err == ERR_FILE_EOF:
				#Loading Complete
				var autoload_prop_start = "autoload/"
				var singletons: = []
				for i in ProjectSettings.get_property_list(): # magic i copy pasted this from here https://github.com/godotengine/godot-proposals/issues/3705
					if i.name.begins_with(autoload_prop_start):
						singletons.push_back(i.name.trim_prefix(autoload_prop_start))
				var resource = loader.get_resource().instance()
				task.progress = 100
				get_tree().get_root().add_child_below_node(get_tree().get_root(),resource)
				for child in get_tree().get_root().get_children(): # gets children of root and queue_free() them if they are not a singleton
					if singletons.has(child.get_name()): # checks if the childs name is valid for exclusion from queue_free() by looking up its name and seeing if it exist in Globals.autoload_names
						pass
					elif child == resource:
						pass
					else:
						child.queue_free()
				print(path.get_file()," is complete!")
				thread.wait_to_finish()
				break
			elif err == OK:
				#Still loading
				var progress = float(loader.get_stage())/loader.get_stage_count()
				print(path.get_file()," is at %",progress * 100," completion!")
			else:
				print("Error while loading file") # if err isn't ERR_FILE_EOF(completed) or OK(still loading) the something Is preventing the file from loading
				break
		yield(get_tree(),"idle_frame") # makes it possible to see end result
