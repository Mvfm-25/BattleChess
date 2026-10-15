class_name BoardView
extends Node3D
## Desenha o tabuleiro e as peças, e traduz cliques em casas.
## Não conhece as regras: só recebe ordens do GameManager.

signal square_clicked(sq: int)

const SQUARE_SIZE := 1.0
const MOVE_TIME := 0.3
const HIGHLIGHT_Y := 0.01

@export var piece_scene: PackedScene
@export var light_color := Color(0.93, 0.86, 0.72)
@export var dark_color := Color(0.46, 0.31, 0.2)
@export var frame_color := Color(0.22, 0.14, 0.09)

@onready var _squares: Node3D = $Squares
@onready var _highlights: Node3D = $Highlights
@onready var _pieces: Node3D = $Pieces

var _piece_views := {}  # casa (int) -> PieceView

var _selection_mesh := PlaneMesh.new()
var _move_mesh := CylinderMesh.new()
var _capture_mesh := TorusMesh.new()
var _selection_mat := _make_highlight_material(Color(1.0, 0.85, 0.2, 0.55))
var _move_mat := _make_highlight_material(Color(0.2, 0.75, 0.3, 0.8))
var _capture_mat := _make_highlight_material(Color(0.9, 0.2, 0.15, 0.85))


func _ready() -> void:
	_selection_mesh.size = Vector2(SQUARE_SIZE, SQUARE_SIZE) * 0.95
	_move_mesh.top_radius = 0.14
	_move_mesh.bottom_radius = 0.14
	_move_mesh.height = 0.02
	_capture_mesh.inner_radius = 0.38
	_capture_mesh.outer_radius = 0.46
	_build_squares()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var sq := _square_under_mouse(event.position)
		if sq != -1:
			square_clicked.emit(sq)


func square_to_world(sq: int) -> Vector3:
	# Tabuleiro centrado na origem; brancas no lado +Z (a1 em x = -3.5, z = +3.5).
	return Vector3(
		(PieceTypes.file_of(sq) - 3.5) * SQUARE_SIZE,
		0.0,
		(3.5 - PieceTypes.rank_of(sq)) * SQUARE_SIZE)


func world_to_square(pos: Vector3) -> int:
	var file := floori(pos.x / SQUARE_SIZE + 4.0)
	var rank := floori(4.0 - pos.z / SQUARE_SIZE)
	if file < 0 or file > 7 or rank < 0 or rank > 7:
		return -1
	return PieceTypes.square(file, rank)


func show_board(board: ChessBoard) -> void:
	clear_highlights()
	for child in _pieces.get_children():
		child.queue_free()
	_piece_views.clear()
	for sq in 64:
		var piece := board.piece_at(sq)
		if piece != PieceTypes.EMPTY:
			_spawn_piece(piece, sq)


func apply_move(move: Move) -> void:
	clear_highlights()
	var view: PieceView = _piece_views[move.from_sq]
	var victim: PieceView = _piece_views.get(move.to_sq)
	if victim:
		victim.capture(MOVE_TIME * 0.5)
	_piece_views.erase(move.from_sq)
	_piece_views[move.to_sq] = view
	view.move_to(square_to_world(move.to_sq), MOVE_TIME)
	if move.promotion != PieceTypes.Type.NONE:
		view.set_type(move.promotion)


func show_selection(sq: int, moves: Array[Move]) -> void:
	clear_highlights()
	_add_highlight(_selection_mesh, _selection_mat, sq)
	for move in moves:
		if _piece_views.has(move.to_sq):
			_add_highlight(_capture_mesh, _capture_mat, move.to_sq)
		else:
			_add_highlight(_move_mesh, _move_mat, move.to_sq)


func clear_highlights() -> void:
	for child in _highlights.get_children():
		child.queue_free()


func _spawn_piece(piece: int, sq: int) -> void:
	var view: PieceView = piece_scene.instantiate()
	view.setup(PieceTypes.type_of(piece), PieceTypes.side_of(piece))
	_pieces.add_child(view)
	view.position = square_to_world(sq)
	_piece_views[sq] = view


func _square_under_mouse(screen_pos: Vector2) -> int:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return -1
	var plane := Plane(Vector3.UP, global_position.y)
	var hit = plane.intersects_ray(camera.project_ray_origin(screen_pos), camera.project_ray_normal(screen_pos))
	if hit == null:
		return -1
	return world_to_square(to_local(hit))


func _build_squares() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(SQUARE_SIZE, 0.1, SQUARE_SIZE)
	var light_mat := _make_surface_material(light_color)
	var dark_mat := _make_surface_material(dark_color)
	for sq in 64:
		var inst := MeshInstance3D.new()
		inst.mesh = mesh
		var is_dark := (PieceTypes.file_of(sq) + PieceTypes.rank_of(sq)) % 2 == 0
		inst.material_override = dark_mat if is_dark else light_mat
		inst.position = square_to_world(sq) + Vector3(0.0, -0.05, 0.0)
		_squares.add_child(inst)

	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(8.6, 0.1, 8.6) * Vector3(SQUARE_SIZE, 1.0, SQUARE_SIZE)
	var frame := MeshInstance3D.new()
	frame.mesh = frame_mesh
	frame.material_override = _make_surface_material(frame_color)
	frame.position = Vector3(0.0, -0.07, 0.0)
	_squares.add_child(frame)


func _add_highlight(mesh: Mesh, material: Material, sq: int) -> void:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = material
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inst.position = square_to_world(sq) + Vector3(0.0, HIGHLIGHT_Y, 0.0)
	_highlights.add_child(inst)


static func _make_surface_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	return mat


static func _make_highlight_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat
