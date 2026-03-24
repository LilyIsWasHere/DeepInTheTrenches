# frozen navigation data per request for thread safety

extends RefCounted
class_name NavPlanSnapshot

var start: Vector3 = Vector3.ZERO
var target: Vector3 = Vector3.ZERO
var agent_config: NavAgentConfig = null
var agent_context: Dictionary = {}
var terrain_snapshot: NavTerrainSnapshot = null
