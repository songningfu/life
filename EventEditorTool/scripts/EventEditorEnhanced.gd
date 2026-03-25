extends Control
# 增强版事件编辑器 - 更强大、更易用

var events_data: Array = []
var current_event: Dictionary = {}
var current_event_index: int = -1
var choice_editors: Array = []
var unsaved_changes: bool = false

# 事件模板
var event_templates = {
	"story_template": {
		"id": "y1s1_new_story",
		"title": "新主线事件",
		"description": "这是一个主线事件的描述...",
		"type": "story",
		"year_min": 1,
		"year_max": 1,
		"semester": "上",
		"once": true,
		"choices": [
			{"text": "选项A", "effects": {"study_points": 5, "mental": -3}},
			{"text": "选项B", "effects": {"social": 5, "health": -3}}
		]
	},
	"daily_template": {
		"id": "daily_new_event",
		"title": "新日常事件",
		"description": "这是一个日常事件的描述...",
		"type": "daily",
		"year_min": 1,
		"year_max": 4,
		"cooldown_days": 7,
		"choices": [
			{"text": "选项A", "effects": {"mental": 3}},
			{"text": "选项B", "effects": {"health": 3}}
		]
	}
}

# 常用标签库
var common_tags = {
	"社团": ["debate_club", "tech_club", "student_union", "no_club"],
	"关系": ["crush", "secret_crush", "in_relationship", "broke_up"],
	"路线": ["want_postgrad", "want_job", "want_abroad", "want_stable"],
	"成就": ["debate_winner", "first_project", "competition_exp", "part_time_exp"]
}

@onready var search_bar = $MainContainer/LeftPanel/SearchBar
@onready var filter_type = $MainContainer/LeftPanel/FilterContainer/FilterType
@onready var event_list = $MainContainer/LeftPanel/EventList
@onready var event_id = $MainContainer/RightPanel/EditorContainer/BasicInfo/IDContainer/EventID
@onready var event_title = $MainContainer/RightPanel/EditorContainer/BasicInfo/TitleContainer/EventTitle
@onready var event_type = $MainContainer/RightPanel/EditorContainer/BasicInfo/TypeContainer/EventType
@onready var event_desc = $MainContainer/RightPanel/EditorContainer/BasicInfo/DescContainer/EventDesc
@onready var year_min = $MainContainer/RightPanel/EditorContainer/Conditions/YearContainer/YearMin
@onready var year_max = $MainContainer/RightPanel/EditorContainer/Conditions/YearContainer/YearMax
@onready var requires_tags = $MainContainer/RightPanel/EditorContainer/Conditions/TagsContainer/Requires
@onready var excludes_tags = $MainContainer/RightPanel/EditorContainer/Conditions/TagsContainer/Excludes
@onready var choices_list = $MainContainer/RightPanel/EditorContainer/Choices/ChoicesList
@onready var status_label = $MainContainer/LeftPanel/StatusLabel
@onready var template_btn = $MainContainer/LeftPanel/ButtonContainer/TemplateBtn
@onready var duplicate_btn = $MainContainer/LeftPanel/ButtonContainer/DuplicateBtn
@onready var validate_btn = $MainContainer/RightPanel/EditorContainer/ValidateBtn
@onready var preview_btn = $MainContainer/RightPanel/EditorContainer/PreviewBtn
@onready var tag_helper_btn = $MainContainer/RightPanel/EditorContainer/Conditions/TagsContainer/TagHelperBtn

func _ready():
	_setup_filters()
	_load_events()
	_refresh_event_list()
	_update_status("就绪")

func _setup_filters():
	filter_type.add_item("全部", 0)
	filter_type.add_item("story", 1)
	filter_type.add_item("daily", 2)
	event_type.add_item("story", 0)
	event_type.add_item("daily", 1)

func _load_events():
	var file_path = "res://data/events.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_text = file.get_as_text()
		file.close()
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			events_data = json.data
			_update_status("已加载 %d 个事件" % events_data.size())
		else:
			_update_status("JSON解析错误", true)
	else:
		_update_status("找不到事件文件", true)

func _refresh_event_list():
	event_list.clear()
	var search_text = search_bar.text.to_lower()
	var filter_idx = filter_type.selected
	var count = 0
	
	for i in range(events_data.size()):
		var event = events_data[i]
		var event_id_str = event.get("id", "")
		var event_title_str = event.get("title", "")
		var event_type_str = event.get("type", "")
		
		if search_text != "":
			if not (event_id_str.to_lower().contains(search_text) or event_title_str.to_lower().contains(search_text)):
				continue
		
		if filter_idx == 1 and event_type_str != "story":
			continue
		if filter_idx == 2 and event_type_str != "daily":
			continue
		
		var display_text = "[%s] %s - %s" % [event_type_str, event_id_str, event_title_str]
		event_list.add_item(display_text)
		event_list.set_item_metadata(event_list.item_count - 1, i)
		count += 1
	
	_update_status("显示 %d 个事件" % count)

func _update_status(message: String, is_error: bool = false):
	if status_label:
		status_label.text = "状态: " + message
		status_label.modulate = Color.RED if is_error else Color.WHITE

func _on_search_changed(new_text: String):
	_refresh_event_list()

func _on_filter_changed(index: int):
	_refresh_event_list()

func _on_event_selected(index: int):
	if unsaved_changes:
		# 简单提示，实际项目可以用对话框
		print("警告：有未保存的更改")
	var event_index = event_list.get_item_metadata(index)
	_load_event_to_editor(event_index)

func _load_event_to_editor(index: int):
	if index < 0 or index >= events_data.size():
		return
	
	current_event_index = index
	current_event = events_data[index].duplicate(true)
	unsaved_changes = false
	
	event_id.text = current_event.get("id", "")
	event_title.text = current_event.get("title", "")
	event_desc.text = current_event.get("description", "")
	
	var type_str = current_event.get("type", "story")
	event_type.selected = 0 if type_str == "story" else 1
	
	year_min.value = current_event.get("year_min", 1)
	year_max.value = current_event.get("year_max", 4)
	
	var requires = current_event.get("requires", [])
	requires_tags.text = ",".join(requires)
	
	var excludes = current_event.get("excludes", [])
	excludes_tags.text = ",".join(excludes)
	
	_clear_choices()
	var choices = current_event.get("choices", [])
	for choice in choices:
		_add_choice_editor(choice)
	
	_update_status("已加载事件: " + current_event.get("id", ""))

func _clear_choices():
	for editor in choice_editors:
		editor.queue_free()
	choice_editors.clear()

func _add_choice_editor(choice_data: Dictionary = {}):
	var choice_editor = preload("res://scenes/ChoiceEditor.tscn").instantiate()
	choices_list.add_child(choice_editor)
	choice_editors.append(choice_editor)
	
	if not choice_data.is_empty():
		choice_editor.load_choice(choice_data)
	
	choice_editor.delete_requested.connect(_on_choice_delete_requested.bind(choice_editor))

func _on_add_choice():
	_add_choice_editor({})
	unsaved_changes = true

func _on_choice_delete_requested(editor):
	var idx = choice_editors.find(editor)
	if idx >= 0:
		choice_editors.remove_at(idx)
		editor.queue_free()
		unsaved_changes = true

func _on_apply_changes():
	if current_event_index < 0:
		_update_status("请先选择一个事件", true)
		return
	
	# 验证
	if not _validate_event():
		return
	
	current_event["id"] = event_id.text
	current_event["title"] = event_title.text
	current_event["description"] = event_desc.text
	current_event["type"] = "story" if event_type.selected == 0 else "daily"
	current_event["year_min"] = int(year_min.value)
	current_event["year_max"] = int(year_max.value)
	
	var requires_text = requires_tags.text.strip_edges()
	if requires_text != "":
		current_event["requires"] = requires_text.split(",", false)
		for i in range(current_event["requires"].size()):
			current_event["requires"][i] = current_event["requires"][i].strip_edges()
	else:
		current_event.erase("requires")
	
	var excludes_text = excludes_tags.text.strip_edges()
	if excludes_text != "":
		current_event["excludes"] = excludes_text.split(",", false)
		for i in range(current_event["excludes"].size()):
			current_event["excludes"][i] = current_event["excludes"][i].strip_edges()
	else:
		current_event.erase("excludes")
	
	var choices = []
	for editor in choice_editors:
		choices.append(editor.get_choice_data())
	current_event["choices"] = choices
	
	events_data[current_event_index] = current_event
	unsaved_changes = false
	_refresh_event_list()
	_update_status("✓ 事件已更新: " + current_event["id"])

func _validate_event() -> bool:
	if event_id.text.strip_edges() == "":
		_update_status("错误：事件ID不能为空", true)
		return false
	
	if event_title.text.strip_edges() == "":
		_update_status("错误：事件标题不能为空", true)
		return false
	
	if choice_editors.size() == 0:
		_update_status("警告：事件至少需要一个选项", true)
		return false
	
	# 检查ID重复
	for i in range(events_data.size()):
		if i != current_event_index:
			if events_data[i].get("id", "") == event_id.text:
				_update_status("错误：事件ID已存在", true)
				return false
	
	return true

func _on_validate():
	if _validate_event():
		_update_status("✓ 验证通过")
	else:
		_update_status("验证失败，请检查错误", true)

func _on_preview():
	var preview_text = "=== 事件预览 ===\n"
	preview_text += "ID: %s\n" % event_id.text
	preview_text += "标题: %s\n" % event_title.text
	preview_text += "类型: %s\n" % ("story" if event_type.selected == 0 else "daily")
	preview_text += "年级: %d-%d\n" % [year_min.value, year_max.value]
	preview_text += "\n描述:\n%s\n" % event_desc.text
	preview_text += "\n选项:\n"
	for i in range(choice_editors.size()):
		var choice_data = choice_editors[i].get_choice_data()
		preview_text += "%d. %s\n" % [i+1, choice_data.get("text", "")]
		if choice_data.has("effects"):
			preview_text += "   效果: %s\n" % str(choice_data["effects"])
	
	print(preview_text)
	_update_status("预览已输出到控制台")

func _on_new_event():
	var new_event = {
		"id": "new_event_" + str(Time.get_ticks_msec()),
		"title": "新事件",
		"description": "事件描述",
		"type": "daily",
		"year_min": 1,
		"year_max": 4,
		"choices": []
	}
	events_data.append(new_event)
	_refresh_event_list()
	_load_event_to_editor(events_data.size() - 1)
	_update_status("✓ 已创建新事件")

func _on_new_from_template():
	# 显示模板选择（简化版，直接用story模板）
	var template = event_templates["story_template"].duplicate(true)
	template["id"] = "new_" + str(Time.get_ticks_msec())
	events_data.append(template)
	_refresh_event_list()
	_load_event_to_editor(events_data.size() - 1)
	_update_status("✓ 从模板创建事件")

func _on_duplicate_event():
	if current_event_index < 0:
		_update_status("请先选择要复制的事件", true)
		return
	
	var duplicated = current_event.duplicate(true)
	duplicated["id"] = duplicated["id"] + "_copy_" + str(Time.get_ticks_msec())
	events_data.append(duplicated)
	_refresh_event_list()
	_load_event_to_editor(events_data.size() - 1)
	_update_status("✓ 已复制事件")

func _on_delete_event():
	if current_event_index < 0:
		_update_status("请先选择要删除的事件", true)
		return
	
	var event_id_str = events_data[current_event_index].get("id", "")
	events_data.remove_at(current_event_index)
	current_event_index = -1
	current_event = {}
	_clear_choices()
	_refresh_event_list()
	_update_status("✓ 已删除事件: " + event_id_str)

func _on_save_to_file():
	# 备份原文件
	var file_path = "res://data/events.json"
	var backup_path = "res://data/events_backup_" + str(Time.get_unix_time_from_system()) + ".json"
	
	if FileAccess.file_exists(file_path):
		var original = FileAccess.open(file_path, FileAccess.READ)
		var backup = FileAccess.open(backup_path, FileAccess.WRITE)
		if original and backup:
			backup.store_string(original.get_as_text())
			backup.close()
			original.close()
	
	# 保存新文件
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_text = JSON.stringify(events_data, "\t")
		file.store_string(json_text)
		file.close()
		_update_status("✓ 已保存 %d 个事件（已备份）" % events_data.size())
	else:
		_update_status("保存失败", true)

func _on_tag_helper():
	var help_text = "=== 常用标签参考 ===\n"
	for category in common_tags:
		help_text += "\n%s:\n" % category
		for tag in common_tags[category]:
			help_text += "  - %s\n" % tag
	print(help_text)
	_update_status("标签帮助已输出到控制台")
