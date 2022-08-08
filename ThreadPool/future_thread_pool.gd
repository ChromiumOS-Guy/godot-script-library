class_name FutureThreadPool
extends Node
# A thread pool designed to perform your tasks efficiently
# Not independet from thread pool manager
# originally from the ThreadPool plugin for godot from the asset lib

signal task_completed(task)

export var use_signals: bool = false

var __tasks: Array = []
var __started = false
var __finished = false
var __tasks_lock: Mutex = Mutex.new()
var __tasks_wait: Semaphore = Semaphore.new()
var __thread_count = 0

onready var __pool = __create_pool() # creates pool when ready (remove onready if you plan to use this class standalone)

func _notification(what: int): # when exiting game this will activate 
	if what == NOTIFICATION_PREDELETE:
		__wait_for_shutdown()


func queue_free() -> void: # will shutdown the thread pool
	shutdown()
	.queue_free()

# all submit functions
func submit_task(instance: Object, method: String, parameter, task_tag = null) -> Future:
	return __enqueue_task(instance, method, parameter, task_tag, false, false, false)

func submit_task_as_parameter(instance: Object, method: String, parameter, task_tag = null) -> Future:
	return __enqueue_task(instance, method, parameter, task_tag, false, false, true)

func submit_task_unparameterized(instance: Object, method: String, task_tag = null) -> Future:
	return __enqueue_task(instance, method, null, task_tag, true, false, false)

func submit_task_as_only_parameter(instance: Object, method: String, task_tag = null) -> Future:
	return __enqueue_task(instance, method, null, task_tag, true, false, true)

func submit_task_array_parameterized(instance: Object, method: String, parameter: Array, task_tag = null) -> Future:
	return __enqueue_task(instance, method, parameter, task_tag, false, true, false)

func submit_task_unparameterized_if_no_parameter(instance: Object, method: String, parameter = null, task_tag = null) -> Future:
	if parameter == null:
		return __enqueue_task(instance, method, null, task_tag, true, false, false)
	else:
		return __enqueue_task(instance, method, parameter, task_tag, false, false, false)

# the shutdown method
func shutdown():
	__finished = true
	__tasks_lock.lock()
	if not __tasks.empty():
		var size = __tasks.size()
		for i in size:
			(__tasks[i] as Future).__finish()
		__tasks.clear()
	for i in __pool:
		__tasks_wait.post()
	__tasks_lock.unlock()


func do_nothing(arg) -> void: # fallback if something fails and a task is executed when no task exists
	#print("doing nothing")
	OS.delay_msec(1) # if there is nothing to do, go sleep

# the main task queueing function
func __enqueue_task(instance: Object, method: String, parameter = null, task_tag = null, no_argument = false, array_argument = false, task_as_argument = false) -> Future:
	var result = Future.new(instance, method, parameter, task_tag, no_argument, array_argument,task_as_argument, self) 
	if __finished:
		result.__finish()
		return result
	__tasks_lock.lock()
	__tasks.push_front(result)
	__tasks_wait.post()
	__start()
	__tasks_lock.unlock()
	return result


func __wait_for_shutdown(): # activates shutdown after all thread finished
	shutdown()
	for t in __pool:
		if t.is_active():
			t.wait_to_finish()

func __create_pool(): # creates the pool
	var result = []
	for c in range(OS.get_processor_count() if __thread_count == 0 else __thread_count):
		result.append(Thread.new())
	return result


func __start() -> void: # starts the threads in the pool in the __execute_tasks method
	if not __started:
		for t in __pool:
			if !(t as Thread).is_active():
				(t as Thread).start(self, "__execute_tasks", t)
		__started = true

func __drain_this_task(task: Future) -> Future: # while not used is highly useful if you need a specifc task
	__tasks_lock.lock()
	if __tasks.empty():
		__tasks_lock.unlock()
		return null
	var result = null
	var size = __tasks.size()
	for i in size:
		var candidate_task: Future = __tasks[i]
		if task == candidate_task:
			__tasks.remove(i)
			result = candidate_task
			break
	__tasks_lock.unlock()
	return result;


func __drain_task() -> Future:
	__tasks_lock.lock()
	var result
	if __tasks.empty():
		result = Future.new(self, "do_nothing", null, null, true, false,false, self)# normally, this is not expected, but better safe than sorry
		result.tag = result
	else:
		result = __tasks.pop_back()
	__tasks_lock.unlock()
	return result;

# the main threads loop
func __execute_tasks(arg_thread) -> void:
	#print_debug(arg_thread)
	while not __finished:
		__tasks_wait.wait()
		if __finished:
			return
		var task: Future = __drain_task()
		__execute_this_task(task)

# secondary main threads function for executing a task
func __execute_this_task(task: Future) -> void:
	if task.cancelled:
		task.__finish()
		return
	task.__execute_task()
	task.completed = true
	task.__finish()
	if use_signals:
		if not (task.tag is Future):# tasks tagged this way are considered hidden
			call_deferred("emit_signal", "task_completed", task)

class Future: # the Future(task) object (basiclly a task template)
	var target_instance: Object
	var target_method: String
	var target_argument
	var result
	var progress
	var tag
	var cancelled: bool # true if was requested for this future to avoid being executed
	var completed: bool # true if this future executed completely
	var finished: bool # true if this future is considered finished and no further processing will take place
	var __no_argument: bool
	var __array_argument: bool
	var __task_as_argument: bool
	var __lock: Mutex
	var __wait: Semaphore
	var __pool: FutureThreadPool

	#initialization of a task: Future.new()
	func _init(instance: Object, method: String, parameter, task_tag, no_argument: bool, array_argument: bool,task_as_argument: bool , pool: FutureThreadPool):
		target_instance = instance
		target_method = method
		target_argument = parameter
		result = null
		tag = task_tag
		__no_argument = no_argument
		__array_argument = array_argument
		__task_as_argument = task_as_argument
		cancelled = false
		completed = false
		finished = false
		__lock = Mutex.new()
		__wait = Semaphore.new()
		__pool = pool


	func cancel() -> void: # if task is cancelled
		cancelled = true


	func wait_for_result() -> void: # does what is says
		if not finished:
			__verify_task_execution()


	func get_result(): # goes and gets result
		wait_for_result()
		return result


	func __execute_task(): # sorts call cases and calls upon them when needed
		if __no_argument and __task_as_argument:
			result = target_instance.call(target_method , self)
		elif __no_argument:
			result = target_instance.call(target_method)
		elif __array_argument:
			result = target_instance.callv(target_method, target_argument)
		elif __task_as_argument:
			result = target_instance.call(target_method, target_argument, self)
		else:
			result = target_instance.call(target_method, target_argument)
		__wait.post()


	func __verify_task_execution() -> void: # verifies that the task has been executed
		__lock.lock()
		if not finished:
			var task: Future = null
			if __pool != null:
				task = __pool.__drain_this_task(self)
			if task != null:
				__pool.__execute_this_task(task)
			else:
				__wait.wait()
		__lock.unlock()


	func __finish(): # finalizes the task for deletion
		finished = true
		__pool = null
