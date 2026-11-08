class_name CylindricalKnobManager
extends Node

signal trace_tick_hit(note: ChartNote)
signal trace_tick_miss(note: ChartNote)

@export var input_manager: InputManager
@export var trace_tolerance: float = 0.25

var active_traces: Array[ChartNote] = []

func register_trace(note: ChartNote) -> void:
	if not active_traces.has(note):
		active_traces.append(note)

func process_traces(current_time: float) -> void:
	if input_manager == null:
		return

	var i: int = active_traces.size() - 1
	while i >= 0:
		var note: ChartNote = active_traces[i]
		if current_time >= note.time and current_time <= note.end_time:
			var duration: float = note.end_time - note.time
			var progress: float = (current_time - note.time) / duration if duration > 0.0 else 1.0
			var expected_val: float = TraceMath.evaluate(
				note.start_value,
				note.end_value,
				progress,
				note.interpolation
			)

			var knob: Node3D = input_manager.left_knob if note.trace_id == 0 else input_manager.right_knob
			if knob != null:
				var current_val: float = input_manager._knob_value(knob)
				var diff: float = abs(current_val - expected_val)

				if diff <= trace_tolerance:
					trace_tick_hit.emit(note)
				else:
					trace_tick_miss.emit(note)

		elif current_time > note.end_time:
			active_traces.remove_at(i)

		i -= 1
