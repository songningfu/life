extends Control

var events_data: Array = []
var current_event: Dictionary = {}
var current_event_index: int = -1
var choice_editors: Array = []

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

func _ready():
	_setup_filters()
	_load_events()
	_refresh_event_list()

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
			print("已加载 %d 个事件" % events_data.size())
		else:
			push_error("JSON解析错误: " + str(error))
	else:
		push_error("找不到事件文件: " + file_path)

func _refresh_event_list():
	event_list.clear()
	var search_text = search_bar.text.to_lower()
	var filter_idx = filter_type.selected
	
	for i in range(events_data.size()):
		var event = events_data[i]
		var event_id_str = event.get("id", "")
		var event_title_str = event.get("title", "")
		var event_type_str = event.get("type", "")
		
		# 搜索过滤
		if search_text != "":
			if not (event_id_str.to_lower().contains(search_text) or event_title_str.to_lower().contains(search_text)):
				continue
		
		# 类型过滤
		if filter_idx == 1 and event_type_str != "story":
			continue
		if filter_idx == 2 and event_type_str != "daily":
			continue
		
		var display_text = "[%s] %s (%s)" % [event_type_str, event_id_str, event_title_str]
		event_list.add_item(display_text)
		event_list.set_item_metadata(event_list.item_count - 1, i)

func _on_search_changed(new_text: String):
	_refresh_event_list()

func _on_filter_changed(index: int):
	_refresh_event_list()

func _on_event_selected(index: int):
	var event_index = event_list.get_item_metadata(index)
	_load_event_to_editor(event_index)

func _load_event_to_editor(index: int):
	if index < 0 or index >= events_data.size():
		return
	
	current_event_index = index
	current_event = events_data[index].duplicate(true)
	
	# 加载基础信息
	event_id.text = current_event.get("id", "")
	event_title.text = current_event.get("title", "")
	event_desc.text = current_event.get("description", "")
	
	var type_str = current_event.get("type", "story")
	event_type.selected = 0 if type_str == "story" else 1
	
	# 加载条件
	year_min.value = current_event.get("year_min", 1)
	year_max.value = current_event.get("year_max", 4)
	
	var requires = current_event.get("requires", [])
	requires_tags.text = ",".join(requires)
	
	var excludes = current_event.get("excludes", [])
	excludes_tags.text = ",".join(excludes)
	
	# 加载选项
	_clear_choices()
	var choices = current_event.get("choices", [])
	for choice in choices:
		_add_choice_editor(choice)

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

func _on_choice_delete_requested(editor):
	var idx = choice_editors.find(editor)
	if idx >= 0:
		choice_editors.remove_at(idx)
		editor.queue_free()

func _on_apply_changes():
	if current_event_index < 0:
		return
	
	# 收集基础信息
	current_event["id"] = event_id.text
	current_event["title"] = event_title.text
	current_event["description"] = event_desc.text
	current_event["type"] = "story" if event_type.selected == 0 else "daily"
	
	# 收集条件
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
	
	# 收集选项
	var choices = []
	for editor in choice_editors:
		choices.append(editor.get_choice_data())
	current_event["choices"] = choices
	
	# 更新数据
	events_data[current_event_index] = current_event
	_refresh_event_list()
	print("事件已更新: " + current_event["id"])

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
	print("已创建新事件")

func _on_delete_event():
	if current_event_index < 0:
		return
	
	var event_id_str = events_data[current_event_index].get("id", "")
	events_data.remove_at(current_event_index)
	current_event_index = -1
	current_event = {}
	_clear_choices()
	_refresh_event_list()
	print("已删除事件: " + event_id_str)

func _on_save_to_file():
	var file_path = "res://data/events.json"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_text = JSON.stringify(events_data, "\t")
		file.store_string(json_text)
		file.close()
		print("事件已保存到: " + file_path)
	else:
		push_error("无法保存文件: " + file_path)
