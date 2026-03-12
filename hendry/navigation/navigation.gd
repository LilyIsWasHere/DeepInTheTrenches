extends Node

const NavPlanHandle := preload("res://hendry/navigation/types/nav_plan_handle.gd")
const NavSteeringResult := preload("res://hendry/navigation/types/nav_steering_result.gd")

# Go in the trenches, or ignore the trenches?
enum NavProfileId {
	SAFE,
	DIRECT,
}

var _agent_properties: Dictionary = {}
var _active_requests: Dictionary = {}

# Probably don't need this function. This is only if you want to change the agent properties mid-request.
func set_agent_properties(
	agent: Node,
	radius: float = 0.45,
	max_speed: float = 5.0,
	max_slope_degrees: float = 30.0,
) -> void:
	if agent == null:
		return

	_agent_properties[agent] = {
		"radius": radius,
		"max_speed": max_speed,
		"max_slope_degrees": max_slope_degrees,
	}

# Call this function to remove an agent from the navigation system. This will cancel any active requests for that agent and free up resources.
func remove_agent(agent: Node) -> void:
	if agent == null:
		return

	_agent_properties.erase(agent)
	_active_requests.erase(agent)

# Call this function to request a path to a target. Returns a NavPlanHandle that can be used to track the status of the request and sample steering results.
func request_move(
	agent: Node,
	target: Vector3,
	profile: NavProfileId = NavProfileId.SAFE,
) -> NavPlanHandle:
	if agent == null:
		return null

	if not _agent_properties.has(agent):
		set_agent_properties(agent)

	var handle := NavPlanHandle.new()
	handle.target = target
	handle.profile = profile

	_active_requests[agent] = handle
	return handle

# Same as above but you can do it for a bunch of agents. Returns a dict mapping each agent to their NavPlanHandle.
func request_batch_move(
	agents: Array[Node],
	target: Vector3,
	profile: NavProfileId = NavProfileId.SAFE,
) -> Dictionary:
	var result: Dictionary = {}

	for agent in agents:
		var handle := request_move(agent, target, profile)
		if handle != null:
			result[agent] = handle

	return result

# Call this function to cancel an active path request for an agent.
func cancel_request(handle: NavPlanHandle) -> void:
	if handle == null:
		return

	handle.status = NavPlanHandle.NavRequestStatus.CANCELLED

# Call this function to ask where the agent should go next. Returns a NavSteeringResult with all the info you need.
func sample_steering(
	agent: Node,
	handle: NavPlanHandle,
	delta: float,
) -> NavSteeringResult:
	var steering := NavSteeringResult.new()

	if agent == null or handle == null:
		return steering

	return steering
