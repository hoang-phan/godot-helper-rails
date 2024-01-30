extends Node2D
class_name PlayerMovementComponent

@export var anim : AnimationComponent
@export var stats : StatsComponent
var actor : CharacterBody2D

func _ready():
	actor = get_parent()

func _physics_process(delta: float):
	var direction : Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	actor.velocity = direction * stats.speed
	
	if direction == Vector2.ZERO:
		anim.travel("idle")
	else:
		anim.travel("run")
		anim.setTree("parameters/run/dir/blend_position", direction)
		anim.setTree("parameters/idle/dir/blend_position", direction)

	actor.move_and_slide()
