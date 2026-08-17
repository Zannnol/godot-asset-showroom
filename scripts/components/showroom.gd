@tool
extends Node3D

@export var test_material: Material:
	set(value):
		test_material = value
		_apply_material()

@export var target_parent: Node3D

func _ready() -> void:
	_apply_material()

func _apply_material() -> void:
	if not target_parent:
		return
	for child in target_parent.get_children():
		if child is MeshInstance3D:
			child.material_override = test_material
