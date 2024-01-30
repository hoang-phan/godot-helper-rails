extends Node2D
class_name ObjectFollowerComponent

@export var anim : AnimationComponent
@export var stats : StatsComponent
@export var follower_group : String = "player"

var actor : CharacterBody2D
var follower : Node2D

func _ready():
	actor = get_parent()
	follower = get_nearest_object()

func _physics_process(delta: float):
	var direction : Vector2 = global_position.direction_to(follower.global_position)
	anim.setTree("parameters/walk/dir/blend_position", direction)

	actor.velocity = stats.speed * direction
	actor.move_and_slide()

func get_nearest_object():
	var min_distance = 999999
	var result = null
	for obj in get_tree().get_nodes_in_group(follower_group):
		var distance = position.distance_to(obj.position)
		if distance < min_distance:
			result = obj
			min_distance = distance
	return result
