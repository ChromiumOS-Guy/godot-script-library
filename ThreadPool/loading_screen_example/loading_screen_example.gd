extends ProgressBar
export(String, FILE, "*.tscn") var scene_file_path
var loading_scene = null

onready var tween : Tween = $Tween

func Load(): # trigger this from somewhere
	loading_scene = ThreadPoolManager.load_scene_with_interactive(scene_file_path)

func _process(delta):
	if loading_scene != null:
		if loading_scene.progress != null:
			tween.interpolate_property(self , "value",  self.value , loading_scene.progress * 10, 0.1 ,Tween.TRANS_SINE , Tween.EASE_IN)
			tween.start()
