class_name CameraRig
extends Node3D
## Câmera orbital: o rig fica no ponto de foco (centro do tabuleiro).
## CameraRig gira em Y (yaw), Pitch gira em X, e a Camera3D fica afastada em +Z,
## então ela sempre olha para a origem do rig.

@export var rotate_sensitivity := 0.005
@export_range(5.0, 89.0) var min_pitch_deg := 20.0
@export_range(5.0, 89.0) var max_pitch_deg := 85.0
@export var min_distance := 6.0
@export var max_distance := 18.0
@export var zoom_step := 1.0
@export var smoothing := 10.0
@export var start_pitch_deg := 55.0
@export var start_distance := 12.0

@onready var _pitch_node: Node3D = $Pitch
@onready var _camera: Camera3D = $Pitch/Camera3D

var _yaw := 0.0
var _pitch := 0.0
var _distance := 0.0
var _target_yaw := 0.0
var _target_pitch := 0.0
var _target_distance := 0.0


func _ready() -> void:
	_pitch = deg_to_rad(start_pitch_deg)
	_distance = start_distance
	_target_pitch = _pitch
	_target_distance = _distance
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		_target_yaw -= event.relative.x * rotate_sensitivity
		_target_pitch = clampf(_target_pitch + event.relative.y * rotate_sensitivity,
				deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	elif event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_target_distance = maxf(_target_distance - zoom_step, min_distance)
			MOUSE_BUTTON_WHEEL_DOWN:
				_target_distance = minf(_target_distance + zoom_step, max_distance)


func _process(delta: float) -> void:
	var t := 1.0 - exp(-smoothing * delta)  # suavização independente de framerate
	_yaw = lerpf(_yaw, _target_yaw, t)
	_pitch = lerpf(_pitch, _target_pitch, t)
	_distance = lerpf(_distance, _target_distance, t)
	_apply()


func _apply() -> void:
	rotation.y = _yaw
	_pitch_node.rotation.x = -_pitch  # negativo = câmera acima do tabuleiro
	_camera.position = Vector3(0.0, 0.0, _distance)
