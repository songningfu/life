extends Node
# ══════════════════════════════════════════════
#             存档管理器
# ══════════════════════════════════════════════

const SAVE_DIR = "user://saves/"
const MAX_SLOTS = 3

func _ready():
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _get_save_path(slot: int) -> String:
	return SAVE_DIR + "save_%d.json" % slot

func _get_meta_path(slot: int) -> String:
	return SAVE_DIR + "meta_%d.json" % slot

func save_game(slot: int, game_data: Dictionary) -> bool:
	var save_data = {
		"version": "5.1",
		"timestamp": Time.get_datetime_string_from_system(),
		"game_data": game_data,
	}
	var json_str = JSON.stringify(save_data, "  ")
	var file = FileAccess.open(_get_save_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("无法写入存档 slot %d" % slot)
		return false
	file.store_string(json_str)
	file.close()

	var info = get_date_info_from_data(game_data)
	var meta = {
		"timestamp": save_data.timestamp,
		"player_name": game_data.get("player_name", "未知"),
		"day_index": game_data.get("day_index", 0),
		"university_tier": game_data.get("university_tier", ""),
		"year": info.year,
		"phase": info.phase,
		"gpa": game_data.get("gpa", 0.0),
		"study_points": game_data.get("study_points", 0.0),
		"living_money": game_data.get("living_money", 0),
	}
	var meta_file = FileAccess.open(_get_meta_path(slot), FileAccess.WRITE)
	if meta_file:
		meta_file.store_string(JSON.stringify(meta, "  "))
		meta_file.close()
	return true

func load_game(slot: int) -> Dictionary:
	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json_str = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_str) != OK:
		return {}
	var data = json.data
	if data is Dictionary and data.has("game_data"):
		var game_data = data["game_data"]
		if game_data is Dictionary:
			if game_data.has("money") and not game_data.has("living_money"):
				game_data["living_money"] = int(float(game_data.get("money", 0.0)) * 30.0 + 500.0)
				game_data["study_points"] = float(game_data.get("study_points", game_data.get("gpa", 65.0)))
				game_data["gpa"] = 0.0
				game_data["semester_records"] = []
				game_data["academic_warning_count"] = 0
			if game_data.has("semester_credits") and not game_data.has("semester_records"):
				game_data["semester_records"] = game_data["semester_credits"]
			if game_data.has("consecutive_low_gpa_semesters") and not game_data.has("academic_warning_count"):
				game_data["academic_warning_count"] = game_data["consecutive_low_gpa_semesters"]
			return game_data
	return {}

func delete_save(slot: int) -> bool:
	var path = _get_save_path(slot)
	var meta_path = _get_meta_path(slot)
	var deleted = false
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		deleted = true
	if FileAccess.file_exists(meta_path):
		DirAccess.remove_absolute(meta_path)
	return deleted

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_get_save_path(slot))

func get_save_meta(slot: int) -> Dictionary:
	var path = _get_meta_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json_str = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_str) != OK:
		return {}
	return json.data if json.data is Dictionary else {}

func get_all_slots_info() -> Array:
	var result = []
	for i in range(MAX_SLOTS):
		result.append({
			"slot": i,
			"exists": has_save(i),
			"meta": get_save_meta(i),
		})
	return result

# 从存档数据中算出年份和阶段（不依赖Game节点）
func get_date_info_from_data(data: Dictionary) -> Dictionary:
	var di = int(data.get("day_index", 0))
	var year = di / 365 + 1
	var day_in_year = di % 365
	var calendar = [
		[0,6,"开学季"], [7,13,"军训"], [14,90,"上学期日常"],
		[91,105,"上学期复习周"], [106,120,"上学期考试周"],
		[121,136,"寒假前"], [137,176,"寒假"], [177,183,"新学期开学"],
		[184,280,"下学期日常"], [281,295,"下学期复习周"],
		[296,310,"下学期考试周"], [311,364,"暑假"],
	]
	var phase = "暑假"
	for entry in calendar:
		if day_in_year >= entry[0] and day_in_year <= entry[1]:
			phase = entry[2]
			break
	return {"year": year, "phase": phase}
