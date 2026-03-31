## ModLoader.gd - 模组加载器
## 配置为 Autoload，负责加载内置模块和用户模组
extends Node

signal mods_loaded(built_in_count: int, user_mod_count: int)
signal mod_load_failed(mod_id: String, error: String)

const MODS_DIR: String = "user://mods/"

var _built_in_modules: Array[String] = [
	"res://scripts/modules/TalentModule.gd",
	"res://scripts/modules/LoveModule.gd",
]

var _loaded_user_mods: Array[Dictionary] = []
var _has_loaded: bool = false

func _ready() -> void:
	_log("模组加载器已初始化")

## 加载所有模组（防重复调用）
func load_all_modules() -> void:
	if _has_loaded:
		_log("模组已加载过，跳过")
		return
	_has_loaded = true
	_log("开始加载所有模组...")
	var built_in_count: int = _load_built_in_modules()
	var user_mod_count: int = _load_user_mods()
	_log("模组加载完成: %d个内置模块, %d个用户模组" % [built_in_count, user_mod_count])
	mods_loaded.emit(built_in_count, user_mod_count)

func _load_built_in_modules() -> int:
	var count: int = 0
	for script_path: String in _built_in_modules:
		if _load_built_in_module(script_path):
			count += 1
	return count

func _load_built_in_module(script_path: String) -> bool:
	if not FileAccess.file_exists(script_path):
		push_warning("ModLoader: 内置模块脚本不存在: %s" % script_path)
		return false
	
	var script: Script = load(script_path)
	if script == null:
		push_error("ModLoader: 无法加载脚本: %s" % script_path)
		return false
	
	var instance: Node = script.new()
	if instance == null:
		push_error("ModLoader: 无法实例化模块: %s" % script_path)
		return false
	
	if not instance is GameModule:
		push_error("ModLoader: 模块 '%s' 必须继承GameModule" % script_path)
		instance.free()
		return false
	
	var game_module: GameModule = instance as GameModule
	# 检查是否已注册（防重复）
	if ModuleManager.has_module(game_module.get_module_id()):
		_log("模块 '%s' 已存在，跳过" % game_module.get_module_id())
		instance.free()
		return false
	
	ModuleManager.register(game_module)
	return true

func add_built_in_module(script_path: String) -> void:
	if not _built_in_modules.has(script_path):
		_built_in_modules.append(script_path)

func _load_user_mods() -> int:
	var count: int = 0
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		push_error("ModLoader: 无法打开user://目录")
		return 0
	if not dir.dir_exists("mods"):
		_log("模组目录不存在，跳过用户模组加载")
		return 0
	
	var mod_dir: DirAccess = DirAccess.open(MODS_DIR)
	if mod_dir == null:
		push_error("ModLoader: 无法打开模组目录: %s" % MODS_DIR)
		return 0
	
	mod_dir.list_dir_begin()
	var folder_name: String = mod_dir.get_next()
	while not folder_name.is_empty():
		if mod_dir.current_is_dir() and not folder_name.begins_with("."):
			var mod_path: String = MODS_DIR + folder_name + "/"
			if _load_user_mod(mod_path, folder_name):
				count += 1
		folder_name = mod_dir.get_next()
	mod_dir.list_dir_end()
	return count

func _load_user_mod(mod_path: String, folder_name: String) -> bool:
	var meta_path: String = mod_path + "module.json"
	if not FileAccess.file_exists(meta_path):
		push_warning("ModLoader: 模组 '%s' 缺少module.json" % folder_name)
		return false
	
	var meta: Dictionary = _read_json_file(meta_path)
	if meta.is_empty():
		push_error("ModLoader: 无法读取模组元数据: %s" % folder_name)
		mod_load_failed.emit(folder_name, "无法读取module.json")
		return false
	
	var mod_id: String = meta.get("id", "")
	if mod_id.is_empty():
		push_error("ModLoader: 模组 '%s' 缺少id字段" % folder_name)
		mod_load_failed.emit(folder_name, "缺少id字段")
		return false
	
	var is_data_pack: bool = meta.get("type", "") == "data_pack"
	if is_data_pack:
		return _load_data_pack_mod(mod_path, meta)
	else:
		return _load_code_mod(mod_path, meta)

func _load_code_mod(mod_path: String, meta: Dictionary) -> bool:
	var mod_id: String = meta.get("id", "")
	var main_script: String = meta.get("main_script", "")
	if main_script.is_empty():
		push_error("ModLoader: 代码模组 '%s' 缺少main_script字段" % mod_id)
		mod_load_failed.emit(mod_id, "缺少main_script字段")
		return false
	
	var script_path: String = mod_path + main_script
	if not FileAccess.file_exists(script_path):
		push_error("ModLoader: 模组脚本不存在: %s" % script_path)
		mod_load_failed.emit(mod_id, "脚本文件不存在")
		return false
	
	var script: Script = load(script_path)
	if script == null:
		push_error("ModLoader: 无法加载模组脚本: %s" % script_path)
		mod_load_failed.emit(mod_id, "无法加载脚本")
		return false
	
	var instance: Node = script.new()
	if instance == null:
		push_error("ModLoader: 无法实例化模组: %s" % mod_id)
		mod_load_failed.emit(mod_id, "无法实例化")
		return false
	
	if not instance is GameModule:
		push_error("ModLoader: 模组 '%s' 必须继承GameModule" % mod_id)
		instance.free()
		mod_load_failed.emit(mod_id, "必须继承GameModule")
		return false
	
	var game_module: GameModule = instance as GameModule
	if game_module.get_module_id() != mod_id:
		push_warning("ModLoader: 模组ID不匹配 - module.json: %s, 脚本: %s" % [mod_id, game_module.get_module_id()])
	
	ModuleManager.register(game_module)
	_loaded_user_mods.append({
		"id": mod_id,
		"name": meta.get("name", ""),
		"type": "code",
		"path": mod_path
	})
	_log("已加载用户代码模组: %s (%s)" % [mod_id, meta.get("name", "")])
	return true

func _load_data_pack_mod(mod_path: String, meta: Dictionary) -> bool:
	var mod_id: String = meta.get("id", "")
	var mod_name: String = meta.get("name", "")
	
	var data_pack: DataPackModule = DataPackModule.new()
	data_pack.mod_id = mod_id
	data_pack.mod_name = mod_name
	data_pack.mod_path = mod_path
	
	var data_file: String = meta.get("data_file", "data/events.json")
	var full_data_path: String = mod_path + data_file
	if FileAccess.file_exists(full_data_path):
		var data: Dictionary = _read_json_file(full_data_path)
		data_pack.load_data(data)
	else:
		push_warning("ModLoader: 数据模组 '%s' 数据文件不存在: %s" % [mod_id, full_data_path])
	
	ModuleManager.register(data_pack)
	_loaded_user_mods.append({
		"id": mod_id,
		"name": mod_name,
		"type": "data_pack",
		"path": mod_path
	})
	_log("已加载用户数据模组: %s (%s)" % [mod_id, mod_name])
	return true

func get_loaded_user_mods() -> Array[Dictionary]:
	return _loaded_user_mods.duplicate()

func is_mod_loaded(mod_id: String) -> bool:
	for mod: Dictionary in _loaded_user_mods:
		if mod.get("id", "") == mod_id:
			return true
	return false

func unload_user_mod(mod_id: String) -> bool:
	if not is_mod_loaded(mod_id):
		return false
	ModuleManager.unregister(mod_id)
	for i: int in range(_loaded_user_mods.size()):
		if _loaded_user_mods[i].get("id", "") == mod_id:
			_loaded_user_mods.remove_at(i)
			break
	_log("已卸载用户模组: %s" % mod_id)
	return true

func _read_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var content: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var error: Error = json.parse(content)
	if error != OK:
		push_error("ModLoader: JSON解析错误: %s" % path)
		return {}
	var result: Variant = json.get_data()
	if result is Dictionary:
		return result
	return {}

func _log(message: String) -> void:
	print("[ModLoader] %s" % message)
