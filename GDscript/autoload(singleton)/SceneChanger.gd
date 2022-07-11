#Author Tiny Legions: youtube link https://www.youtube.com/watch?v=TJaeGJ9DADI
#Modifed by ChromiumOS-Guy
#Github https://github.com/ChromiumOS-Guy


extends Node
export var max_load_time = 10000
var thread = Thread.new() # makes new thread 

func start_load(path,doloadingbar = true): # example use: SceneChanger.start_load("res://levels/level1.tscn",self)
	if Globals.can_async:
		thread.start(self,"goto_scene",[ResourceLoader.load_interactive(path), doloadingbar, path],thread.PRIORITY_HIGH) # starts new thread with HIGH Priority
	else:
		print("Error your platform does not support multi threading falling back to main thread")
		get_tree().change_scene(path) # complete fall back 
	

func goto_scene(data): # handels polling and scene switching
	var loader = data[0]
	var doloadingbar = data[1]
	var path = data[2]
	if Globals.can_async: # double check if platform supports aysnc (no fallback if it failes)
		
		if loader == null: # complains about invalid paths
			print("Resource loader unable to load the resource at path")
			return
		
		var loading_bar = Globals.loading_bar.instance() if doloadingbar else null# put your own loading screen here 
		
		if doloadingbar:
			get_tree().get_root().call_deferred('add_child',loading_bar) # adding loading bar as child
		
		var t = OS.get_ticks_msec()
		
		while OS.get_ticks_msec() - t < max_load_time: # polling / loading selected scene and updating progress for loading bar
			var err = loader.poll()
			if err == ERR_FILE_EOF:
				#Loading Complete
				var resource = loader.get_resource()
				for child in get_tree().get_root().get_children(): # gets children of root and queue_free() them if they are not a singleton
					if !Globals.autoload_names.has(child.get_name()): # checks if the childs name is valid for exclusion from queue_free() by looking up its name and seeing if it exist in Globals.autoload_names
						child.queue_free()
				get_tree().get_root().call_deferred('add_child',resource.instance())
				if !doloadingbar:
					print(path.get_file()," is complete!")
				thread.wait_to_finish()
				break
			elif err == OK:
				#Still loading
				var progress = float(loader.get_stage())/loader.get_stage_count()
				if doloadingbar:
					loading_bar.loading.value = progress * 100 # change loading_bar.progress to loading_bar.(the % update function you have)
				else:
					print(path.get_file()," is at %",progress * 100," completion!")
			else:
				print("Error while loading file") # if err isn't ERR_FILE_EOF(completed) or OK(still loading) the something Is preventing the file from loading
				break
			yield(get_tree(),"idle_frame") # makes it possible to see end result
