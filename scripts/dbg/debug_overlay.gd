class_name DebugOverlay
extends CanvasLayer

var max_points: int = 120
var fps_history: Array[float] = []
var frame_time_history: Array[float] = []

var master_bus_idx: int = 0
var analyzer: AudioEffectSpectrumAnalyzerInstance

var panel: Control

func _ready() -> void:
	layer = 128
	master_bus_idx = AudioServer.get_bus_index("Master")
	
	for i in AudioServer.get_bus_effect_count(master_bus_idx):
		if AudioServer.get_bus_effect(master_bus_idx, i) is AudioEffectSpectrumAnalyzer:
			analyzer = AudioServer.get_bus_effect_instance(master_bus_idx, i)
			break
			
	if not analyzer:
		var effect = AudioEffectSpectrumAnalyzer.new()
		AudioServer.add_bus_effect(master_bus_idx, effect)
		analyzer = AudioServer.get_bus_effect_instance(master_bus_idx, AudioServer.get_bus_effect_count(master_bus_idx) - 1)
		
	panel = Control.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(10, 10)
	panel.custom_minimum_size = Vector2(300, 260)
	panel.draw.connect(_on_panel_draw)
	add_child(panel)

func _process(delta: float) -> void:
	var fps = Engine.get_frames_per_second()
	var frame_time = delta * 1000.0
	
	fps_history.append(fps)
	frame_time_history.append(frame_time)
	
	if fps_history.size() > max_points:
		fps_history.pop_front()
		frame_time_history.pop_front()
		
	panel.queue_redraw()

func _on_panel_draw() -> void:
	var rect = Rect2(Vector2.ZERO, panel.custom_minimum_size)
	panel.draw_rect(rect, Color(0, 0, 0, 0.75))
	
	var fps = Engine.get_frames_per_second()
	var frame_time = get_process_delta_time() * 1000.0
	var latency = AudioServer.get_output_latency() * 1000.0
	var peak_l = AudioServer.get_bus_peak_volume_left_db(master_bus_idx, 0)
	var peak_r = AudioServer.get_bus_peak_volume_right_db(master_bus_idx, 0)
	
	var text = "FPS: %d\nFrame Time: %.2f ms\nAudio Latency: %.2f ms\nPeak dB: L %.1f | R %.1f" % [fps, frame_time, latency, peak_l, peak_r]
	panel.draw_multiline_string(ThemeDB.fallback_font, Vector2(10, 20), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, -1, Color.WHITE)
	
	
	_draw_graph(Rect2(10, 100, 280, 50), frame_time_history, Color(0.2, 0.8, 0.2), 33.3)
	_draw_spectrum(Rect2(10, 170, 280, 80))

func _draw_graph(rect: Rect2, data: Array[float], color: Color, max_val: float) -> void:
	panel.draw_rect(rect, Color(0.1, 0.1, 0.1, 0.5))
	if data.size() < 2:
		return
		
	var points = PackedVector2Array()
	var step = rect.size.x / float(max_points - 1)
	
	for i in data.size():
		var val = clampf(data[i], 0.0, max_val)
		var norm = val / max_val
		var x = rect.position.x + (i * step)
		var y = rect.position.y + rect.size.y - (norm * rect.size.y)
		points.append(Vector2(x, y))
		
	panel.draw_polyline(points, color, 1.0)

func _draw_spectrum(rect: Rect2) -> void:
	panel.draw_rect(rect, Color(0.1, 0.1, 0.1, 0.5))
	if not analyzer:
		return
		
	var bands = 16
	var w = rect.size.x / bands
	var prev_hz = 20.0
	
	for i in range(1, bands + 1):
		var hz = 20.0 * pow(1000.0, float(i) / bands)
		var mag = analyzer.get_magnitude_for_frequency_range(prev_hz, hz).length()
		var db = linear_to_db(mag)
		var height_norm = clampf((db + 60.0) / 60.0, 0.0, 1.0)
		
		var h = height_norm * rect.size.y
		var bar_rect = Rect2(rect.position.x + (i - 1) * w + 1, rect.position.y + rect.size.y - h, w - 2, h)
		panel.draw_rect(bar_rect, Color(0.2, 0.6, 1.0))
		prev_hz = hz
