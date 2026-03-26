extends Control

enum Loc {
	DORMITORY,
	CLASSROOM,
	LIBRARY,
	CANTEEN,
	PLAYGROUND,
	GATE,
	LAKE,
	SHOP,
}

const MAP_SIZE := Vector2(400, 300)
const BORDER_COLOR := Color.BLACK
const FILL_COLOR := Color.WHITE
const PLAYER_OUTLINE := Color.BLACK
const PLAYER_FILL := Color.WHITE

var game_ref = null
var landmarks: Dictionary = {
	Loc.DORMITORY: {"pos": Vector2(64, 236), "shape": "rect", "label": "Dorm"},
	Loc.CLASSROOM: {"pos": Vector2(205, 82), "shape": "wide_rect", "label": "Class"},
	Loc.LIBRARY: {"pos": Vector2(330, 68), "shape": "triangle", "label": "Library"},
	Loc.CANTEEN: {"pos": Vector2(128, 142), "shape": "round_rect", "label": "Canteen"},
	Loc.PLAYGROUND: {"pos": Vector2(310, 196), "shape": "ellipse", "label": "Field"},
	Loc.GATE: {"pos": Vector2(48, 48), "shape": "gate", "label": "Gate"},
	Loc.LAKE: {"pos": Vector2(330, 258), "shape": "wave", "label": "Lake"},
	Loc.SHOP: {"pos": Vector2(130, 258), "shape": "small_rect", "label": "Shop"},
}
var roads: Array = [
	[Loc.GATE, Loc.CLASSROOM],
	[Loc.GATE, Loc.DORMITORY],
	[Loc.DORMITORY, Loc.CANTEEN],
	[Loc.DORMITORY, Loc.SHOP],
	[Loc.CANTEEN, Loc.CLASSROOM],
	[Loc.CLASSROOM, Loc.LIBRARY],
	[Loc.CLASSROOM, Loc.PLAYGROUND],
	[Loc.PLAYGROUND, Loc.LAKE],
	[Loc.CANTEEN, Loc.PLAYGROUND],
]

var current_loc: int = Loc.DORMITORY
var target_loc: int = Loc.DORMITORY
var player_pos: Vector2 = Vector2.ZERO
var player_name: String = "Me"
var visual_hour: float = 0.0


func _ready() -> void:
	custom_minimum_size = MAP_SIZE
	size = MAP_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_pos = landmarks[Loc.DORMITORY]["pos"]
	set_process(true)


func setup(ref) -> void:
	game_ref = ref
	if game_ref != null and game_ref.has_method("get_date_info"):
		player_name = str(game_ref.player_name)
		current_loc = resolve_current_location()
		target_loc = current_loc
		player_pos = landmarks[current_loc]["pos"]
	queue_redraw()


func _process(delta: float) -> void:
	if game_ref != null:
		player_name = str(game_ref.player_name)
		visual_hour = _compute_visual_hour()
		target_loc = resolve_current_location()
	else:
		visual_hour = 8.0

	var target_pos: Vector2 = landmarks[target_loc]["pos"]
	player_pos = player_pos.lerp(target_pos, clampf(delta * 4.0, 0.0, 1.0))
	if player_pos.distance_to(target_pos) < 1.0:
		player_pos = target_pos
		current_loc = target_loc

	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), FILL_COLOR, true)
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), BORDER_COLOR, false, 1.0)
	_draw_roads()
	_draw_landmarks()
	_draw_player()
	_draw_text(Vector2(16, 24), "Campus Map", 15, HORIZONTAL_ALIGNMENT_LEFT, 120)
	_draw_text(Vector2(MAP_SIZE.x - 16, 24), _format_time(visual_hour), 14, HORIZONTAL_ALIGNMENT_RIGHT, 80)


func _draw_roads() -> void:
	for road in roads:
		var from_pos: Vector2 = landmarks[road[0]]["pos"]
		var to_pos: Vector2 = landmarks[road[1]]["pos"]
		draw_line(from_pos, to_pos, BORDER_COLOR, 1.0)


func _draw_landmarks() -> void:
	for loc in landmarks.keys():
		var info: Dictionary = landmarks[loc]
		var center: Vector2 = info["pos"]
		match str(info["shape"]):
			"rect":
				_draw_box(center, Vector2(40, 40))
				_draw_text(center + Vector2(0, 5), str(info["label"]), 10, HORIZONTAL_ALIGNMENT_CENTER, 60)
			"wide_rect":
				_draw_box(center, Vector2(64, 34))
				_draw_text(center + Vector2(0, 4), str(info["label"]), 10, HORIZONTAL_ALIGNMENT_CENTER, 74)
			"triangle":
				_draw_triangle(center)
				_draw_text(center + Vector2(0, 38), str(info["label"]), 10, HORIZONTAL_ALIGNMENT_CENTER, 70)
			"round_rect":
				_draw_round_rect(center, Vector2(52, 30), 8)
				_draw_text(center + Vector2(0, 4), str(info["label"]), 10, HORIZONTAL_ALIGNMENT_CENTER, 62)
			"ellipse":
				_draw_ellipse(center, Vector2(28, 18))
				_draw_text(center + Vector2(0, 4), str(info["label"]), 10, HORIZONTAL_ALIGNMENT_CENTER, 60)
			"gate":
				_draw_gate(center)
				_draw_text(center + Vector2(0, 26), str(info["label"]), 10, HORIZONTAL_ALIGNMENT_CENTER, 48)
			"wave":
				_draw_wave(center)
				_draw_text(center + Vector2(24, -6), str(info["label"]), 10, HORIZONTAL_ALIGNMENT_LEFT, 60)
			"small_rect":
				_draw_box(center, Vector2(34, 24))
				_draw_text(center + Vector2(0, 3), str(info["label"]), 9, HORIZONTAL_ALIGNMENT_CENTER, 42)


func _draw_player() -> void:
	draw_circle(player_pos, 16.0, PLAYER_FILL)
	draw_arc(player_pos, 16.0, 0.0, TAU, 32, PLAYER_OUTLINE, 2.0)
	var display_name: String = player_name
	if display_name.length() > 2:
		display_name = display_name.substr(0, 2)
	_draw_text(player_pos + Vector2(0, 4), display_name, 12, HORIZONTAL_ALIGNMENT_CENTER, 34)
	_draw_text(player_pos + Vector2(0, -22), _activity_text(current_loc), 9, HORIZONTAL_ALIGNMENT_CENTER, 80, Color(0.35, 0.35, 0.35))


func _draw_box(center: Vector2, box_size: Vector2) -> void:
	var rect := Rect2(center - box_size * 0.5, box_size)
	draw_rect(rect, FILL_COLOR, true)
	draw_rect(rect, BORDER_COLOR, false, 2.0)


func _draw_round_rect(center: Vector2, box_size: Vector2, radius: int) -> void:
	var points := PackedVector2Array()
	var half := box_size * 0.5
	var corners := [
		{"c": center + Vector2(-half.x + radius, -half.y + radius), "start": PI, "end": PI * 1.5},
		{"c": center + Vector2(half.x - radius, -half.y + radius), "start": PI * 1.5, "end": TAU},
		{"c": center + Vector2(half.x - radius, half.y - radius), "start": 0.0, "end": PI * 0.5},
		{"c": center + Vector2(-half.x + radius, half.y - radius), "start": PI * 0.5, "end": PI},
	]
	for corner in corners:
		for i in range(7):
			var t := lerpf(corner["start"], corner["end"], float(i) / 6.0)
			points.append(corner["c"] + Vector2(cos(t), sin(t)) * radius)
	draw_colored_polygon(points, FILL_COLOR)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, BORDER_COLOR, 2.0)


func _draw_triangle(center: Vector2) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -22),
		center + Vector2(26, 18),
		center + Vector2(-26, 18),
	])
	draw_colored_polygon(points, FILL_COLOR)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, BORDER_COLOR, 2.0)


func _draw_ellipse(center: Vector2, radius: Vector2) -> void:
	var points := PackedVector2Array()
	for i in range(33):
		var angle := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, FILL_COLOR)
	draw_polyline(points, BORDER_COLOR, 2.0)


func _draw_gate(center: Vector2) -> void:
	draw_line(center + Vector2(-10, -12), center + Vector2(-10, 10), BORDER_COLOR, 2.0)
	draw_line(center + Vector2(10, -12), center + Vector2(10, 10), BORDER_COLOR, 2.0)
	draw_line(center + Vector2(-14, -12), center + Vector2(14, -12), BORDER_COLOR, 2.0)


func _draw_wave(center: Vector2) -> void:
	var points := PackedVector2Array()
	for i in range(19):
		var x := -22.0 + i * 2.5
		var y := sin(float(i) * 0.75) * 4.0
		points.append(center + Vector2(x, y))
	draw_polyline(points, BORDER_COLOR, 2.0)


func _draw_text(pos: Vector2, text: String, font_size: int, alignment: HorizontalAlignment, width: float, color: Color = BORDER_COLOR) -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	draw_string(font, pos, text, alignment, width, font_size, color)


func _compute_visual_hour() -> float:
	if game_ref == null:
		return visual_hour
	var day_progress := 0.0
	if game_ref.day_interval > 0.0:
		day_progress = clampf(float(game_ref.day_timer) / float(game_ref.day_interval), 0.0, 1.0)
	return day_progress * 24.0


func resolve_current_location() -> int:
	if game_ref == null or not game_ref.has_method("get_date_info"):
		return Loc.DORMITORY

	var info: Dictionary = game_ref.get_date_info()
	var hour: int = int(floor(visual_hour))
	var has_relationship: bool = "in_relationship" in game_ref.tags
	var weekend_options: Array[int] = [Loc.LIBRARY, Loc.PLAYGROUND, Loc.SHOP]
	var weekend_pick: int = weekend_options[int(game_ref.day_index) % weekend_options.size()]

	if info.get("is_holiday", false):
		return Loc.GATE
	if info.get("is_military", false):
		if hour <= 6:
			return Loc.DORMITORY
		if hour == 7 or hour == 18:
			return Loc.CANTEEN
		if hour <= 17:
			return Loc.PLAYGROUND
		return Loc.DORMITORY
	if info.get("is_exam", false) or info.get("is_review", false):
		if hour <= 6:
			return Loc.DORMITORY
		if hour == 7 or hour == 12 or hour == 13:
			return Loc.CANTEEN
		if hour <= 22:
			return Loc.LIBRARY
		return Loc.DORMITORY
	if info.get("is_weekend", false):
		if hour <= 8:
			return Loc.DORMITORY
		if hour <= 10:
			return Loc.CANTEEN
		if hour <= 16:
			return Loc.LAKE if has_relationship else weekend_pick
		if hour <= 18:
			return Loc.CANTEEN
		return Loc.DORMITORY
	if hour <= 6:
		return Loc.DORMITORY
	if hour == 7 or hour == 12 or hour == 13 or hour == 18:
		return Loc.CANTEEN
	if hour <= 16:
		return Loc.CLASSROOM
	if hour == 17:
		return Loc.PLAYGROUND
	if hour <= 21:
		return Loc.LIBRARY if float(game_ref.study_points) >= 60.0 else Loc.DORMITORY
	return Loc.DORMITORY


func _activity_text(loc: int) -> String:
	match loc:
		Loc.CLASSROOM:
			return "class"
		Loc.LIBRARY:
			return "study"
		Loc.CANTEEN:
			return "eat"
		Loc.PLAYGROUND:
			return "run"
		Loc.GATE:
			return "away"
		Loc.LAKE:
			return "walk"
		Loc.SHOP:
			return "shop"
		_:
			return "rest"


func _format_time(hour_value: float) -> String:
	var total_minutes := int(round(clampf(hour_value, 0.0, 23.99) * 60.0))
	var hour := total_minutes / 60
	var minute := total_minutes % 60
	return "%02d:%02d" % [hour, minute]
