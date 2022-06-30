#Author ChromiumOS-Guy
#Github https://github.com/ChromiumOS-Guy

extends Node

signal done
var SAVE_DIR = "res://gamedata/"

# save / load functions
func save_data(data ,save_path: String,encrypted_password : String = ""):
	var do_not_encrypt
	if encrypted_password == "":
		do_not_encrypt = true
	else:
		do_not_encrypt = false
	
	if save_path.get_extension() == "":
		save_path += ".dat"
	save_logic([data ,SAVE_DIR + save_path ,encrypted_password, do_not_encrypt]) # Calls SaveData to save the file

func load_data(save_path: String,encrypted_password: String = ""):
	var no_encryption
	if encrypted_password == "":
		no_encryption = true
	else:
		no_encryption = false
	
	if save_path.get_extension() == "":
		save_path += ".dat"
	return load_logic([SAVE_DIR + save_path ,encrypted_password, no_encryption])# Calls SaveData to load the file

# logic:
func _ready(): # Uses the _ready function to check if the main directory exists if not then it creates it
	var dir = Directory.new()
	if !dir.dir_exists(Handler.SAVE_DIR):
		dir.make_dir_recursive(Handler.SAVE_DIR)

func save_logic(data_array): # Set function and parameters
	var data = data_array[0]
	var save_path = data_array[1]
	var encrypted_password = data_array[2]
	var do_not_encrypt = data_array[3]
	var dir = Directory.new() # Checks if the directory exists if not then it creates it
	if !dir.dir_exists(save_path.get_base_dir()):
		dir.make_dir_recursive(save_path.get_base_dir())
	
	var file = File.new()
	if do_not_encrypt:
		var error = file.open(save_path, File.WRITE) # Checks for error and inputs the data
		if error == OK:
				file.store_var(data) # Actually stores the data inside of a file
				file.close()
		else:
			print("Failed to Save: ",save_path ," error: ",error)
	else:
		var error = file.open_encrypted_with_pass(save_path, File.WRITE , encrypted_password) # Checks for error and inputs the data and encryption 
		if error == OK:
			file.store_var(data) # Actually stores the data inside of a file
			file.close()
		else:
			print("Failed to Save: ",save_path ," error: ",error)

func load_logic(data_array): # Set function and parameters
	var save_path = data_array[0]
	var encrypted_password = data_array[1]
	var no_encryption = data_array[2]
	var file = File.new()
	if file.file_exists(save_path):
		if no_encryption:
			var error = file.open(save_path, File.READ) # Checks for error ,outputs the data
			if error == OK:
				var savefile_name = file.get_var() # Actually loads the data inside of a file
				file.close()
				return savefile_name
			else: # Outputs an error if there is one
				print("Failed to Load: ",save_path ," error: ",error) 
		else:
			var error = file.open_encrypted_with_pass(save_path, File.READ , encrypted_password) # Checks for error ,inputs encryption password and outputs the data
			if error == OK:
				var savefile_name = file.get_var() # Actually loads the data inside of a file
				file.close()
				return savefile_name
			else: # Outputs an error if there is one
				print("Failed to Load: ",save_path ," error: ",error) 
	else: # Outputs a complaint of file does not exist
		print("File does not exist: ",save_path)

func create_dir(dir_path):
	var dir = Directory.new() # Checks if the directory exists or not
	dir_path = SAVE_DIR + dir_path
	if dir_path.get_extension() == "":
		if !dir.dir_exists(dir_path.get_base_dir()):
			dir.make_dir_recursive(dir_path)
			return true
		else:
			print("directory (",dir_path,") already exists")
	else:
		print("this function is for creating directories as such it isn't able to create files use the save_json() or save_data() functions respectively to do that")
	return false

func remove_file(save_path):
	var dir = Directory.new() # Checks if the directory exists or not
	save_path = SAVE_DIR + save_path
	if save_path.get_extension() != "":
		if dir.dir_exists(save_path.get_base_dir()):
			dir.remove(save_path)
			return true
		else:
			print("the directory does not exists or was not found: (",save_path.get_base_dir(),") cannot delete file at directory")
	else:
		print("only files can be deleted with this function safely please use the remove_dir() function if you are trying to remove a directory")
	return false
	

func remove_dir(dir_path):
	var dir = Directory.new() # Checks if the directory exists or not
	if dir_path.get_extension() == "":
		if dir_path[-1] == "/":
			dir_path = SAVE_DIR + dir_path
			if dir.dir_exists(dir_path):
				dir.remove(dir_path)
				return true
			else:
				print("the directory does not exists or was not found: (",dir_path,")")
		else:
			dir_path = SAVE_DIR + dir_path + "/"
			if dir.dir_exists(dir_path):
				dir.remove(dir_path)
				return true
			else:
				print("the directory does not exists or was not found: (",dir_path,")")
	else:
		print("only directories can be deleted with this function safely please use the remove_file() function if you are trying to remove a file")
	return false

