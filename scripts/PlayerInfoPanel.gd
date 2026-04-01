extends CanvasLayer

const BACKGROUNDS = {
	"normal": {"name": "普通家庭"},
	"business": {"name": "经商家庭"},
	"teacher": {"name": "教师家庭"},
	"rural": {"name": "农村家庭"},
	"single_parent": {"name": "单亲家庭"},
}

const STORY_TITLE_MAP := {
	"y1s1_roommate": "初到宿舍",
	"y1s1_club_fair": "社团招新",
	"y1s1_first_class": "开学第一课",
	"y1s1_homesick": "想家时刻",
	"y1s1_debate": "辩论启程",
	"y1s1_tech_project": "技术项目",
	"y1s1_union_work": "学生会工作",
	"y1s1_final": "大一上结束",
	"y1s1_winter": "寒假安排",
	"y1s2_love": "心动开始",
	"y1s2_love_develop": "关系升温",
	"y1s2_competition": "比赛挑战",
	"y1s2_final": "大一下结束",
	"y1s2_summer": "暑假选择",
	"y2_major_doubt": "专业迷茫",
	"y2_relationship_trouble": "感情波动",
	"y3_future": "未来方向",
	"y3_internship": "实习机会",
	"y3_postgrad_pressure": "升学压力",
	"y3_startup": "创业尝试",
	"y4_postgrad_result": "升学结果",
	"y4_autumn": "秋招季",
	"y4_thesis": "毕业论文",
	"y4_last_night": "毕业前夜",
}

var game_node: Node = null
var was_time_running_before_open := false

@onready var overlay_rect: ColorRect = $Overlay
@onready var panel_host: MarginContainer = $MarginContainer
@onready var shell_panel: PanelContainer = $MarginContainer/Shell
@onready var header_panel: PanelContainer = $MarginContainer/Shell/MainVBox/HeaderPanel
@onready var close_btn: Button = $MarginContainer/Shell/MainVBox/HeaderPanel/HeaderMargin/HeaderRow/Actions/CloseBtn
@onready var header_eyebrow: Label = $MarginContainer/Shell/MainVBox/HeaderPanel/HeaderMargin/HeaderRow/IdentityBlock/HeaderEyebrow
@onready var header_title: Label = $MarginContainer/Shell/MainVBox/HeaderPanel/HeaderMargin/HeaderRow/IdentityBlock/HeaderTitle
@onready var header_sub: Label = $MarginContainer/Shell/MainVBox/HeaderPanel/HeaderMargin/HeaderRow/IdentityBlock/HeaderSub
@onready var scroll: ScrollContainer = $MarginContainer/Shell/MainVBox/ScrollContainer
@onready var quick_stats_grid: GridContainer = $MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/QuickStatsPanel/QuickStatsMargin/QuickStatsVBox/QuickStatsGrid
@onready var info_grid: GridContainer = $MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/LeftColumn/BasicInfoPanel/SectionMargin/SectionVBox/InfoGrid
@onready var progress_content: VBoxContainer = $MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/LeftColumn/ProgressPanel/SectionMargin/SectionVBox/ProgressContent
@onready var talents_flow: FlowContainer = $MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/LeftColumn/TalentsPanel/SectionMargin/SectionVBox/TalentsFlow
@onready var tags_flow: FlowContainer = $MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/LeftColumn/TagsPanel/SectionMargin/SectionVBox/TagsFlow
@onready var story_content: VBoxContainer = $MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/RightColumn/StoryPanel/SectionMargin/SectionVBox/StoryContent
@onready var academic_content: VBoxContainer = $MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/RightColumn/AcademicPanel/SectionMargin/SectionVBox/AcademicContent
@onready var roommates_content: VBoxContainer = $MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/RightColumn/DormPanel/SectionMargin/SectionVBox/RoommatesContent
@onready var relationships_content: VBoxContainer = $MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/RightColumn/RelationshipsPanel/SectionMargin/SectionVBox/RelationshipsContent
@onready var data_content: VBoxContainer = $MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/RightColumn/DataPanel/SectionMargin/SectionVBox/RawDataContent


func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_btn.pressed.connect(_close)
	overlay_rect.gui_input.connect(_on_overlay_input)
	_apply_styles()


func _input(event: InputEvent):
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
		get_viewport().set_input_as_handled()


func toggle(game_ref: Node = null):
	if visible:
		_close()
	else:
		open(game_ref)


func open(game_ref: Node = null):
	if game_ref != null:
		game_node = game_ref
	if game_node == null:
		return

	was_time_running_before_open = bool(game_node.time_running) and not bool(game_node.waiting_for_choice)
	if was_time_running_before_open:
		game_node.time_running = false
		if game_node.has_method("_update_time_display"):
			game_node._update_time_display()

	visible = true
	scroll.scroll_vertical = 0
	_refresh_data()
	_animate_open()


func close():
	_close()


func _close():
	if not visible:
		return
	var should_restore_time := (
		game_node != null
		and was_time_running_before_open
		and not bool(game_node.waiting_for_choice)
		and not bool(game_node.game_over)
	)

	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(overlay_rect, "modulate:a", 0.0, 0.14)
	tw.tween_property(panel_host, "modulate:a", 0.0, 0.14)
	tw.tween_property(panel_host, "scale", Vector2(0.98, 0.98), 0.14)
	tw.finished.connect(func():
		visible = false
		if should_restore_time:
			game_node.time_running = true
			if game_node.has_method("_update_time_display"):
				game_node._update_time_display()
	)


func _on_overlay_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		_close()


func _animate_open():
	overlay_rect.modulate = Color(1, 1, 1, 0)
	panel_host.modulate = Color(1, 1, 1, 0)
	panel_host.scale = Vector2(0.985, 0.985)
	panel_host.pivot_offset = panel_host.size * 0.5

	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(overlay_rect, "modulate:a", 1.0, 0.18)
	tw.tween_property(panel_host, "modulate:a", 1.0, 0.18)
	tw.tween_property(panel_host, "scale", Vector2.ONE, 0.18)


func _apply_styles():
	var shell_style = StyleBoxFlat.new()
	shell_style.bg_color = Color(0.045, 0.06, 0.10, 0.985)
	shell_style.border_width_left = 1
	shell_style.border_width_top = 1
	shell_style.border_width_right = 1
	shell_style.border_width_bottom = 1
	shell_style.border_color = Color(0.22, 0.30, 0.44, 0.92)
	shell_style.set_corner_radius_all(18)
	shell_style.shadow_color = Color(0, 0, 0, 0.55)
	shell_style.shadow_size = 28
	shell_panel.add_theme_stylebox_override("panel", shell_style)

	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.07, 0.11, 0.18, 1.0)
	header_style.corner_radius_top_left = 18
	header_style.corner_radius_top_right = 18
	header_panel.add_theme_stylebox_override("panel", header_style)

	header_eyebrow.add_theme_color_override("font_color", Color(0.52, 0.74, 1.0))
	header_title.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	header_sub.add_theme_color_override("font_color", Color(0.70, 0.76, 0.86))

	_style_button(close_btn)

	for node in [
		$MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/QuickStatsPanel,
		$MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/LeftColumn/BasicInfoPanel,
		$MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/LeftColumn/ProgressPanel,
		$MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/LeftColumn/TalentsPanel,
		$MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/LeftColumn/TagsPanel,
		$MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/RightColumn/StoryPanel,
		$MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/RightColumn/AcademicPanel,
		$MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/RightColumn/DormPanel,
		$MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/RightColumn/RelationshipsPanel,
		$MarginContainer/Shell/MainVBox/ScrollContainer/ContentMargin/ContentVBox/BodyColumns/RightColumn/DataPanel,
	]:
		node.add_theme_stylebox_override("panel", _make_panel_style())

	for label in shell_panel.find_children("*", "Label", true, false):
		if label.name == "SectionTitle" or label.name == "QuickStatsTitle":
			label.add_theme_color_override("font_color", Color(0.86, 0.92, 1.0))


func _refresh_data():
	if game_node == null:
		return

	var info = game_node.get_date_info()
	header_title.text = "%s的档案" % game_node.player_name
	header_sub.text = "%s | %s | 第%d天" % [_year_label(info), str(info.phase), int(game_node.day_index) + 1]

	_populate_quick_stats()
	_populate_basic_info()
	_populate_progress()
	_populate_talents()
	_populate_tags()
	_populate_story()
	_populate_academic()
	_populate_roommates()
	_populate_relationships()
	_populate_data_details()


func _populate_quick_stats():
	_clear(quick_stats_grid)
	var items = [
		["学业", "%.1f" % float(game_node.study_points), Color(0.30, 0.74, 1.0), "当前学习值"],
		["社交", "%.0f" % float(game_node.social), Color(1.0, 0.64, 0.34), "社交联系"],
		["能力", "%.0f" % float(game_node.ability), Color(0.50, 0.92, 0.50), "执行能力"],
		["心态", "%.0f" % float(game_node.mental), Color(0.80, 0.56, 1.0), "稳定程度"],
		["健康", "%.0f" % float(game_node.health), Color(0.96, 0.40, 0.44), "身体状态"],
		["金钱", "%s元" % game_node._format_money(int(game_node.living_money)), Color(1.0, 0.86, 0.34), "当前余额"],
		["绩点", _get_gpa_text(), Color(0.34, 0.90, 0.86), "当前总绩点"],
		["学分", "%d / %d" % [int(game_node.earned_credits), int(game_node.major_required_credits)], Color(0.64, 0.94, 0.64), "毕业进度"],
	]
	for item in items:
		quick_stats_grid.add_child(_make_stat_card(item[0], item[1], item[2], item[3]))


func _populate_basic_info():
	_clear(info_grid)
	var info = game_node.get_date_info()
	var rows = [
		["姓名", str(game_node.player_name)],
		["性别", "男" if str(game_node.player_gender) == "male" else "女"],
		["学校", str(game_node.university_name)],
		["专业", str(game_node.major_name)],
		["出身", _get_background_name()],
		["年级", _year_label(info)],
		["学期", _get_semester_label(info)],
		["日期", "%d月%d日 %s" % [int(info.month), int(info.day), _weekday_label(info)]],
		["阶段", str(info.phase)],
		["时间状态", _get_time_status_text()],
		["存档位", "槽位%d" % (int(game_node.save_slot) + 1)],
		["自动存档", "每%d天一次" % int(game_node.auto_save_interval)],
	]
	for row in rows:
		info_grid.add_child(_make_k_label(row[0]))
		info_grid.add_child(_make_v_label(row[1]))


func _populate_progress():
	_clear(progress_content)
	var info = game_node.get_date_info()
	var story_data = _collect_story_progress(info)
	var total_story = max(int(story_data.total), 1)
	var credit_percent = int(round(clampf(float(game_node.earned_credits) / maxf(float(game_node.major_required_credits), 1.0), 0.0, 1.0) * 100.0))
	var day_percent = int(round(clampf(float(game_node.day_index + 1) / maxf(float(game_node.total_days), 1.0), 0.0, 1.0) * 100.0))
	var story_percent = int(round(float(story_data.completed.size()) / float(total_story) * 100.0))

	_add_kv_row(progress_content, "天数进度", "%d / %d（%d%%）" % [int(game_node.day_index) + 1, int(game_node.total_days), day_percent], Color(0.82, 0.88, 0.98))
	_add_kv_row(progress_content, "学分进度", "%d / %d（%d%%）" % [int(game_node.earned_credits), int(game_node.major_required_credits), credit_percent], Color(0.64, 0.94, 0.64))
	_add_kv_row(progress_content, "剧情进度", "%d / %d（%d%%）" % [story_data.completed.size(), int(story_data.total), story_percent], Color(0.34, 0.90, 0.86))
	_add_kv_row(progress_content, "当前主线", _get_current_focus_text(), Color(0.98, 0.88, 0.56))
	_add_kv_row(progress_content, "风险状态", _get_risk_text(), _get_risk_color())
	_add_kv_row(progress_content, "微信", "对话%d | 未读%d | 待回复%d" % [_get_active_conversation_count(), WechatSystem.get_total_unread(), _get_pending_reply_count()], Color(0.52, 0.90, 0.60))


func _populate_talents():
	_clear(talents_flow)
	var talent_module: TalentModule = ModuleManager.get_module("talent")
	var talents = []
	if talent_module:
		talents = talent_module.get_talents()
	if talents.is_empty():
		talents_flow.add_child(_make_empty_label("暂无天赋数据"))
		return

	for talent in talents:
		var color = Color.from_string(str(talent.get("color", "#4db8e6")), Color(0.30, 0.74, 1.0))
		var chip = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = color.darkened(0.70)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = color.darkened(0.35)
		style.set_corner_radius_all(10)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		chip.add_theme_stylebox_override("panel", style)

		var box = VBoxContainer.new()
		box.custom_minimum_size = Vector2(180, 0)
		box.add_theme_constant_override("separation", 4)
		chip.add_child(box)

		var title = Label.new()
		title.text = "%s %s" % [str(talent.get("icon", "")), str(talent.get("name", "未命名天赋"))]
		title.add_theme_font_size_override("font_size", 14)
		title.add_theme_color_override("font_color", color.lightened(0.28))
		box.add_child(title)

		var desc = Label.new()
		desc.text = str(talent.get("desc", ""))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", Color(0.74, 0.80, 0.88))
		box.add_child(desc)

		talents_flow.add_child(chip)


func _populate_tags():
	_clear(tags_flow)
	if game_node.tags.is_empty():
		tags_flow.add_child(_make_empty_label("暂无标签"))
		return

	for tag in game_node.tags:
		var chip = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.18, 0.28)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.24, 0.42, 0.72)
		style.set_corner_radius_all(8)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		chip.add_theme_stylebox_override("panel", style)

		var lbl = Label.new()
		lbl.text = str(game_node._translate_tag(str(tag)))
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.58, 0.82, 1.0))
		chip.add_child(lbl)
		tags_flow.add_child(chip)


func _populate_story():
	_clear(story_content)
	var info = game_node.get_date_info()
	var story_data = _collect_story_progress(info)

	_add_story_group("已完成", story_data.completed, Color(0.48, 0.92, 0.56))
	_add_story_group("可触发", story_data.available, Color(0.34, 0.80, 1.0))
	_add_story_group("后续剧情", story_data.upcoming, Color(0.72, 0.78, 0.88))


func _populate_academic():
	_clear(academic_content)
	_add_kv_row(academic_content, "总绩点", _get_gpa_text(), Color(0.34, 0.90, 0.86))
	_add_kv_row(academic_content, "学习值", "%.1f / 100" % float(game_node.study_points), Color(0.34, 0.80, 1.0))
	_add_kv_row(academic_content, "预警次数", "%d" % int(game_node.academic_warning_count), Color(0.96, 0.40, 0.44) if int(game_node.academic_warning_count) > 0 else Color(0.72, 0.78, 0.86))

	if game_node.semester_records.is_empty():
		academic_content.add_child(_make_empty_label("暂无学期记录"))
		return

	for record in game_node.semester_records:
		var gpa_val = float(record.get("semester_gpa", 0.0))
		_add_kv_row(
			academic_content,
			str(record.get("label", "未知学期")),
			"绩点 %.2f | 学分 %d" % [gpa_val, int(record.get("credits_earned", 0))],
			_gpa_color(gpa_val)
		)


func _populate_roommates():
	_clear(roommates_content)
	if game_node.roommate_roster.is_empty():
		roommates_content.add_child(_make_empty_label("暂无舍友信息"))
		return

	for roommate in game_node.roommate_roster:
		var effects = roommate.get("effects", {})
		var parts: Array[String] = []
		for key in effects:
			parts.append("%s %+d" % [_attr_name(str(key)), int(effects[key])])
		var text = str(roommate.get("persona_summary", roommate.get("summary", "")))
		var intro_memory = str(roommate.get("intro_memory", ""))
		if intro_memory != "":
			text += "\n初次对话：" + intro_memory
		if not parts.is_empty():
			text += "\n加成：" + " / ".join(parts)
		roommates_content.add_child(_make_simple_card(
			"%s | %s号床 | %s" % [
				str(roommate.get("nickname", roommate.get("name", "舍友"))),
				str(roommate.get("bed_no", "?")),
				str(roommate.get("persona_title", roommate.get("title", "普通"))),
			],
			text,
			Color(0.34, 0.80, 1.0)
		))


func _populate_relationships():
	_clear(relationships_content)
	if RelationshipManager.npc_data.is_empty():
		relationships_content.add_child(_make_empty_label("暂无人际数据"))
		return

	var role_ids = RelationshipManager.get_all_npcs()
	role_ids.sort()

	for role_id in role_ids:
		var npc_info = RelationshipManager.get_npc_display(role_id)
		if not bool(npc_info.get("met", false)) and int(npc_info.get("interactions", 0)) <= 0:
			continue

		var affinity = int(npc_info.get("affinity", 0))
		var accent = _relationship_color(affinity)
		var subtitle = "关系%s | 好感%d | 互动%d | 未读%d" % [
			str(npc_info.get("level_name", "未知")),
			affinity,
			int(npc_info.get("interactions", 0)),
			int(npc_info.get("unread_messages", 0)),
		]
		relationships_content.add_child(_make_simple_card(
			"%s | %s" % [str(npc_info.get("name", role_id)), str(npc_info.get("role", "未知身份"))],
			subtitle,
			accent
		))


func _populate_data_details():
	_clear(data_content)
	var info = game_node.get_date_info()
	_add_kv_row(data_content, "当前阶段", "%s | %s" % [_year_label(info), str(info.phase)], Color(0.82, 0.88, 0.98))
	_add_kv_row(data_content, "剧情池 / 日常池", "%d / %d" % [_count_story_events(), _count_daily_events_in_pool()], Color(0.72, 0.78, 0.86))
	_add_kv_row(data_content, "已用事件数", "%d" % game_node.used_event_ids.size(), Color(0.72, 0.78, 0.86))
	_add_kv_row(data_content, "标签数量", "%d" % game_node.tags.size(), Color(0.72, 0.78, 0.86))
	_add_kv_row(data_content, "活跃对话", "%d" % _get_active_conversation_count(), Color(0.52, 0.90, 0.60))
	_add_kv_row(data_content, "待回复数", "%d" % _get_pending_reply_count(), Color(0.52, 0.90, 0.60))
	_add_kv_row(data_content, "已认识角色", "%d" % RelationshipManager.get_met_npcs().size(), Color(0.72, 0.78, 0.86))
	_add_kv_row(data_content, "宿舍人数", "%d" % game_node.roommate_roster.size(), Color(0.72, 0.78, 0.86))
	_add_kv_row(data_content, "上次自动存档", "第%d天" % int(game_node.last_auto_save_day), Color(0.72, 0.78, 0.86))
	_add_kv_row(data_content, "财务状态", "透支" if bool(game_node.in_overdraft) else "正常", Color(0.96, 0.40, 0.44) if bool(game_node.in_overdraft) else Color(0.52, 0.90, 0.60))


func _add_story_group(title: String, items: Array, accent: Color):
	var section_title = Label.new()
	section_title.text = "%s | %d" % [title, items.size()]
	section_title.add_theme_font_size_override("font_size", 15)
	section_title.add_theme_color_override("font_color", accent)
	story_content.add_child(section_title)

	if items.is_empty():
		story_content.add_child(_make_empty_label("暂无"))
		return

	var show_count = min(items.size(), 4)
	for i in range(show_count):
		var item = items[i]
		story_content.add_child(_make_simple_card(
			str(item.get("title", "")),
			str(item.get("summary", "")),
			accent
		))


func _make_stat_card(title: String, value: String, accent: Color, note: String) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 108)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.11, 0.17)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = accent.darkened(0.35)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)

	var t = Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 12)
	t.add_theme_color_override("font_color", Color(0.58, 0.66, 0.76))
	box.add_child(t)

	var v = Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 22)
	v.add_theme_color_override("font_color", accent)
	box.add_child(v)

	var n = Label.new()
	n.text = note
	n.add_theme_font_size_override("font_size", 11)
	n.add_theme_color_override("font_color", Color(0.46, 0.52, 0.62))
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(n)

	return card


func _make_simple_card(title: String, body: String, accent: Color) -> PanelContainer:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.09, 0.14)
	style.border_width_left = 3
	style.border_color = accent
	style.set_corner_radius_all(12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	card.add_child(box)

	var t = Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 14)
	t.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	box.add_child(t)

	var d = Label.new()
	d.text = body
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_font_size_override("font_size", 12)
	d.add_theme_color_override("font_color", Color(0.68, 0.74, 0.84))
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(d)

	return card


func _make_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.12)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.16, 0.22, 0.32, 0.95)
	style.set_corner_radius_all(16)
	return style


func _make_k_label(text_value: String) -> Label:
	var label = Label.new()
	label.text = text_value + "："
	label.custom_minimum_size = Vector2(82, 0)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.50, 0.58, 0.68))
	return label


func _make_v_label(text_value: String) -> Label:
	var label = Label.new()
	label.text = text_value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _make_empty_label(text_value: String) -> Label:
	var label = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.42, 0.48, 0.58))
	return label


func _add_kv_row(parent: VBoxContainer, key: String, value: String, value_color: Color):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	var k = Label.new()
	k.text = key
	k.custom_minimum_size = Vector2(96, 0)
	k.add_theme_font_size_override("font_size", 13)
	k.add_theme_color_override("font_color", Color(0.50, 0.58, 0.68))
	row.add_child(k)

	var v = Label.new()
	v.text = value
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_theme_font_size_override("font_size", 13)
	v.add_theme_color_override("font_color", value_color)
	row.add_child(v)

	parent.add_child(row)


func _style_button(btn: Button):
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.18, 0.28, 0.42)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", normal)

	var hover = normal.duplicate()
	hover.bg_color = Color(0.24, 0.38, 0.58)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = normal.duplicate()
	pressed.bg_color = Color(0.14, 0.22, 0.36)
	btn.add_theme_stylebox_override("pressed", pressed)


func _clear(node: Node):
	for child in node.get_children():
		child.queue_free()


func _collect_story_progress(info: Dictionary) -> Dictionary:
	var completed: Array = []
	var available: Array = []
	var upcoming: Array = []
	var total := 0

	# 安全检查：如果 all_events 为空或方法不存在，直接返回空结构
	if not game_node or game_node.all_events.is_empty():
		return {"completed": completed, "available": available, "upcoming": upcoming, "total": 1}

	for event_data in game_node.all_events:
		if str(event_data.get("type", "")) != "story":
			continue
		total += 1
		var event_id = str(event_data.get("id", ""))
		var item = {
			"id": event_id,
			"title": _story_title(event_id),
			"summary": _event_summary(event_data),
			"year_min": int(event_data.get("year_min", 1)),
			"semester": int(event_data.get("semester", 0)),
		}
		if event_id in game_node.used_event_ids:
			completed.append(item)
		else:
			upcoming.append(item)

	upcoming.sort_custom(func(a, b):
		if int(a.year_min) == int(b.year_min):
			return int(a.semester) < int(b.semester)
		return int(a.year_min) < int(b.year_min)
	)

	if total == 0:
		total = 1

	return {"completed": completed, "available": available, "upcoming": upcoming, "total": total}


func _year_label(info: Dictionary) -> String:
	return "%s" % str(game_node._year_cn(int(info.year)))


func _weekday_label(info: Dictionary) -> String:
	if info.has("weekday_name"):
		return str(info.weekday_name)
	return ""


func _get_background_name() -> String:
	var bg_key = str(game_node.selected_background)
	if BACKGROUNDS.has(bg_key):
		return str(BACKGROUNDS[bg_key].get("name", bg_key))
	return bg_key


func _get_semester_label(info: Dictionary) -> String:
	var sem = int(info.get("semester", 0))
	if sem <= 0:
		return "假期"
	return "第%d学期" % (((int(info.year) - 1) * 2) + sem)


func _get_time_status_text() -> String:
	if bool(game_node.waiting_for_choice):
		return "事件暂停中"
	if bool(game_node.time_running):
		return "时间流动中"
	return "已暂停"


func _get_gpa_text() -> String:
	if game_node.semester_records.is_empty():
		return "-- / 4.00"
	return "%.2f / 4.00" % float(game_node.gpa)


func _get_current_focus_text() -> String:
	var t: Array = game_node.tags
	if "postgrad_committed" in t or "want_postgrad" in t:
		return "升学路线"
	if "started_business" in t:
		return "创业路线"
	if "big_company_intern" in t or "startup_intern" in t or "want_job" in t:
		return "就业路线"
	if "in_relationship" in t or "crush" in t or "secret_crush" in t:
		return "感情路线"
	if "tech_club" in t or "first_project" in t:
		return "技术成长"
	if "debate_club" in t:
		return "辩论发展"
	if "student_union" in t:
		return "学生会路线"
	return "校园日常"


func _get_risk_text() -> String:
	var risks: Array[String] = []
	if int(game_node.living_money) < 300:
		risks.append("资金偏低")
	if float(game_node.mental) < 35.0:
		risks.append("心态偏低")
	if float(game_node.health) < 35.0:
		risks.append("健康偏低")
	if int(game_node.academic_warning_count) > 0:
		risks.append("学业预警")
	if risks.is_empty():
		return "暂无明显风险"
	return " / ".join(risks)


func _get_risk_color() -> Color:
	return Color(0.96, 0.40, 0.44) if _get_risk_text() != "暂无明显风险" else Color(0.52, 0.90, 0.60)


func _count_story_events() -> int:
	var count := 0
	for event_data in game_node.all_events:
		if str(event_data.get("type", "")) == "story":
			count += 1
	return count


func _count_daily_events_in_pool() -> int:
	var count := 0
	for event_data in game_node.all_events:
		if str(event_data.get("type", "")) == "daily":
			count += 1
	return count


func _get_active_conversation_count() -> int:
	return WechatSystem.get_active_conversations().size()


func _get_pending_reply_count() -> int:
	# WechatSystem.conversations 实际是 _chat_history（Dict of Arrays）
	# 这里统计最后一条消息是 NPC 发来且未读的对话数
	var count := 0
	if not WechatSystem:
		return 0
	for role_id in WechatSystem.get_chat_partners():
		var history: Array = WechatSystem.get_chat_history(role_id)
		if history.is_empty():
			continue
		var last_msg: Dictionary = history[-1]
		if last_msg.get("sender", "") == "npc" and not last_msg.get("read", true):
			count += 1
	return count


func _story_title(event_id: String) -> String:
	return STORY_TITLE_MAP.get(event_id, event_id.replace("_", "、"))


func _event_summary(event_data: Dictionary) -> String:
	var text_value = str(event_data.get("text", ""))
	if text_value == "":
		text_value = str(event_data.get("result", ""))
	text_value = text_value.replace("\n", " ").strip_edges()
	if text_value.length() > 66:
		return text_value.substr(0, 66) + "..."
	return text_value


func _attr_name(attr: String) -> String:
	match attr:
		"study_points", "gpa":
			return "学业"
		"social":
			return "社交"
		"ability":
			return "能力"
		"mental":
			return "心态"
		"health":
			return "健康"
		"living_money":
			return "金钱"
	return attr


func _gpa_color(value: float) -> Color:
	if value < 1.0:
		return Color(0.96, 0.40, 0.44)
	if value < 2.0:
		return Color(1.0, 0.66, 0.34)
	if value >= 3.5:
		return Color(0.52, 0.90, 0.60)
	return Color(0.34, 0.80, 1.0)


func _relationship_color(affinity: int) -> Color:
	if affinity >= 80:
		return Color(1.0, 0.56, 0.76)
	if affinity >= 60:
		return Color(0.52, 0.90, 0.60)
	if affinity >= 40:
		return Color(0.34, 0.80, 1.0)
	if affinity < 20:
		return Color(0.96, 0.40, 0.44)
	return Color(0.72, 0.78, 0.86)

# ✅ 阶段1完成
