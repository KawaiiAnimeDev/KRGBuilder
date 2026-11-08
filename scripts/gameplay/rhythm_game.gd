extends Node

const JUDGEMENT_Z: float = -1.25

@export var input_manager: InputManager
@export var track_separators: Node3D
@export var lane_glow_meshes: Array[MeshInstance3D]

@export var scroll_speed: float = 10.0
@export var trace_material: Material

var knob_manager: CylindricalKnobManager
var current_time: float = 0.0
var trace_mesh_nodes: Array[MeshInstance3D] = []

func _ready() -> void:
	if trace_material == null:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.albedo_color = Color(0.2, 0.8, 1.0, 0.85)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.render_priority = 10
		trace_material = mat

	knob_manager = CylindricalKnobManager.new()
	knob_manager.input_manager = input_manager
	add_child(knob_manager)

	knob_manager.trace_tick_hit.connect(_on_trace_hit)
	knob_manager.trace_tick_miss.connect(_on_trace_miss)

	_spawn_test_traces()

func _spawn_test_traces() -> void:
	var left_min := deg_to_rad(input_manager.left_angle_min_deg)
	var left_max := deg_to_rad(input_manager.left_angle_max_deg)
	var right_min := deg_to_rad(input_manager.right_angle_min_deg)
	var right_max := deg_to_rad(input_manager.right_angle_max_deg)

	var left_note := ChartNote.new()
	left_note.type = ChartNote.NoteType.TRACE
	left_note.trace_id = 0
	left_note.time = 2.0
	left_note.end_time = 7.0
	left_note.start_value = 0.0
	left_note.end_value = 1.0
	left_note.interpolation = ChartNote.InterpolationType.SISO

	knob_manager.register_trace(left_note)
	_build_and_attach_mesh(left_note, Vector2(-5.3, 0.0), 0.8, left_min, left_max)

	var right_note := ChartNote.new()
	right_note.type = ChartNote.NoteType.TRACE
	right_note.trace_id = 1
	right_note.time = 3.0
	right_note.end_time = 8.0
	right_note.start_value = 1.0
	right_note.end_value = 0.0
	right_note.interpolation = ChartNote.InterpolationType.SISO

	knob_manager.register_trace(right_note)
	_build_and_attach_mesh(right_note, Vector2(5.3, 0.0), 0.8, right_min, right_max)

func _build_and_attach_mesh(note: ChartNote, center: Vector2, radius: float, angle_min: float, angle_max: float) -> void:
	var mesh := CylindricalTraceMeshBuilder.create_cylindrical_trace_mesh(
		note,
		center,
		radius,
		angle_min,
		angle_max,
		scroll_speed,
		0.35,
		0.12,
		0.01,
		64
	)

	var mesh_node := MeshInstance3D.new()
	mesh_node.mesh = mesh
	mesh_node.material_override = trace_material
	mesh_node.set_meta("note_start_time", note.time)

	get_parent().add_child.call_deferred(mesh_node)
	trace_mesh_nodes.append(mesh_node)

func _process(delta: float) -> void:
	current_time += delta

	for mesh_node in trace_mesh_nodes:
		var start_time: float = mesh_node.get_meta("note_start_time")
		mesh_node.position.z = JUDGEMENT_Z - (start_time - current_time) * scroll_speed

	knob_manager.process_traces(current_time)

func _on_trace_hit(note: ChartNote) -> void:
	print("TRACE HIT | ID: ", note.trace_id, " | Time: ", snp(current_time, 2))

func _on_trace_miss(note: ChartNote) -> void:
	print("TRACE MISS | ID: ", note.trace_id, " | Time: ", snp(current_time, 2))

func snp(val: float, decimals: int) -> float:
	var step := pow(10.0, decimals)
	return round(val * step) / step
