class_name ChartNote
extends RefCounted

enum NoteType { TAP, POISON, PULSE, FLICK, HOLD, TRACE }
enum FlickDirection { UP, DOWN, LEFT, RIGHT }
enum InterpolationType { S, SI, SO, SISO, SOSI, BEZIER }

var group: int = 0
var type: NoteType
var time: float
var lane: int = -1

var flick_direction: FlickDirection = FlickDirection.UP

var duration: float = 0.0

var trace_id: int = 0
var end_time: float = 0.0
var start_value: float = 0.0
var end_value: float = 0.0
var interpolation: InterpolationType = InterpolationType.S
