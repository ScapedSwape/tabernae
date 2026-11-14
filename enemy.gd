extends Node2D

@export var follow_path_object: Node2D
@export var chase_speed: float = 100.0
@export var stop_dist: float = 0.4
@export var turnspeed: float = 1.3
@export var disabled: bool = false
@export var ground_check: Node2D
@export var ground_layer: int = 1

var player: Node2D
var entered_trigger: bool = false
var follow_path: Node
var rb: RigidBody2D
var closest_node: int = 0
var closest_dist: float = 99999.0

func _ready() -> void:
	if follow_path_object != null:
		follow_path = follow_path_object.get_node_or_null("FollowPath")
	else:
		follow_path_object = self
		follow_path = get_node_or_null("FollowPath")
	
	if follow_path != null:
		rb = follow_path.get("Rigidbodycontainer") as RigidBody2D
		if rb == null:
			rb = follow_path.get_node_or_null("Rigidbodycontainer") as RigidBody2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = body
		entered_trigger = true
		if follow_path:
			follow_path.set("disable", true)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		entered_trigger = false
		closest_node = 0
		closest_dist = 99999.0
		
		var pointvec = follow_path.get("pointvec")
		if pointvec == null:
			return
		
		for i in range(pointvec.size()):
			var node: Vector2 = pointvec[i]
			var challengerdist: float = node.distance_to(follow_path_object.global_position)
			if challengerdist <= closest_dist:
				closest_dist = challengerdist
				closest_node = i
		
		follow_path.set("target", closest_node)

func ground_check_ray() -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		ground_check.global_position,
		ground_check.global_position + Vector2(0, 14),
		ground_layer
	)
	var result = space_state.intersect_ray(query)
	
	if result.size() > 0:
		print("There is something under me!")
		return true
	
	print("There is not something under me!")
	return false

func _physics_process(delta: float) -> void:
	if disabled or rb == null:
		return
	
	if entered_trigger and player != null:
		var player_x = player.global_position.x
		var self_x = follow_path_object.global_position.x
		
		if abs(player_x - self_x) > stop_dist:
			if player_x < self_x:
				if rb.linear_velocity.x >= 0 or abs(rb.linear_velocity.x) <= chase_speed:
					if ground_check_ray():
						rb.linear_velocity.x -= turnspeed * delta
					else:
						rb.linear_velocity.x = 0
			else:
				if rb.linear_velocity.x <= 0 or abs(rb.linear_velocity.x) <= chase_speed:
					if ground_check_ray():
						rb.linear_velocity.x += turnspeed * delta
					else:
						rb.linear_velocity.x = 0
	else:
		if follow_path:
			follow_path.set("disable", false)

var health: int = 30

func take_damage(amount: int) -> void:
	health -= amount
	print("Enemy took damage! Health: ", health)
	if health <= 0:
		queue_free() # Or play a death animation

func die() -> void:
	set_deferred("monitoring", false) # Disable collision immediately [citation:3]
	queue_free()
	
	
	
