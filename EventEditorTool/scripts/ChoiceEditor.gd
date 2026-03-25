extends PanelContainer

signal delete_requested

@onready var choice_text = $MarginContainer/VBoxContainer/TextContainer/ChoiceText
@onready var study_spin = $MarginContainer/VBoxContainer/EffectsContainer/EffectsGrid/Study
@onready var social_spin = $MarginContainer/VBoxContainer/EffectsContainer/EffectsGrid/Social
@onready var ability_spin = $MarginContainer/VBoxContainer/EffectsContainer/EffectsGrid/Ability
@onready var money_spin = $MarginContainer/VBoxContainer/EffectsContainer/EffectsGrid/Money
@onready var mental_spin = $MarginContainer/VBoxContainer/EffectsContainer/EffectsGrid/Mental
@onready var health_spin = $MarginContainer/VBoxContainer/EffectsContainer/EffectsGrid/Health
@onready var add_tags = $MarginContainer/VBoxContainer/TagsContainer/AddTags
@onready var remove_tags = $MarginContainer/VBoxContainer/TagsContainer/RemoveTags
@onready var effect_hint = $MarginContainer/VBoxContainer/HintContainer/EffectHint

func load_choice(choice_data: Dictionary):
	choice_text.text = choice_data.get("text", "")
	
	var effects = choice_data.get("effects", {})
	study_spin.value = effects.get("study_points", 0)
	social_spin.value = effects.get("social", 0)
	ability_spin.value = effects.get("ability", 0)
	money_spin.value = effects.get("living_money", 0)
	mental_spin.value = effects.get("mental", 0)
	health_spin.value = effects.get("health", 0)
	
	var add_tags_arr = choice_data.get("add_tags", [])
	add_tags.text = ",".join(add_tags_arr)
	
	var remove_tags_arr = choice_data.get("remove_tags", [])
	remove_tags.text = ",".join(remove_tags_arr)
	
	effect_hint.text = choice_data.get("effect_hint", "")

func get_choice_data() -> Dictionary:
	var data = {
		"text": choice_text.text
	}
	
	# 收集效果
	var effects = {}
	if study_spin.value != 0:
		effects["study_points"] = int(study_spin.value)
	if social_spin.value != 0:
		effects["social"] = int(social_spin.value)
	if ability_spin.value != 0:
		effects["ability"] = int(ability_spin.value)
	if money_spin.value != 0:
		effects["living_money"] = int(money_spin.value)
	if mental_spin.value != 0:
		effects["mental"] = int(mental_spin.value)
	if health_spin.value != 0:
		effects["health"] = int(health_spin.value)
	
	if not effects.is_empty():
		data["effects"] = effects
	
	# 收集标签
	var add_tags_text = add_tags.text.strip_edges()
	if add_tags_text != "":
		var tags_arr = add_tags_text.split(",", false)
		for i in range(tags_arr.size()):
			tags_arr[i] = tags_arr[i].strip_edges()
		data["add_tags"] = tags_arr
	
	var remove_tags_text = remove_tags.text.strip_edges()
	if remove_tags_text != "":
		var tags_arr = remove_tags_text.split(",", false)
		for i in range(tags_arr.size()):
			tags_arr[i] = tags_arr[i].strip_edges()
		data["remove_tags"] = tags_arr
	
	# 效果提示
	var hint_text = effect_hint.text.strip_edges()
	if hint_text != "":
		data["effect_hint"] = hint_text
	
	return data

func _on_delete_pressed():
	delete_requested.emit()
