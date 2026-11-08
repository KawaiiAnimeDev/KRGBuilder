class_name ChartParser
extends RefCounted

static func parse_file(file_path: String) -> ChartData:
	if not FileAccess.file_exists(file_path):
		printerr("Chart file not found: ", file_path)
		return null
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	
	return parse_json(content)

static func parse_json(json_string: String) -> ChartData:
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		printerr("JSON parse error: ", json.get_error_message())
		return null
	
	var data: Dictionary = json.data
	var chart := ChartData.new()
	
	var raw_groups: Array = data.get("timing_groups", [])
	for group_dict in raw_groups:
		var tg := _parse_timing_group(group_dict)
		chart.timing_groups[tg.id] = tg
		
	if not chart.timing_groups.has(0):
		var default_group := TimingGroup.new()
		default_group.id = 0
		chart.timing_groups[0] = default_group
	
	var raw_notes: Array = data.get("notes", [])
	for item in raw_notes:
		var note := _parse_note(item)
		if note != null:
			chart.notes.append(note)
			
	chart.notes.sort_custom(func(a: ChartNote, b: ChartNote) -> bool:
		return a.time < b.time
	)
	
	return chart

static func _parse_timing_group(dict: Dictionary) -> TimingGroup:
	var tg := TimingGroup.new()
	tg.id = dict.get("id", 0)
	
	var raw_bpms: Array = dict.get("bpm_events", [])
	for b in raw_bpms:
		var bpm_event := TimingGroup.BpmEvent.new()
		bpm_event.time = b.get("time", 0.0) / 1000.0
		bpm_event.bpm = b.get("bpm", 120.0)
		bpm_event.beats_per_measure = b.get("beats_per_measure", 4)
		tg.bpm_events.append(bpm_event)
		
	tg.bpm_events.sort_custom(func(a: TimingGroup.BpmEvent, b: TimingGroup.BpmEvent) -> bool:
		return a.time < b.time
	)
	
	var raw_speeds: Array = dict.get("speed_events", [])
	for s in raw_speeds:
		var speed_event := TimingGroup.SpeedEvent.new()
		speed_event.time = s.get("time", 0.0) / 1000.0
		speed_event.speed = s.get("speed", 1.0)
		tg.speed_events.append(speed_event)
		
	tg.speed_events.sort_custom(func(a: TimingGroup.SpeedEvent, b: TimingGroup.SpeedEvent) -> bool:
		return a.time < b.time
	)
	
	return tg

static func _parse_note(dict: Dictionary) -> ChartNote:
	var note := ChartNote.new()
	note.group = dict.get("group", 0)
	var type_str: String = dict.get("type", "tap")
	
	match type_str:
		"tap":
			note.type = ChartNote.NoteType.TAP
			note.time = dict.get("time", 0.0) / 1000.0
			note.lane = dict.get("lane", 0)
		
		"poison":
			note.type = ChartNote.NoteType.POISON
			note.time = dict.get("time", 0.0) / 1000.0
			note.lane = dict.get("lane", 0)
			
		"pulse":
			note.type = ChartNote.NoteType.PULSE
			note.time = dict.get("time", 0.0) / 1000.0
			
		"flick":
			note.type = ChartNote.NoteType.FLICK
			note.time = dict.get("time", 0.0) / 1000.0
			note.lane = dict.get("lane", 0)
			note.flick_direction = _parse_flick_dir(dict.get("direction", "up"))
			
		"hold":
			note.type = ChartNote.NoteType.HOLD
			note.time = dict.get("time", 0.0) / 1000.0
			note.duration = dict.get("duration", 0.0) / 1000.0
			note.lane = dict.get("lane", 0)
			
		"trace":
			note.type = ChartNote.NoteType.TRACE
			note.trace_id = dict.get("id", 0)
			note.time = dict.get("startTime", 0.0) / 1000.0
			note.end_time = dict.get("endTime", 0.0) / 1000.0
			note.start_value = dict.get("startValue", 0.0)
			note.end_value = dict.get("endValue", 0.0)
			note.interpolation = _parse_interp(dict.get("interpolation", "s"))
			
		_:
			return null
			
	return note

static func _parse_flick_dir(dir_str: String) -> ChartNote.FlickDirection:
	match dir_str.to_lower():
		"down": return ChartNote.FlickDirection.DOWN
		"left": return ChartNote.FlickDirection.LEFT
		"right": return ChartNote.FlickDirection.RIGHT
		_: return ChartNote.FlickDirection.UP

static func _parse_interp(interp_str: String) -> ChartNote.InterpolationType:
	match interp_str.to_lower():
		"si": return ChartNote.InterpolationType.SI
		"so": return ChartNote.InterpolationType.SO
		"siso": return ChartNote.InterpolationType.SISO
		"sosi": return ChartNote.InterpolationType.SOSI
		"b": return ChartNote.InterpolationType.BEZIER
		_: return ChartNote.InterpolationType.S
