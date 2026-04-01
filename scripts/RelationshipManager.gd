extends Node
# ══════════════════════════════════════════════
#        NPC 好感度 & 关系系统
# ══════════════════════════════════════════════

# 关系等级定义
enum RelLevel { STRANGER, ACQUAINTANCE, FRIEND, CLOSE_FRIEND, BEST_FRIEND, CRUSH, LOVER, EX }

# 关系等级中文名
const REL_NAMES = {
	RelLevel.STRANGER: "陌生人",
	RelLevel.ACQUAINTANCE: "认识",
	RelLevel.FRIEND: "朋友",
	RelLevel.CLOSE_FRIEND: "好友",
	RelLevel.BEST_FRIEND: "挚友",
	RelLevel.CRUSH: "心动",
	RelLevel.LOVER: "恋人",
	RelLevel.EX: "前任",
}

# 好感度→关系等级阈值（普通NPC）
const LEVEL_THRESHOLDS = [
	[0, RelLevel.STRANGER],
	[10, RelLevel.ACQUAINTANCE],
	[30, RelLevel.FRIEND],
	[55, RelLevel.CLOSE_FRIEND],
	[80, RelLevel.BEST_FRIEND],
]

# NPC 角色信息模板
const NPC_TEMPLATES = {
	"roommate_gamer": {
		"role": "室友", "gender": "male",
		"personality": "爱打游戏，性格开朗，有点懒",
		"icon": "🎮", "color": "#4db8e6",
	},
	"roommate_studious": {
		"role": "室友", "gender": "male",
		"personality": "学霸，安静，作息规律",
		"icon": "📚", "color": "#99e64d",
	},
	"roommate_quiet": {
		"role": "室友", "gender": "male",
		"personality": "内向安静，喜欢独处，偶尔冒出金句",
		"icon": "🤫", "color": "#b380ff",
	},
	"crush_target": {
		"role": "同学", "gender": "female",
		"personality": "温柔大方，成绩不错，笑起来很好看",
		"icon": "💫", "color": "#ff6b9d",
	},
	"debate_senior": {
		"role": "学长", "gender": "male",
		"personality": "辩论社核心，口才一流，很照顾后辈",
		"icon": "🎤", "color": "#ff9933",
	},
	"tech_senior": {
		"role": "学长", "gender": "male",
		"personality": "技术大佬，寡言少语，但人很好",
		"icon": "💻", "color": "#6ec6ff",
	},
	"union_minister": {
		"role": "学生会", "gender": "male",
		"personality": "学生会部长，做事认真，有点严肃",
		"icon": "📋", "color": "#e6d94d",
	},
	"neighbor_classmate": {
		"role": "同学", "gender": "female",
		"personality": "隔壁班的，热心肠，爱分享笔记",
		"icon": "📝", "color": "#ff85a2",
	},
	"counselor": {
		"role": "辅导员", "gender": "female",
		"personality": "年轻的辅导员，亲和力强，偶尔严厉",
		"icon": "👩‍🏫", "color": "#c0a0ff",
	},
	"lin_zhiyi": {
		"role": "同学", "gender": "female",
		"personality": "安静而优秀，喜欢阅读和写作",
		"icon": "📖", "color": "#4db8e6",
	},
	"su_xiaowan": {
		"role": "同学", "gender": "female",
		"personality": "辩论社活跃分子，表面强势内心脆弱",
		"icon": "🎤", "color": "#ff9933",
	},
	"chen_yutong": {
		"role": "同学", "gender": "female",
		"personality": "温柔大方，对所有人都很热情",
		"icon": "🌸", "color": "#ff85a2",
	},
	"zhou_yiran": {
		"role": "同学", "gender": "female",
		"personality": "独立坚强，同时打两份工",
		"icon": "💪", "color": "#a0522d",
	},
	"shen_yingshuang": {
		"role": "同学", "gender": "female",
		"personality": "考研战友，专注而内敛",
		"icon": "📝", "color": "#6c5ce7",
	},
}

# ========== 运行时数据 ==========
var npc_data: Dictionary = {}  # role_id -> {affinity, level, interactions, ...}

func _ready():
	pass

# ========== 初始化 ==========
func init_all_npcs():
	npc_data.clear()
	for role_id in NPC_TEMPLATES:
		var template = NPC_TEMPLATES[role_id]
		var initial_affinity = _get_initial_affinity(role_id)
		npc_data[role_id] = {
			"affinity": initial_affinity,
			"level": _calc_level(role_id, initial_affinity),
			"interactions": 0,
			"last_interaction_day": -1,
			"met": initial_affinity > 0,
			"special_flags": [],
			"chat_history": [],
			"unread_messages": 0,
		}

func _get_initial_affinity(role_id: String) -> int:
	match role_id:
		"roommate_gamer", "roommate_studious", "roommate_quiet":
			return 15  # 室友开局就认识
		"counselor":
			return 10  # 辅导员开局认识
		"chen_yutong":
			return 10  # 开局自动认识
		_:
			return 0

# ========== 好感度操作 ==========
func change_affinity(role_id: String, amount: int, day_index: int = -1) -> Dictionary:
	if role_id not in npc_data:
		return {}
	var data = npc_data[role_id]
	var old_level = data.level
	data.affinity = clampi(data.affinity + amount, -20, 100)
	data.interactions += 1
	if day_index >= 0:
		data.last_interaction_day = day_index
	if not data.met and data.affinity > 0:
		data.met = true
	data.level = _calc_level(role_id, data.affinity)

	# 好感变更通知
	if amount != 0 and has_node("/root/Notify") and NamePool and NamePool.has_method("get_full_name"):
		Notify.affinity_change(NamePool.get_full_name(role_id), amount)
	elif amount != 0 and has_node("/root/Notify"):
		Notify.affinity_change(role_id, amount)

	var result = {"old_level": old_level, "new_level": data.level, "affinity": data.affinity}
	if old_level != data.level:
		result["level_changed"] = true
		result["level_name"] = REL_NAMES.get(data.level, "未知")
	return result

func get_affinity(role_id: String) -> int:
	if role_id in npc_data:
		return npc_data[role_id].affinity
	return 0

func get_level(role_id: String) -> int:
	if role_id in npc_data:
		return npc_data[role_id].level
	return RelLevel.STRANGER

func get_level_name(role_id: String) -> String:
	return REL_NAMES.get(get_level(role_id), "未知")

func is_met(role_id: String) -> bool:
	if role_id in npc_data:
		return npc_data[role_id].met
	return false

func set_special_relation(role_id: String, level: int):
	if role_id in npc_data:
		npc_data[role_id].level = level

func add_flag(role_id: String, flag: String):
	if role_id in npc_data:
		if flag not in npc_data[role_id].special_flags:
			npc_data[role_id].special_flags.append(flag)

func has_flag(role_id: String, flag: String) -> bool:
	if role_id in npc_data:
		return flag in npc_data[role_id].special_flags
	return false

# ========== 等级计算 ==========
func _calc_level(role_id: String, affinity: int) -> int:
	# 特殊关系不受好感度影响
	if role_id in npc_data:
		var current = npc_data[role_id].level
		if current in [RelLevel.CRUSH, RelLevel.LOVER, RelLevel.EX]:
			return current
	var result = RelLevel.STRANGER
	for entry in LEVEL_THRESHOLDS:
		if affinity >= entry[0]:
			result = entry[1]
	return result

# ========== 获取所有已认识NPC ==========
func get_met_npcs() -> Array:
	var result = []
	for role_id in npc_data:
		if npc_data[role_id].met:
			result.append(role_id)
	return result

func get_all_npcs() -> Array:
	return npc_data.keys()

# ========== 获取NPC显示信息 ==========
func get_npc_display(role_id: String) -> Dictionary:
	var template = NPC_TEMPLATES.get(role_id, {})
	var data = npc_data.get(role_id, {})
	var npc_name = NamePool.get_full_name(role_id) if NamePool.has_method("get_full_name") else role_id
	var nickname = NamePool.get_nickname(role_id) if NamePool.has_method("get_nickname") else role_id
	return {
		"role_id": role_id,
		"name": npc_name,
		"nickname": nickname,
		"role": template.get("role", "未知"),
		"gender": template.get("gender", "male"),
		"personality": template.get("personality", ""),
		"icon": template.get("icon", "👤"),
		"color": template.get("color", "#ffffff"),
		"affinity": data.get("affinity", 0),
		"level": data.get("level", RelLevel.STRANGER),
		"level_name": REL_NAMES.get(data.get("level", RelLevel.STRANGER), "未知"),
		"met": data.get("met", false),
		"interactions": data.get("interactions", 0),
		"unread_messages": data.get("unread_messages", 0),
	}

# ========== 序列化 ==========
func serialize() -> Dictionary:
	return npc_data.duplicate(true)

func deserialize(data: Dictionary):
	npc_data = data.duplicate(true)

# ========== 兼容方法（供 PhoneSystem / WechatSystem 调用） ==========

## PhoneSystem.get_sendable_messages 中调用
func get_relationship(role_id: String) -> Dictionary:
	return get_npc_display(role_id)

## PhoneSystem._show_contacts_app 中调用
func get_all_relationships() -> Array:
	return get_all_npcs()

## WechatSystem._apply_message_effects 中调用
func modify_affinity(role_id: String, amount: int, day_index: int = -1) -> Dictionary:
	return change_affinity(role_id, amount, day_index)

# ✅ 阶段3完成
