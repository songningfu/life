extends Node
# ══════════════════════════════════════════════
#             存档管理器
# ══════════════════════════════════════════════

const SAVE_DIR = "user://saves/"
const MAX_SLOTS = 3
const SAVE_VERSION = "5.2"

func _ready():
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _get_save_path(slot: int) -> String:
	return SAVE_DIR + "save_%d.json" % slot

func _get_meta_path(slot: int) -> String:
	return SAVE_DIR + "meta_%d.json" % slot

func save_game(slot: int, game_data: Dictionary) -> bool:
	var save_data = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"game_data": game_data,
	}
	var payload_text: String = JSON.stringify(game_data)
	save_data["checksum"] = payload_text.sha256_text()
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
		"university_name": game_data.get("university_name", ""),
		"major_name": game_data.get("major_name", ""),
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
		push_error("存档解析失败: slot %d" % slot)
		return {}
	var data: Variant = json.data
	if not (data is Dictionary) or not data.has("game_data"):
		push_error("存档结构无效: slot %d" % slot)
		return {}

	var wrapped: Dictionary = data
	var game_data_variant: Variant = wrapped.get("game_data", {})
	if not (game_data_variant is Dictionary):
		push_error("存档game_data无效: slot %d" % slot)
		return {}

	var game_data: Dictionary = game_data_variant.duplicate(true)
	var stored_checksum: String = str(wrapped.get("checksum", ""))
	if not stored_checksum.is_empty():
		var current_checksum: String = JSON.stringify(game_data).sha256_text()
		if current_checksum != stored_checksum:
			push_error("存档校验失败(可能损坏): slot %d" % slot)
			return {}

	var version: String = str(wrapped.get("version", "0"))
	return _migrate_game_data(game_data, version)

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

func _migrate_game_data(game_data: Dictionary, version: String) -> Dictionary:
	# 旧版 money 字段迁移
	if game_data.has("money") and not game_data.has("living_money"):
		game_data["living_money"] = int(float(game_data.get("money", 0.0)) * 30.0 + 500.0)
		game_data["study_points"] = float(game_data.get("study_points", game_data.get("gpa", 65.0)))
		game_data["gpa"] = 0.0
		game_data["semester_records"] = []
		game_data["academic_warning_count"] = 0

	# 学期字段迁移
	if game_data.has("semester_credits") and not game_data.has("semester_records"):
		game_data["semester_records"] = game_data["semester_credits"]
	if game_data.has("consecutive_low_gpa_semesters") and not game_data.has("academic_warning_count"):
		game_data["academic_warning_count"] = game_data["consecutive_low_gpa_semesters"]

	# 统一写入当前版本号，便于后续链式迁移
	game_data["version"] = SAVE_VERSION
	if version != SAVE_VERSION:
		push_warning("存档已迁移: %s -> %s" % [version, SAVE_VERSION])
	return game_data

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

# ==================== 临时元数据存储（用于pending_game_init） ====================

var _temp_store: Dictionary = {}

## 设置临时数据（用于角色创建到游戏场景的过渡）
func store_temp(key: String, value: Variant) -> void:
	if value == null:
		_temp_store.erase(key)
	else:
		_temp_store[key] = value

## 获取临时数据
func get_temp(key: String, default: Variant = null) -> Variant:
	return _temp_store.get(key, default)

## 检查是否有指定临时数据
func has_temp(key: String) -> bool:
	return _temp_store.has(key)

func clear_temp(key: String) -> void:
	_temp_store.erase(key)

# ==================== 舍友数据缓存 ====================

var _roommates_cache: Array = []

## 设置舍友数据
func set_roommates(roommates: Array) -> void:
	_roommates_cache = roommates.duplicate(true)

## 获取全部舍友
func get_roommates() -> Array:
	return _roommates_cache.duplicate(true)

## 根据ID获取舍友
func get_roommate(id: String) -> Dictionary:
	for item: Variant in _roommates_cache:
		if item is Dictionary:
			var info: Dictionary = item
			if str(info.get("id", "")) == id:
				return info.duplicate(true)
	return {}
