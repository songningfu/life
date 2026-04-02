## EventRuntime.gd
## 职责：封装事件触发、事件展示与选项结算
extends RefCounted

func check_event_trigger(game: Node, action_id: String, _time_slot: String) -> void:
	var module_events: Array[Dictionary] = []
	if ModuleManager:
		module_events = ModuleManager.collect_event_injections(game.current_day, game.current_phase_name, action_id)
	for event: Dictionary in module_events:
		display_event(game, event)

	var action_data: Dictionary = game._get_action_data(action_id)
	var event_pool_id: String = action_data.get("event_pool", "")
	if not event_pool_id.is_empty():
		try_trigger_pool_event(game, event_pool_id)
	try_trigger_flavor_text(game, action_id)

func display_event(game: Node, event_data: Dictionary) -> void:
	var title: String = event_data.get("title", "")
	var text: String = event_data.get("text", "")
	var event_type: String = event_data.get("type", "micro")

	if event_type == "micro":
		if not text.is_empty():
			game._append_log("📌 %s：%s" % [title, text])
		var effects: Dictionary = event_data.get("effects", {})
		game._apply_effects(effects)
		game._refresh_ui()
		return

	var choices: Array = event_data.get("choices", [])
	if choices.is_empty():
		game._append_log("📌 %s：%s" % [title, text])
		var plain_effects: Dictionary = event_data.get("effects", {})
		game._apply_effects(plain_effects)
		game._refresh_ui()
		return

	if game._current_text:
		game._current_text.clear()
		game._current_text.append_text("[b]%s[/b]\n%s" % [title, text])

	game._clear_choices()
	game.waiting_for_choice = true
	if game._next_button:
		game._next_button.disabled = true

	for i: int in range(choices.size()):
		var choice: Dictionary = choices[i]
		var choice_text: String = choice.get("text", "选项%d" % (i + 1))
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 44)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = "  ▸ " + choice_text

		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.10, 0.13, 0.18, 0.92)
		normal_style.set_corner_radius_all(8)
		normal_style.content_margin_left = 10
		normal_style.content_margin_right = 10
		btn.add_theme_stylebox_override("normal", normal_style)
		var hover_style: StyleBoxFlat = normal_style.duplicate()
		hover_style.bg_color = Color(0.16, 0.22, 0.30, 1.0)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_color_override("font_color", Color(0.92, 0.95, 0.99))

		btn.pressed.connect(game._on_event_choice_selected.bind(choice))
		game._choices_container.add_child(btn)

	game.event_triggered.emit(event_data.get("id", ""))

func on_event_choice_selected(game: Node, choice: Dictionary) -> void:
	var choice_text: String = choice.get("text", "")
	game._append_log("→ 你选择了：%s" % choice_text)

	var effects: Dictionary = choice.get("effects", {})
	game._apply_effects(effects)

	if choice.has("unlocks_flag"):
		game.flags[choice["unlocks_flag"]] = true
	if choice.has("add_tags"):
		for tag in choice["add_tags"]:
			if tag not in game.tags:
				game.tags.append(tag)
	if choice.has("remove_tags"):
		for tag in choice["remove_tags"]:
			game.tags.erase(tag)

	var followup: String = choice.get("followup", "")
	if not followup.is_empty():
		game._append_log(followup)

	game._clear_choices()
	game.waiting_for_choice = false
	if game._next_button:
		game._next_button.disabled = false
	game._refresh_ui()

func try_trigger_pool_event(game: Node, pool_id: String) -> void:
	var pools: Dictionary = game._events_data_cache.get("event_pools", {})
	if not pools.has(pool_id):
		return
	var pool: Dictionary = pools[pool_id]
	var events_dict: Dictionary = game._events_data_cache.get("events", {})

	for tier: String in ["micro", "standard"]:
		var event_ids: Array = pool.get(tier, [])
		for event_id in event_ids:
			if not events_dict.has(event_id):
				continue
			if event_id in game.used_event_ids:
				var used_event_data: Dictionary = events_dict[event_id]
				if used_event_data.get("once", false) or used_event_data.get("once_per_phase", false):
					continue
			var event_data: Dictionary = events_dict[event_id]
			var probability: float = event_data.get("probability", 0.0)
			if randf() <= probability:
				display_event(game, event_data)
				if event_id not in game.used_event_ids:
					game.used_event_ids.append(event_id)
				return

func try_trigger_flavor_text(game: Node, action_id: String) -> void:
	var category_map: Dictionary = {
		"attend_class": "class", "self_study": "library", "library": "library",
		"exercise": "exercise", "rest": "rest", "part_time_job": "part_time_job",
		"dorm_chat": "dorm", "club_activity": "club",
		"hangout_eat": "social", "hangout_game": "social", "hangout_study": "social",
	}
	var category: String = category_map.get(action_id, "general")
	var micro_events: Dictionary = game._flavor_texts_cache.get("micro_events", {})
	var event_list: Array = micro_events.get(category, []).duplicate()
	if event_list.is_empty():
		event_list = micro_events.get("general", []).duplicate()
	if event_list.is_empty():
		return

	var phase_events: Dictionary = game._flavor_texts_cache.get("phase_specific", {})
	for phase_key: String in phase_events.keys():
		if phase_key in game.current_phase_name:
			event_list.append_array(phase_events[phase_key])

	for event: Dictionary in event_list:
		var prob: float = event.get("probability", 0.0)
		if randf() <= prob:
			var text: String = event.get("text", "")
			var effects: Dictionary = event.get("effects", {})
			if not text.is_empty():
				game._append_log("💭 " + text)
				game._apply_effects(effects)
				game._refresh_ui()
			return
