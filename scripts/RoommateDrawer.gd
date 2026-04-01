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
			"max_redraw": 2
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
			"max_redraw": 2
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
		"max_redraw": 2
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

	for i: int in range(filtered.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var temp: Variant = filtered[i]
		filtered[i] = filtered[j]
		filtered[j] = temp

	var take_n: int = mini(maxi(count, 0), filtered.size())
	return filtered.slice(0, take_n)

static func get_roommate_by_id(id: String) -> Dictionary:
	var pool: Array = load_pool()
	for item: Variant in pool:
		if item is Dictionary:
			var info: Dictionary = item
			if str(info.get("id", "")) == id:
				return info.duplicate(true)
	return {}
