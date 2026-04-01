extends Node

# 场景名到路径映射
const SCENE_MAP := {
	"studio_logo": "res://scenes/studio_logo.tscn",
	"main_menu": "res://scenes/main_menu.tscn",
	"game": "res://scenes/Game.tscn",
	"char_creation": "res://scenes/CharacterCreation.tscn"
}

# 通用淡入淡出（默认过渡）
func fade_to(scene_key: String) -> void:
	_change_scene(scene_key, {
		"pattern": "fade",
		"color": Color(0, 0, 0, 1),
		"speed": 2.0,
		"wait_time": 0.0
	})

# Logo 到主菜单（慢速淡黑）
func logo_to_menu() -> void:
	_change_scene("main_menu", {
		"pattern": "fade",
		"color": Color(0, 0, 0, 1),
		"speed": 1.0,
		"wait_time": 0.0
	})

# 主菜单到角色创建（右滑）
func menu_to_creation() -> void:
	_change_scene("char_creation", {
		"pattern": "horizontal",
		"invert_on_leave": true,
		"color": Color(0.02, 0.03, 0.05, 1.0),
		"speed": 2.5,
		"wait_time": 0.0
	})

# 角色创建到游戏（慢速淡白）
func creation_to_game() -> void:
	_change_scene("game", {
		"pattern": "fade",
		"color": Color(1, 1, 1, 1),
		"speed": 0.85,
		"wait_time": 0.0
	})

# 游戏中日与日之间（快速淡黑）
func day_transition() -> void:
	if not _has_scene_manager():
		return
	if SceneManager.is_transitioning:
		return
	SceneManager.fade_in_place({
		"pattern": "fade",
		"color": Color(0, 0, 0, 1),
		"speed": 5.5,
		"wait_time": 0.0
	})

# 返回主菜单
func back_to_menu() -> void:
	_change_scene("main_menu", {
		"pattern": "fade",
		"color": Color(0, 0, 0, 1),
		"speed": 2.0,
		"wait_time": 0.0
	})

func _change_scene(scene_key: String, options: Dictionary) -> void:
	if not _has_scene_manager():
		return
	if SceneManager.is_transitioning:
		return
	if not SCENE_MAP.has(scene_key):
		push_warning("SceneTransitions: 未找到场景映射 %s" % scene_key)
		return
	SceneManager.change_scene(SCENE_MAP[scene_key], options)

func _has_scene_manager() -> bool:
	return has_node("/root/SceneManager")
