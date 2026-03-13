extends RefCounted
class_name NavPlanHandle

# You can use these signals to know when the path is ready, updated, or failed.
signal ready
signal updated
signal failed

enum NavRequestStatus {
	PENDING,    # Request is being processed
	READY,      # Path is ready and can be sampled
	FAILED,     # Pathfinding failed (e.g., no path found)
	CANCELLED,  # Request was cancelled before completion
}

var status: NavRequestStatus = NavRequestStatus.PENDING
var target: Vector3 = Vector3.ZERO
var profile: int = 0
var waypoints: PackedVector3Array = PackedVector3Array()
var failure_reason: String = ""
