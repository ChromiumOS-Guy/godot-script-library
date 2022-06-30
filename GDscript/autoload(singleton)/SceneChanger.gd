#Author Tiny Legions: youtube link https://www.youtube.com/watch?v=TJaeGJ9DADI
#Modifed by ChromiumOS-Guy
#Github https://github.com/ChromiumOS-Guy


extends Node
export var max_load_time = 10000
var thread = Thread.new() # makes new thread 
var current_scene

func start_load(path,scene): # example use: SceneChanger.start_load("res://levels/level1.tscn",self)
	if Handler.can_async:
		current_scene = scene
		thread.start(self,"goto_scene",ResourceLoader.load_interactive(path),thread.PRIORITY_HIGH) # starts new thread with HIGH Priority
	else:
		print("Error your platform does not support multi threading falling back to main thread")
		get_tree().change_scene(path) # complete fall back 
	

func goto_scene(loader): # handels polling and scene switching
	if Handler.can_async: # double check if platform supports aysnc (no fallback if it failes)
		
		if loader == null: # complains about invalid paths
			print("Resource loader unable to load the resource at path")
			return
		
		var loading_bar = load("res://Loading screen.tscn").instance() # put your own loading screen here 
		
		get_tree().get_root().call_deferred('add_child',loading_bar) # adding loading bar as child
		
		var t = OS.get_ticks_msec()
		
		while OS.get_ticks_msec() - t < max_load_time: # polling / loading selected scene and updating progress for loading bar
			var err = loader.poll()
			if err == ERR_FILE_EOF:
				#Loading Complete
				var resource = loader.get_resource()
				get_tree().get_root().call_deferred('add_child',resource.instance())
				current_scene.queue_free()
				loading_bar.queue_free()
				thread.wait_to_finish()
				break
			elif err == OK:
				#Still loading
				var progress = float(loader.get_stage())/loader.get_stage_count()
				loading_bar.progress = progress * 100 # change loading_bar.progress to loading_bar.(the % update function you have)
				print(progress * 100)
			else:
				print("Error while loading file") # if err isn't ERR_FILE_EOF(completed) or OK(still loading) the something Is preventing the file from loading
				break
			yield(get_tree(),"idle_frame") # makes it possible to see end result
	

