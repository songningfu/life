## ActionExecutor.gd
## 职责：封装行动执行、效果计算与属性结算
extends RefCounted

func execute_action(game: Node, action_id: String, time_slot: String) -> void:
	game._log("执行行动: %s (%s)" % [action_id, time_slot])
	game.waiting_for_choice = false
	game.daily_actions[time_slot] = action_id

	var action_data: Dictionary = game._get_action_data(action_id)
	var action_cost: int = int(action_data.get("cost", 0))
	if action_cost > 0:
		game.attributes["living_money"] -= action_cost
		if game._notify and game._notify.has_method("money_change"):
			game._notify.money_change(-action_cost)

	var base_effects: Dictionary = calculate_action_effects(game, action_data)
	if action_cost > 0 and base_effects.has("living_money"):
		base_effects.erase("living_money")

	var final_effects: Dictionary = game._apply_modifiers(base_effects)
	apply_effects(game, final_effects)

	var context: Dictionary = {
		"action_id": action_id,
		"time_slot": time_slot,
		"effects": final_effects,
		"action_data": action_data
	}
	if game.ModuleManager:
		game.ModuleManager.broadcast_action_performed(action_id, time_slot, context)

	game._check_event_trigger(action_id, time_slot)

	game.action_history.append({
		"day": game.current_day,
		"time_slot": time_slot,
		"action": action_id,
		"effects": final_effects
	})

	var action_name: String = action_data.get("name", action_id)
	game._append_log("[%s] 执行：%s" % [time_slot, action_name])
	game._refresh_ui()
	if not game.waiting_for_choice:
		game.action_selected.emit(action_id, time_slot)

func calculate_action_effects(_game: Node, action_data: Dictionary) -> Dictionary:
	var effects: Dictionary = {}
	var action_effects: Dictionary = action_data.get("effects", {})
	for attr: String in action_effects.keys():
		var effect_data: Variant = action_effects[attr]
		if effect_data is Dictionary:
			var min_val: int = int(effect_data.get("min", 0))
			var max_val: int = int(effect_data.get("max", 0))
			if max_val < min_val:
				var tmp: int = min_val
				min_val = max_val
				max_val = tmp
			if min_val == max_val:
				effects[attr] = min_val
			else:
				effects[attr] = randi() % (max_val - min_val + 1) + min_val
		elif effect_data is int or effect_data is float:
			effects[attr] = effect_data
	return effects

func apply_effects(game: Node, effects: Dictionary) -> void:
	var attr_names: Dictionary = {
		"study_points": "学习",
		"social": "社交",
		"ability": "能力",
		"mental": "心理",
		"health": "健康",
		"living_money": "生活费",
		"gpa": "绩点"
	}
	for attr: String in effects.keys():
		if not game.attributes.has(attr):
			continue
		var old_value: float = float(game.attributes[attr])
		game.attributes[attr] += effects[attr]
		game.attributes[attr] = clamp(game.attributes[attr], 0, 100) if attr != "living_money" and attr != "gpa" else game.attributes[attr]
		var new_value: float = float(game.attributes[attr])
		var delta: float = new_value - old_value
		if is_zero_approx(delta):
			continue
		if attr == "living_money":
			if game._notify and game._notify.has_method("money_change"):
				game._notify.money_change(int(round(delta)))
		else:
			if game._notify and game._notify.has_method("stat_change"):
				game._notify.stat_change(attr_names.get(attr, attr), delta)
