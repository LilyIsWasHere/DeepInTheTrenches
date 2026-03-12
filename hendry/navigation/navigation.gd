extends Node

# const NavPlanHandle := preload("res://hendry/navigation/types/nav_plan_handle.gd")
# const NavSteeringResult := preload("res://hendry/navigation/types/nav_steering_result.gd")

const NavMap := preload("res://hendry/navigation/nav_map.gd")
var _nav_map: NavMap = null

const DEFAULT_AGENT_RADIUS := 0.2
const DEFAULT_AGENT_HEIGHT := 1.7
const DEFAULT_AGENT_MAX_SPEED := 5.0
const DEFAULT_AGENT_MAX_SLOPE_DEGREES := 45.0
const DEFAULT_AGENT_MAX_STEP_HEIGHT := 1.0
const DEFAULT_AGENT_WALL_CLIMB_HEIGHT := 1.7

# Go in the trenches, or ignore the trenches?
enum NavProfileId {
	SAFE,
	DIRECT,
}

var _agent_properties: Dictionary = {}
var _active_requests: Dictionary = {}

func _ready() -> void:
	_nav_map = NavMap.new()

# Probably don't need this function. This is only if you want to change the agent properties mid-request.
func set_agent_properties(
	agent: Node,
	radius: float = DEFAULT_AGENT_RADIUS,
	height: float = DEFAULT_AGENT_HEIGHT,
	max_speed: float = DEFAULT_AGENT_MAX_SPEED,
	max_slope_degrees: float = DEFAULT_AGENT_MAX_SLOPE_DEGREES,
	max_step_height: float = DEFAULT_AGENT_MAX_STEP_HEIGHT,
	wall_climb_height: float = DEFAULT_AGENT_WALL_CLIMB_HEIGHT
) -> void:
	if agent == null:
		return

	_agent_properties[agent] = {
		"radius": radius,
		"height": height,
		"max_speed": max_speed,
		"max_slope_degrees": max_slope_degrees,
		"max_step_height": max_step_height,
		"wall_climb_height": wall_climb_height,
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
	_delta: float,
) -> NavSteeringResult:
	var steering := NavSteeringResult.new()

	if agent == null or handle == null:
		return steering

	return steering

# DEBUG
func debug_find_path(
	start: Vector3,
	goal: Vector3,
	agent_config: Dictionary,
	profile: int = Navigation.NavProfileId.SAFE
) -> PackedVector3Array:
	print("Debug find path with config:", agent_config)
	print("Debug find path with profile:", profile)
	return _nav_map.find_path(start, goal, agent_config, profile)
