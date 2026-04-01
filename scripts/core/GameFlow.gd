## GameFlow.gd
## 职责：封装 Game 的时间与阶段推进流程（phase/day 流转）
extends RefCounted

func advance_phase(game: Node) -> void:
	if game._phase_advancing:
		return
	if game.waiting_for_choice:
		game._append_log("请先完成当前行动选择")
		return

	game._phase_advancing = true
	match game.current_phase_enum:
		game.DayPhase.MORNING_INFO:
			process_morning_info(game)
			advance_to_phase(game, game.DayPhase.SLOT_MORNING)
		
		game.DayPhase.SLOT_MORNING:
			process_time_slot(game, "morning")
			if not game.waiting_for_choice:
				advance_to_phase(game, game.DayPhase.SLOT_AFTERNOON)
		
		game.DayPhase.SLOT_AFTERNOON:
			process_time_slot(game, "afternoon")
			if not game.waiting_for_choice:
				advance_to_phase(game, game.DayPhase.SLOT_EVENING)
		
		game.DayPhase.SLOT_EVENING:
			process_time_slot(game, "evening")
			if not game.waiting_for_choice:
				advance_to_phase(game, game.DayPhase.NIGHT_SUMMARY)
		
		game.DayPhase.NIGHT_SUMMARY:
			game._process_night_summary()
			advance_to_next_day(game)
			advance_to_phase(game, game.DayPhase.MORNING_INFO)
	game._phase_advancing = false

func advance_to_phase(game: Node, phase: int) -> void:
	game.current_phase_enum = phase
	game.phase_changed.emit(phase)
	game._log("进入阶段: %s" % game._get_phase_name(phase))
	game._refresh_ui()

func advance_to_next_day(game: Node) -> void:
	if game._scene_transitions and game._scene_transitions.has_method("day_transition"):
		game._scene_transitions.day_transition()
	game.current_day += 1

	game.current_year = (game.current_day / 365) + 1
	var day_in_year: int = game.current_day % 365
	if day_in_year < 177:
		game.current_semester = 1
	else:
		game.current_semester = 2

	game._update_phase_name()
	game.daily_actions = {"morning": "", "afternoon": "", "evening": ""}
	game._selected_actions = {"morning": "", "afternoon": "", "evening": ""}

	if game.current_day >= game.TOTAL_DAYS:
		game._trigger_game_end()
		return

	game._auto_save_if_needed()
	game._refresh_ui()
	game.day_advanced.emit(game.current_day)

func process_morning_info(game: Node) -> void:
	game._log("处理晨间信息 - 第%d天" % game.current_day)

	if game.ModuleManager:
		game.ModuleManager.set_player_state(game._get_player_state())
		game.ModuleManager.broadcast_day_start(game.current_day, game.current_phase_name)

	var morning_infos: Array[Dictionary] = []
	if game.ModuleManager:
		morning_infos = game.ModuleManager.collect_morning_info(game.current_day)

	var base_info: Array[Dictionary] = get_base_morning_info(game)
	morning_infos.append_array(base_info)

	morning_infos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("priority", 0) > b.get("priority", 0)
	)

	if game._current_text:
		game._current_text.clear()
		game._current_text.append_text("[b]晨间信息[/b]\n")
		for info: Dictionary in morning_infos:
			game._current_text.append_text("%s %s\n" % [info.get("icon", "•"), info.get("text", "")])

	game._append_log("晨间信息已更新（%d条）" % morning_infos.size())

func get_base_morning_info(game: Node) -> Array[Dictionary]:
	var infos: Array[Dictionary] = []
	infos.append({
		"icon": "📅",
		"text": "第%d天 · %s · 大%d" % [game.current_day + 1, game.current_phase_name, game.current_year],
		"priority": 10
	})

	if game.current_day % 30 == 0:
		infos.append({
			"icon": "💰",
			"text": "生活费到账 +¥1500",
			"priority": 9
		})
		game.attributes["living_money"] += 1500
		if game._notify and game._notify.has_method("money_change"):
			game._notify.money_change(1500)

	if game.attributes["health"] < 30:
		infos.append({"icon": "🏥", "text": "你的健康状况不佳，注意休息", "priority": 8})
	if game.attributes["mental"] < 30:
		infos.append({"icon": "💭", "text": "你感觉压力很大，找人聊聊吧", "priority": 8})
	return infos

func process_time_slot(game: Node, time_slot: String) -> void:
	game._log("处理%s时段" % time_slot)
	var is_important: bool = game._is_important_day()
	game.waiting_for_choice = false
	if is_important:
		game.waiting_for_choice = true
		game._show_action_menu(time_slot)
	else:
		game._auto_execute_action(time_slot)
