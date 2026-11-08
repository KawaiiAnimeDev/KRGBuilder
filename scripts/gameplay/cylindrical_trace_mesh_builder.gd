class_name CylindricalTraceMeshBuilder
extends RefCounted

static func create_cylindrical_trace_mesh(
	note: ChartNote,
	cylinder_center: Vector2,
	cylinder_radius: float,
	angle_min_rad: float,
	angle_max_rad: float,
	scroll_speed: float,
	ribbon_angle_width_rad: float = 0.35,
	height: float = 0.12,
	radial_offset: float = 0.01,
	subdivisions: int = 64,
	head_length: float = 0.4 # world-space length of the tapered head, NOT a percentage
) -> ArrayMesh:
	if note.type != ChartNote.NoteType.TRACE or subdivisions < 1:
		return null

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_angle := ribbon_angle_width_rad * 0.5
	var r_base := cylinder_radius + radial_offset
	var duration := note.end_time - note.time
	var total_length := duration * scroll_speed

	var rings_bl: Array[Vector3] = []
	var rings_br: Array[Vector3] = []
	var rings_pk: Array[Vector3] = []

	for i in range(subdivisions + 1):
		var progress := float(i) / float(subdivisions)
		var val := TraceMath.evaluate(note.start_value, note.end_value, progress, note.interpolation)
		var center_angle := lerpf(angle_min_rad, angle_max_rad, val)
		var z_local := -progress * total_length

		# Taper by actual world distance traveled, not by progress fraction
		var dist_from_head := -z_local # 0 at head, grows toward tail
		var head_taper := smoothstep(0.0, head_length, dist_from_head)
		var current_height := height * head_taper
		var current_half_angle := half_angle * head_taper

		var a_left := center_angle - current_half_angle
		var a_right := center_angle + current_half_angle

		var pos_bl := Vector3(cylinder_center.x + r_base * cos(a_left), cylinder_center.y + r_base * sin(a_left), z_local)
		var pos_br := Vector3(cylinder_center.x + r_base * cos(a_right), cylinder_center.y + r_base * sin(a_right), z_local)
		var r_peak := r_base + current_height
		var pos_pk := Vector3(cylinder_center.x + r_peak * cos(center_angle), cylinder_center.y + r_peak * sin(center_angle), z_local)

		rings_bl.append(pos_bl)
		rings_br.append(pos_br)
		rings_pk.append(pos_pk)

	var add_tri := func(a: Vector3, b: Vector3, c: Vector3, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
		var normal := (b - a).cross(c - a).normalized()
		st.set_normal(normal); st.set_uv(ua); st.add_vertex(a)
		st.set_normal(normal); st.set_uv(ub); st.add_vertex(b)
		st.set_normal(normal); st.set_uv(uc); st.add_vertex(c)

	for i in range(subdivisions):
		var p0 := float(i) / float(subdivisions)
		var p1 := float(i + 1) / float(subdivisions)

		var bl0 := rings_bl[i]; var br0 := rings_br[i]; var pk0 := rings_pk[i]
		var bl1 := rings_bl[i + 1]; var br1 := rings_br[i + 1]; var pk1 := rings_pk[i + 1]

		add_tri.call(bl0, pk0, pk1, Vector2(0.0, p0), Vector2(0.5, p0), Vector2(0.5, p1))
		add_tri.call(bl0, pk1, bl1, Vector2(0.0, p0), Vector2(0.5, p1), Vector2(0.0, p1))
		add_tri.call(pk0, br0, br1, Vector2(0.5, p0), Vector2(1.0, p0), Vector2(1.0, p1))
		add_tri.call(pk0, br1, pk1, Vector2(0.5, p0), Vector2(1.0, p1), Vector2(0.5, p1))
		add_tri.call(br0, bl0, bl1, Vector2(1.0, p0), Vector2(0.0, p0), Vector2(0.0, p1))
		add_tri.call(br0, bl1, br1, Vector2(1.0, p0), Vector2(0.0, p1), Vector2(1.0, p1))

	st.generate_tangents()
	return st.commit()
