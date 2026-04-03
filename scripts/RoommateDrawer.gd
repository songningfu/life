# res://scripts/RoommateDrawer.gd
extends RefCounted
class_name RoommateDrawer

static var _cache_loaded: bool = false
static var _roommate_pool_cache: Array = []
static var _draw_config_cache: Dictionary = {}

static func load_pool() -> Array:
	if _cache_loaded:
		return _roommate_pool_cache.duplicate(true)

	var file: FileAccess = FileAccess.open("res://data/roommates.json", FileAccess.READ)
	if file == null:
		push_error("[RoommateDrawer] 无法打开 roommates.json")
		_cache_loaded = true
		_roommate_pool_cache = []
		_draw_config_cache = {
			"roommate_count": 3,
			"allow_redraw": true,
			"max_redraw": 2,
			"ssr_rarity": "ssr",
			"late_draw_threshold": 20,
		}
		return []

	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var err: int = json.parse(json_text)
	if err != OK:
		push_error("[RoommateDrawer] roommates.json 解析失败")
		_cache_loaded = true
		_roommate_pool_cache = []
		_draw_config_cache = {
			"roommate_count": 3,
			"allow_redraw": true,
			"max_redraw": 2,
			"ssr_rarity": "ssr",
			"late_draw_threshold": 20,
		}
		return []

	var root: Variant = json.data
	if root is Dictionary:
		var root_dict: Dictionary = root
		var pool_var: Variant = root_dict.get("roommate_pool", [])
		var cfg_var: Variant = root_dict.get("draw_config", {})

		_roommate_pool_cache = pool_var if pool_var is Array else []
		_draw_config_cache = cfg_var if cfg_var is Dictionary else {}
	else:
		_roommate_pool_cache = []
		_draw_config_cache = {}

	_cache_loaded = true
	return _roommate_pool_cache.duplicate(true)

static func get_draw_config() -> Dictionary:
	if not _cache_loaded:
		load_pool()

	var config: Dictionary = {
		"roommate_count": 3,
		"allow_redraw": true,
		"max_redraw": 2,
		"ssr_rarity": "ssr",
		"late_draw_threshold": 20,
		"late_draw_tip": "抽到这里你该懂了，真正难得的不是极品，是一直陪着你过日子的人。",
		"ssr_tip": "这次真让你欧到了。可再稀有的人，也要能陪你把日子过下去。"
	}
	for key: Variant in _draw_config_cache.keys():
		config[key] = _draw_config_cache[key]
	return config

static func draw_roommates(count: int, exclude_ids: Array) -> Array:
	var pool: Array = load_pool()
	var filtered: Array = []

	for item: Variant in pool:
		if item is Dictionary:
			var info: Dictionary = item
			var rid: String = str(info.get("id", ""))
			if rid.is_empty():
				continue
			if exclude_ids.has(rid):
				continue
			filtered.append(info.duplicate(true))

	var take_n: int = mini(maxi(count, 0), filtered.size())
	var result: Array = []
	while result.size() < take_n and not filtered.is_empty():
		var pick_index := _pick_weighted_index(filtered)
		if pick_index < 0 or pick_index >= filtered.size():
			break
		result.append(filtered[pick_index])
		filtered.remove_at(pick_index)
	return result

static func has_ssr(roommates: Array) -> bool:
	var config := get_draw_config()
	var ssr_rarity := str(config.get("ssr_rarity", "ssr")).to_lower()
	for item: Variant in roommates:
		if item is Dictionary and str(item.get("rarity", "r")).to_lower() == ssr_rarity:
			return true
	return false

static func get_roommate_by_id(id: String) -> Dictionary:
	var pool: Array = load_pool()
	for item: Variant in pool:
		if item is Dictionary:
			var info: Dictionary = item
			if str(info.get("id", "")) == id:
				return info.duplicate(true)
	return {}

static func _pick_weighted_index(candidates: Array) -> int:
	var total_weight := 0
	for item: Variant in candidates:
		if item is Dictionary:
			total_weight += maxi(int(item.get("weight", 1)), 1)
	if total_weight <= 0:
		return 0

	var roll := randi_range(1, total_weight)
	var cursor := 0
	for i in range(candidates.size()):
		var item: Variant = candidates[i]
		if not (item is Dictionary):
			continue
		cursor += maxi(int(item.get("weight", 1)), 1)
		if roll <= cursor:
			return i
	return max(candidates.size() - 1, 0)
