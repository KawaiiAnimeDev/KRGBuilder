class_name TimingGroup
extends RefCounted

class BpmEvent:
	var time: float
	var bpm: float
	var beats_per_measure: int

class SpeedEvent:
	var time: float
	var speed: float

var id: int = 0
var bpm_events: Array[BpmEvent] = []
var speed_events: Array[SpeedEvent] = []
