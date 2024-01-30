extends Node2D
class_name AnimationComponent

@onready var tree : AnimationTree = $AnimationTree
@onready var playback : AnimationNodeStateMachinePlayback = tree.get("parameters/playback")

func setTree(key: String, value):
	tree.set(key, value)

func travel(state: String):
	playback.travel(state)
