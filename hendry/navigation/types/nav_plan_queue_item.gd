extends RefCounted
class_name NavPlanQueueItem

var handle: NavPlanHandle = null  # handle for the rest of the game
var snapshot: NavPlanSnapshot = null  # all the data that the worker needs to solve the plan with
var path: PackedVector3Array = PackedVector3Array() # resulting path
