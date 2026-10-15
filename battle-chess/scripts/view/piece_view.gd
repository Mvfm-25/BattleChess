class_name PieceView
extends Node3D
## Representação visual de uma peça. Modelo provisório feito de primitivas;
## troque _build_model() por cenas importadas quando houver modelos de verdade.

@export var white_color := Color(0.92, 0.9, 0.84)
@export var black_color := Color(0.16, 0.14, 0.13)

var type := PieceTypes.Type.PAWN
var side := PieceTypes.Side.WHITE

@onready var _model: Node3D = $Model

var _tween: Tween
var _material: StandardMaterial3D


func setup(p_type: PieceTypes.Type, p_side: PieceTypes.Side) -> void:
	type = p_type
	side = p_side
	if is_node_ready():
		_build_model()


func _ready() -> void:
	_build_model()


func set_type(p_type: PieceTypes.Type) -> void:
	type = p_type
	_build_model()


## Move a peça num pequeno arco até target.
func move_to(target: Vector3, duration: float) -> void:
	if _tween:
		_tween.kill()
	var peak := (position + target) * 0.5 + Vector3.UP * 0.6
	_tween = create_tween()
	_tween.tween_property(self, "position", peak, duration * 0.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", target, duration * 0.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func capture(delay: float) -> void:
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


func _build_model() -> void:
	for child in _model.get_children():
		child.queue_free()
	_material = StandardMaterial3D.new()
	_material.albedo_color = white_color if side == PieceTypes.Side.WHITE else black_color
	_material.roughness = 0.35
	# "Frente" do modelo é -Z (em direção às pretas); as pretas olham para o outro lado.
	_model.rotation.y = 0.0 if side == PieceTypes.Side.WHITE else PI

	_add_cylinder(0.34, 0.34, 0.1, 0.0)  # base
	match type:
		PieceTypes.Type.PAWN:
			_add_cylinder(0.22, 0.12, 0.35, 0.1)
			_add_sphere(0.15, 0.55)
		PieceTypes.Type.ROOK:
			_add_cylinder(0.26, 0.23, 0.5, 0.1)
			_add_cylinder(0.3, 0.3, 0.16, 0.6)
		PieceTypes.Type.KNIGHT:
			_add_cylinder(0.25, 0.17, 0.35, 0.1)
			_add_box(Vector3(0.2, 0.26, 0.48), Vector3(0.0, 0.6, -0.08), Vector3(0.45, 0.0, 0.0))
		PieceTypes.Type.BISHOP:
			_add_cylinder(0.24, 0.11, 0.5, 0.1)
			_add_sphere(0.17, 0.72, 1.35)
			_add_sphere(0.06, 0.98)
		PieceTypes.Type.QUEEN:
			_add_cylinder(0.26, 0.12, 0.65, 0.1)
			_add_cylinder(0.13, 0.24, 0.14, 0.75)
			_add_sphere(0.08, 0.96)
		PieceTypes.Type.KING:
			_add_cylinder(0.27, 0.13, 0.75, 0.1)
			_add_cylinder(0.14, 0.24, 0.14, 0.85)
			_add_box(Vector3(0.07, 0.3, 0.07), Vector3(0.0, 1.14, 0.0))
			_add_box(Vector3(0.22, 0.07, 0.07), Vector3(0.0, 1.17, 0.0))


func _add_cylinder(bottom_radius: float, top_radius: float, height: float, base_y: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom_radius
	mesh.top_radius = top_radius
	mesh.height = height
	_add_part(mesh, Vector3(0.0, base_y + height * 0.5, 0.0))


func _add_sphere(radius: float, center_y: float, stretch_y := 1.0) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0 * stretch_y
	_add_part(mesh, Vector3(0.0, center_y, 0.0))


func _add_box(size: Vector3, center: Vector3, rotation_rad := Vector3.ZERO) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_add_part(mesh, center).rotation = rotation_rad


func _add_part(mesh: Mesh, pos: Vector3) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = _material
	inst.position = pos
	_model.add_child(inst)
	return inst
