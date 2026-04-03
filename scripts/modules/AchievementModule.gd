class_name AchievementModule
extends GameModule

const ACHIEVEMENTS_PATH := "res://data/achievements.json"
const META_ID := "collector"

var _definitions: Array[Dictionary] = []
var _def_by_id: Dictionary = {}
var _unlocked: Dictionary = {}
var _counters: Dictionary = {}

func get_module_id() -> String:
	return "achievement"

func get_module_name() -> String:
	return "成就系统"

func on_new_game(init_data: Dictionary) -> void:
	_load_definitions()
	_unlocked.clear()
	_counters.clear()
	var roommate_draw_summary: Dictionary = init_data.get("roommate_draw_summary", {})
	if not roommate_draw_summary.is_empty():
		var draw_count: int = int(roommate_draw_summary.get("draw_count", 0))
		var ssr_draw_count: int = int(roommate_draw_summary.get("ssr_draw_count", 0))
		if draw_count > 0:
			_set_counter("roommate_draw_total", draw_count)
		if ssr_draw_count > 0:
			_set_counter("roommate_ssr_total", ssr_draw_count)

func on_day_start(day_index: int, _phase: String) -> void:
	_set_counter("days_survived", day_index + 1)
	_refresh_met_npc_counter()
	_check_all_non_meta()

func on_action_performed(action_id: String, _time_slot: String, _context: Dictionary) -> void:
	_add_counter("actions_total", 1)
	_add_counter("action_%s" % action_id, 1)
	if _is_social_action(action_id):
		_add_counter("social_actions", 1)
	_refresh_met_npc_counter()
	_check_all_non_meta()

func on_day_end(day_index: int, _phase: String) -> void:
	_set_counter("days_survived", day_index + 1)
	_check_all_non_meta()

func on_semester_end(_year: int, _semester: int) -> void:
	_add_counter("semesters_completed", 1)
	_check_all_non_meta()

func on_game_end(ending_type: String, game_state: Dictionary = {}) -> void:
	for def: Dictionary in _definitions:
		if def.get("type", "") == "ending" and def.get("ending", "") == ending_type:
			_unlock(def.get("id", ""))
	if not game_state.is_empty():
		var attrs: Dictionary = game_state.get("attributes", {})
		for key: String in ["living_money", "gpa", "social", "ability", "health", "mental"]:
			if attrs.has(key):
				# 结局页再做一次属性校验
				_check_attribute_defs_for(key, float(attrs[key]))
	_check_meta_collector()

func serialize() -> Dictionary:
	return {
		"unlocked": _unlocked.duplicate(true),
		"counters": _counters.duplicate(true)
	}

func get_overview() -> Dictionary:
	return {
		"definitions": _definitions.duplicate(true),
		"unlocked": _unlocked.duplicate(true),
		"counters": _counters.duplicate(true)
	}

func deserialize(data: Dictionary) -> void:
	_load_definitions()
	_unlocked = data.get("unlocked", {}).duplicate(true)
	_counters = data.get("counters", {}).duplicate(true)
	_check_meta_collector()

func _load_definitions() -> void:
	_definitions.clear()
	_def_by_id.clear()
	if not FileAccess.file_exists(ACHIEVEMENTS_PATH):
		push_warning("AchievementModule: 成就定义文件不存在")
		return
	var file: FileAccess = FileAccess.open(ACHIEVEMENTS_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var parsed: Variant = json.get_data()
	if parsed is Dictionary:
		var arr: Array = parsed.get("achievements", [])
		for item in arr:
			if item is Dictionary:
				var def: Dictionary = item
				var id: String = def.get("id", "")
				if id.is_empty():
					continue
				_definitions.append(def)
				_def_by_id[id] = def

func _add_counter(counter_name: String, value: int) -> void:
	var current: int = int(_counters.get(counter_name, 0))
	_counters[counter_name] = current + value
	_check_counter_defs_for(counter_name)

func _set_counter(counter_name: String, value: int) -> void:
	var current: int = int(_counters.get(counter_name, 0))
	if value > current:
		_counters[counter_name] = value
	_check_counter_defs_for(counter_name)

func add_counter(counter_name: String, value: int = 1) -> void:
	_add_counter(counter_name, value)

func set_counter(counter_name: String, value: int) -> void:
	_set_counter(counter_name, value)

func _refresh_met_npc_counter() -> void:
	if RelationshipManager and RelationshipManager.has_method("get_met_npcs"):
		var met: Array = RelationshipManager.get_met_npcs()
		_set_counter("met_npcs", met.size())


func _check_counter_defs_for(counter_name: String) -> void:
	for def: Dictionary in _definitions:
		if def.get("type", "") != "counter":
			continue
		if def.get("counter", "") != counter_name:
			continue
		var target: int = int(def.get("target", 0))
		if int(_counters.get(counter_name, 0)) >= target:
			_unlock(def.get("id", ""))
	_check_meta_collector()

func _check_attribute_defs_for(attribute: String, value: float) -> void:
	for def: Dictionary in _definitions:
		if def.get("type", "") != "attribute":
			continue
		if def.get("attribute", "") != attribute:
			continue
		var target: float = float(def.get("target", 0.0))
		var op: String = def.get("op", ">=")
		if op == ">=" and value >= target:
			_unlock(def.get("id", ""))
	_check_meta_collector()

func _check_all_non_meta() -> void:
	var state: Dictionary = _get_player_state()
	var attrs: Dictionary = state.get("attributes", {})
	for attr: String in ["living_money", "gpa", "social", "ability", "health", "mental"]:
		if attrs.has(attr):
			_check_attribute_defs_for(attr, float(attrs[attr]))

func _unlock(achievement_id: String) -> void:
	if achievement_id.is_empty() or _unlocked.get(achievement_id, false):
		return
	_unlocked[achievement_id] = true
	var def: Dictionary = _def_by_id.get(achievement_id, {})
	if def.is_empty():
		return
	if Notify and Notify.has_method("achievement"):
		Notify.achievement(def.get("name", achievement_id))
	_log("解锁成就: %s" % def.get("name", achievement_id))

func _check_meta_collector() -> void:
	if not _def_by_id.has(META_ID):
		return
	if _unlocked.get(META_ID, false):
		return
	for def: Dictionary in _definitions:
		var id: String = def.get("id", "")
		if id.is_empty() or id == META_ID:
			continue
		if not _unlocked.get(id, false):
			return
	_unlock(META_ID)

func _is_social_action(action_id: String) -> bool:
	if action_id.begins_with("hangout"):
		return true
	return action_id in ["chat_up", "dorm_chat", "club_activity"]
