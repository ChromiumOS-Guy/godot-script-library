thread_pool_manager.gd is an autoload remember to set it as such

load_scene_with_interactive() is by desgin ment to run once per time don't use in parallel if you do, expext unexpected behavor and crashes

ThreadPool Features:

task time limit

variable thread count

Futures

ThreadPoolManager.gd functions:

debugging functions:

get_task_queue_as_immutable()

get_pending_queue_as_immutable()

get_threads_as_immutable()

normal functions:
```diff
join(identifier, by: String = "task")
```
# when called will "block" thread from doing anything until a task is finished or cancelled, use example 1: join(task) , use example 2: join("the_task_tag","task_tag") # will return err when finished err == "OK" is success , err == "OK_CANCEL" is success but task that has been joind got cancelled

```diff
submit_task(instance: Object, method: String, parameter,task_tag : String ,time_limit : float = task_time_limit, priority:int = default_priority) 
```
# submit tasks like normal

submit_task_as_parameter(instance: Object, method: String, parameter,task_tag : String, time_limit : float = task_time_limit, priority:int = default_priority) # like submit_task() but gives the selected method the task as self allowing said method to change things about its task example: func said_method(userdata, task)

submit_task_unparameterized(instance: Object, method: String, task_tag : String, time_limit : float = task_time_limit, priority:int = default_priority) # like submit_task() but without any parameters

submit_task_array_parameterized(instance: Object, method: String, parameter: Array,task_tag : String, time_limit : float = task_time_limit, priority:int = default_priority) # like submit_task() but uses callv () instead of call()

submit_task_as_only_parameter(instance: Object, method: String ,task_tag : String, time_limit : float = task_time_limit, priority:int = default_priority) # like submit_task_unparameterized() but sends task as only parameter example: func said_method(task)

submit_task_unparameterized_if_no_parameter(instance: Object, method: String, task_tag : String,parameter = null, time_limit : float = task_time_limit, priority:int = default_priority) # like submit_task() but if parameter is equal to null it uses submit_task_unparameterized() instead of submit_task()

load_scene_with_interactive(path, task_tag : String, print_to_console = true ,time_limit : float = task_time_limit, priority:int = 0) # uses ResourceLoader.load_interactive() to load your scene async while also updating the task's task.progress and it returns task so you can hook it up to a loading screen , use example: load_scene_with_interactive("path_to_level.tscn","task_tag", false #optional , 10000 # optional, 51 # optional)
