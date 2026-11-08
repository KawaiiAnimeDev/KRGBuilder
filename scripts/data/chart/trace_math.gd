class_name TraceMath
extends RefCounted

static func evaluate(start_val: float, end_val: float, progress: float, interp: ChartNote.InterpolationType) -> float:
	var t := clampf(progress, 0.0, 1.0)
	var factor := 0.0
	
	match interp:
		ChartNote.InterpolationType.S:
			factor = t
		ChartNote.InterpolationType.SI:
			factor = 1.0 - cos(t * PI * 0.5)
		ChartNote.InterpolationType.SO:
			factor = sin(t * PI * 0.5)
		ChartNote.InterpolationType.SISO:
			factor = (1.0 - cos(t * PI)) * 0.5
		ChartNote.InterpolationType.SOSI:
			if t < 0.5:
				factor = sin(t * PI) * 0.5
			else:
				factor = 1.0 - cos((t - 0.5) * PI) * 0.5
		ChartNote.InterpolationType.BEZIER:
			factor = t * t * (3.0 - 2.0 * t)
			
	return lerpf(start_val, end_val, factor)
