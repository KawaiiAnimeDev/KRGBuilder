class_name InputManager
extends Node

signal lane_pressed(lane: int, touch_id: int)
signal lane_released(lane: int, touch_id: int)

@export var camera: Camera3D
@export var judgement_y: float = 0.0
@export var left_knob: Node3D
@export var right_knob: Node3D
@export var knob_touch_radius: float = 100.0
@export var knob_sensitivity: float = 1.0

var left_angle_min_deg: float = 90.0
var left_angle_max_deg: float = 15.0

var right_angle_min_deg: float = 165.0
var right_angle_max_deg: float = 90.0

var knob_angle_deg: Dictionary = {}

var lanes: Array[LaneConfig] = []
var active_touches: Dictionary = {}
var last_touch_pos: Dictionary = {}
var active_knob_drags: Dictionary = {}

func setup(built_lanes: Array[LaneConfig]) -> void:
	lanes = built_lanes

func _ready() -> void:
	right_angle_min_deg = 180.0 - left_angle_max_deg
	right_angle_max_deg = 180.0 - left_angle_min_deg
	if left_knob != null:
		knob_angle_deg[left_knob] = rad_to_deg(left_knob.rotation.z)
	if right_knob != null:
		knob_angle_deg[right_knob] = rad_to_deg(right_knob.rotation.z)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_handle_drag(event.index, event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_touch(0, event.position, event.pressed)
	elif event is InputEventMouseMotion:
		if active_knob_drags.has(0):
			_handle_drag(0, event.position)

func _handle_touch(index: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		var knob := _get_knob_at_screen_pos(pos)
		if knob != null:
			active_knob_drags[index] = knob
			last_touch_pos[index] = pos
			return
		var lane := _lane_from_screen_pos(pos)
		if lane != -1:
			active_touches[index] = lane
			lane_pressed.emit(lane, index)
	else:
		if active_touches.has(index):
			var lane: int = active_touches[index]
			lane_released.emit(lane, index)
			active_touches.erase(index)
		if active_knob_drags.has(index):
			active_knob_drags.erase(index)
			last_touch_pos.erase(index)

func _handle_drag(index: int, pos: Vector2) -> void:
	if not active_knob_drags.has(index):
		return
	var knob: Node3D = active_knob_drags[index]
	var center: Vector2 = camera.unproject_position(knob.global_position)

	if last_touch_pos.has(index):
		var drag_delta: Vector2 = pos - last_touch_pos[index]
		var offset: Vector2 = pos - center
		var dist: float = offset.length()

		var dir := Vector2.UP
		if dist > 1.0:
			dir = offset / dist

		var tangent := Vector2(-dir.y, dir.x)
		var tangential_delta := drag_delta.dot(tangent)
		var delta_rad := (tangential_delta / knob_touch_radius) * knob_sensitivity

		var old_rot_deg: float = rad_to_deg(knob.rotation.z)
		var bounds: Vector2 = _get_knob_bounds(knob)
		var lo: float = min(bounds.x, bounds.y)
		var hi: float = max(bounds.x, bounds.y)

		var target_rot_deg: float = old_rot_deg - rad_to_deg(delta_rad)
		var clamped_rot_deg: float = clamp(target_rot_deg, lo, hi)
		knob.rotation.z = deg_to_rad(clamped_rot_deg)

	last_touch_pos[index] = pos


func _lane_from_screen_pos(screen_pos: Vector2) -> int:
	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_dir := camera.project_ray_normal(screen_pos)
	var plane := Plane(Vector3.UP, judgement_y)
	var hit = plane.intersects_ray(ray_origin, ray_dir)

	if hit == null:
		return -1

	for lane in lanes:
		if lane.contains(hit.x):
			return lane.index
	return -1

func _get_knob_at_screen_pos(pos: Vector2) -> Node3D:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		cam = camera
	for knob in [left_knob, right_knob]:
		if knob == null:
			continue
		var screen_pos := cam.unproject_position(knob.global_position)
		if pos.distance_to(screen_pos) <= knob_touch_radius:
			return knob
	return null

func _get_knob_bounds(knob: Node3D) -> Vector2:
	if knob == left_knob:
		return Vector2(left_angle_min_deg, left_angle_max_deg)
	return Vector2(right_angle_min_deg, right_angle_max_deg)

func _knob_value(knob: Node3D) -> float:
	var bounds: Vector2 = _get_knob_bounds(knob)
	var rot_deg: float = rad_to_deg(knob.rotation.z)
	return inverse_lerp(bounds.x, bounds.y, rot_deg)
