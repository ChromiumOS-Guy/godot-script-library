thread_pool_manager.gd is an autoload remember to set it as such

load_scene_with_interactive() is by desgin ment to run once per time don't use in parallel if you do, expext unexpected behavor and crashes

ThreadPool Features:

task time limit

variable thread count

Futures

ThreadPoolManager.gd functions:

debugging functions:

get_task_queue() # gives you access to the task queue in immutable form

get_pending_queue() # gives you access to the pending tasks in immutable form

get_threads() # gives you access to the ThreadPool's Threads in immutable form

normal functions:

submit_task(instance: Object, method: String, parameter,task_tag = null ,time_limit : float = task_time_limit) # submit tasks like normal

submit_task_as_parameter(instance: Object, method: String, parameter, task_tag = null, time_limit : float = task_time_limit) # like submit_task() but gives the selected method the task as self allowing said method to change things about its task

submit_task_unparameterized(instance: Object, method: String, task_tag = null, time_limit : float = task_time_limit) # like submit_task() but without any parameters

submit_task_array_parameterized(instance: Object, method: String, parameter: Array,task_tag = null, time_limit : float = task_time_limit) # like submit_task() but uses callv () instead of call()

submit_task_as_only_parameter(instance: Object, method: String ,task_tag = null, time_limit : float = task_time_limit) # like submit_task_unparameterized() but sends task as only parameter

submit_task_unparameterized_if_no_parameter(instance: Object, method: String, parameter = null, task_tag = null, time_limit : float = task_time_limit) # like submit_task() but if parameter is equal to null it uses submit_task_unparameterized() instead of submit_task()

load_scene_with_interactive(path, print_to_console = true, time_limit : float = task_time_limit) # uses ResourceLoader.load_interactive() to load your scene async while also updating the task's task.progress and it returns task so you can hook it up to a loading screen
