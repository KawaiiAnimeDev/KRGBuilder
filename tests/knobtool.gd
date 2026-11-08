@tool
extends Node

@export var generate_knob: bool = false:
	set(value):
		if value:
			generate_and_save_knob()
			generate_knob = false

func generate_and_save_knob() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var radius: float = 0.85
	var thickness: float = 0.2
	var arrow_length: float = 0.35
	var arrow_angle: float = 0.25
	var segments: int = 64
	var half_z: float = thickness * 0.5
	
	# 1. Cylinder Body
	for i in range(segments):
		var u1: float = float(i) / segments
		var u2: float = float(i + 1) / segments
		var a1: float = u1 * TAU
		var a2: float = u2 * TAU
		
		var cos1: float = cos(a1)
		var sin1: float = sin(a1)
		var cos2: float = cos(a2)
		var sin2: float = sin(a2)
		
		var p1_front = Vector3(radius * cos1, radius * sin1, half_z)
		var p2_front = Vector3(radius * cos2, radius * sin2, half_z)
		var p1_back = Vector3(radius * cos1, radius * sin1, -half_z)
		var p2_back = Vector3(radius * cos2, radius * sin2, -half_z)
		
		# Front Cap
		st.set_uv(Vector2(0.5, 0.5))
		st.add_vertex(Vector3(0, 0, half_z))
		st.set_uv(Vector2(0.5 + cos1 * 0.5, 0.5 + sin1 * 0.5))
		st.add_vertex(p1_front)
		st.set_uv(Vector2(0.5 + cos2 * 0.5, 0.5 + sin2 * 0.5))
		st.add_vertex(p2_front)
		
		# Back Cap
		st.set_uv(Vector2(0.5, 0.5))
		st.add_vertex(Vector3(0, 0, -half_z))
		st.set_uv(Vector2(0.5 + cos2 * 0.5, 0.5 + sin2 * 0.5))
		st.add_vertex(p2_back)
		st.set_uv(Vector2(0.5 + cos1 * 0.5, 0.5 + sin1 * 0.5))
		st.add_vertex(p1_back)
		
		# Rim Quads
		st.set_uv(Vector2(u1, 1.0))
		st.add_vertex(p1_front)
		st.set_uv(Vector2(u1, 0.0))
		st.add_vertex(p1_back)
		st.set_uv(Vector2(u2, 1.0))
		st.add_vertex(p2_front)
		
		st.set_uv(Vector2(u2, 1.0))
		st.add_vertex(p2_front)
		st.set_uv(Vector2(u1, 0.0))
		st.add_vertex(p1_back)
		st.set_uv(Vector2(u2, 0.0))
		st.add_vertex(p2_back)

	# 2. Arrow Pointer
	var tip_front = Vector3(radius + arrow_length, 0.0, half_z)
	var tip_back = Vector3(radius + arrow_length, 0.0, -half_z)
	
	var t_left_front = Vector3(radius * cos(arrow_angle), radius * sin(arrow_angle), half_z)
	var t_right_front = Vector3(radius * cos(-arrow_angle), radius * sin(-arrow_angle), half_z)
	var t_left_back = Vector3(radius * cos(arrow_angle), radius * sin(arrow_angle), -half_z)
	var t_right_back = Vector3(radius * cos(-arrow_angle), radius * sin(-arrow_angle), -half_z)

	# Arrow Front Face (+Z)
	st.set_uv(Vector2(0.0, 1.0))
	st.add_vertex(t_left_front)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(t_right_front)
	st.set_uv(Vector2(1.0, 0.5))
	st.add_vertex(tip_front)

	# Arrow Back Face (-Z)
	st.set_uv(Vector2(0.0, 1.0))
	st.add_vertex(t_left_back)
	st.set_uv(Vector2(1.0, 0.5))
	st.add_vertex(tip_back)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(t_right_back)

	# Arrow Upper Edge
	st.set_uv(Vector2(0.0, 1.0))
	st.add_vertex(t_left_front)
	st.set_uv(Vector2(1.0, 1.0))
	st.add_vertex(tip_front)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(t_left_back)

	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(t_left_back)
	st.set_uv(Vector2(1.0, 1.0))
	st.add_vertex(tip_front)
	st.set_uv(Vector2(1.0, 0.0))
	st.add_vertex(tip_back)

	# Arrow Lower Edge
	st.set_uv(Vector2(0.0, 1.0))
	st.add_vertex(t_right_front)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(t_right_back)
	st.set_uv(Vector2(1.0, 1.0))
	st.add_vertex(tip_front)

	st.set_uv(Vector2(1.0, 1.0))
	st.add_vertex(tip_front)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(t_right_back)
	st.set_uv(Vector2(1.0, 0.0))
	st.add_vertex(tip_back)

	st.generate_normals()
	st.generate_tangents()
	
	var mesh: ArrayMesh = st.commit()
	ResourceSaver.save(mesh, "res://knob.mesh")
