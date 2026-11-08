class_name LaneConfig
extends Resource

var index: int
var start_x: float
var end_x: float

func contains(x: float) -> bool:
	return x >= start_x and x <= end_x
