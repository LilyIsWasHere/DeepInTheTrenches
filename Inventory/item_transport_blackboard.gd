extends Node


# used for item transportation
var pickup_requests: Array[Array]
var dropoff_requests: Array[Array]

var pickup_request_inv_item_map: Dictionary[Array, ItemTransportRequest]
var dropoff_request_inv_item_map: Dictionary[Array, ItemTransportRequest]


func _ready() -> void:
	for i in range(ItemTransportRequest.RequestPriority.SIZE):
		pickup_requests.append([])
		dropoff_requests.append([])



func claim_closest_item_pickup(position: Vector3, item: InventoryItem, quantity: int) ->ItemTransportRequest:
	
	var closest: ItemTransportRequest = null
	var closest_dist: float = INF
		
	for idx in range(ItemTransportRequest.RequestPriority.SIZE):
		var pickup_arr: Array = pickup_requests[idx]
		for pickup: ItemTransportRequest in pickup_arr:
			if (pickup.item == item):
				if (pickup.inventory.global_position.distance_to(position) < closest_dist):
					closest = pickup
				
	if (closest): _claim_pickup_request(closest, quantity)
	return closest
	
func claim_closest_item_dropoff(position: Vector3, item: InventoryItem, quantity: int) ->ItemTransportRequest:
	
	var closest: ItemTransportRequest = null
	var closest_dist: float = INF
		
	for idx in range(ItemTransportRequest.RequestPriority.SIZE):
		var dropoff_arr: Array = dropoff_requests[idx]
		for dropoff: ItemTransportRequest in dropoff_arr:
			if (dropoff.item == item):
				if (dropoff.inventory.global_position.distance_to(position) < closest_dist):
					closest = dropoff
				
	if (closest): _claim_dropoff_request(closest, quantity)
	return closest
	
	
func item_dropoff_exists(item: InventoryItem) -> bool:
	for idx in range(ItemTransportRequest.RequestPriority.SIZE):
		var dropoff_arr: Array = dropoff_requests[idx]
		for dropoff: ItemTransportRequest in dropoff_arr:
			if (dropoff.item == item && dropoff.quantity > 0):
				return true
				
	return false
				

	

func has_bidirecional_request(inventory: Inventory, item :InventoryItem) -> bool:
	return false
	#var pickup: ItemTransportRequest = pickup_request_inv_item_map.get([inventory, item])
	#var dropoff: ItemTransportRequest = dropoff_request_inv_item_map.get([inventory, item])
	#if (!pickup || !dropoff): return false
	#return !pickup.local && !dropoff.local

func claim_pickup_dropoff_pair(near_point: Vector3) -> Array[ItemTransportRequest]:
	
		
	# Find the closest pickup request to the provided point
	
	var closest_pickup: ItemTransportRequest = null
	var closest_dist: float = INF
	var matching_dropoff: ItemTransportRequest = null
	
	for p_idx in range(ItemTransportRequest.RequestPriority.SIZE):
		for pickup: ItemTransportRequest in pickup_requests[p_idx]:
			var dist: float = near_point.distance_to(pickup.inventory.global_position)
			if (dist < closest_dist):
				var dropoff: ItemTransportRequest = _find_matching_dropoff(pickup)
				if (!dropoff || has_bidirecional_request(dropoff.inventory, dropoff.item) && !dropoff.local): 
					continue
					
				
				closest_pickup = pickup
				closest_dist = dist
				matching_dropoff = dropoff
				
		if closest_pickup != null:
			break
		
	if (!closest_pickup || !matching_dropoff):
		return []
		
	else:
		
		var qty: int = min(closest_pickup.quantity, matching_dropoff.quantity)
		
		_claim_pickup_request(closest_pickup, qty)
		_claim_dropoff_request(matching_dropoff, qty)
		
		return [closest_pickup, matching_dropoff]
		
		
func _find_matching_dropoff(pickup_request: ItemTransportRequest) -> ItemTransportRequest:
	
	for d_idx in range(ItemTransportRequest.RequestPriority.SIZE):
		var dropoff_arr: Array = dropoff_requests[d_idx]
		for dropoff: ItemTransportRequest in dropoff_arr:
			if (dropoff.item == pickup_request.item && !has_bidirecional_request(dropoff.inventory, dropoff.item) && !dropoff.local):
				return dropoff
				
	return null
			

func request_pickup(from_inventory: Inventory, item: InventoryItem, qty: int, priority: ItemTransportRequest.RequestPriority, is_local: bool = false) -> void:
	var existing_request: ItemTransportRequest = pickup_request_inv_item_map.get([from_inventory, item])
	
	if (existing_request):
		if (existing_request.priority != priority):
			pickup_requests[existing_request.priority].erase(existing_request)
			pickup_requests[priority].append(existing_request)
			existing_request.priority = priority
			existing_request.local = is_local
		
		existing_request.quantity += qty
		
	else:
		var new_request: ItemTransportRequest = ItemTransportRequest.new()
		new_request.inventory = from_inventory
		new_request.item = item
		new_request.priority = priority
		new_request.quantity = qty
		new_request.type = ItemTransportRequest.RequestType.PICKUP
		new_request.local = is_local
		pickup_requests[priority].append(new_request)
		var key: Array = [from_inventory, item]
		pickup_request_inv_item_map.set(key, new_request)	

func request_dropoff(to_inventory: Inventory, item: InventoryItem, qty: int, priority: ItemTransportRequest.RequestPriority, is_local: bool = false) -> void:
	var existing_request: ItemTransportRequest = dropoff_request_inv_item_map.get([to_inventory, item])
	
	if (existing_request):
		if (existing_request.priority != priority):
			dropoff_requests[existing_request.priority].erase(existing_request)
			dropoff_requests[priority].append(existing_request)
			existing_request.priority = priority
			existing_request.local = is_local
		existing_request.quantity += qty
		
	else:
		var new_request: ItemTransportRequest = ItemTransportRequest.new()
		new_request.inventory = to_inventory
		new_request.item = item
		new_request.priority = priority
		new_request.quantity = qty
		new_request.type = ItemTransportRequest.RequestType.DROPOFF
		new_request.local = is_local
		dropoff_requests[priority].append(new_request)
		var key: Array = [to_inventory, item]
		dropoff_request_inv_item_map.set(key, new_request)	

	
func _claim_pickup_request(request: ItemTransportRequest, pickup_qty: int) -> void:
	pickup_request_inv_item_map.erase([request.inventory, request.item])
	pickup_requests[request.priority].erase(request)
	
	assert(pickup_qty <= request.quantity)
	
	if (pickup_qty < request.quantity):
		request_pickup(request.inventory, request.item, request.quantity - pickup_qty, request.priority)
	
func _claim_dropoff_request(request: ItemTransportRequest, dropoff_qty: int) -> void:
	dropoff_request_inv_item_map.erase([request.inventory, request.item])
	dropoff_requests[request.priority].erase(request)
	
	#assert(dropoff_qty <= request.quantity)
	
	if (dropoff_qty < request.quantity):
		request_dropoff(request.inventory, request.item, request.quantity - dropoff_qty, request.priority)

	
func _unclaim_pickup_request(request: ItemTransportRequest) -> void:
	request_pickup(request.inventory, request.item, request.quantity, request.priority)
	
func _unclaim_dropoff_request(request: ItemTransportRequest) -> void:
	request_dropoff(request.inventory, request.item, request.quantity, request.priority)
	
	


	
