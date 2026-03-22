# combines the handle and snapshot into one object for easier queue management

extends RefCounted
class_name NavPlanQueueItem

var handle: NavPlanHandle = null
var snapshot: NavPlanSnapshot = null
