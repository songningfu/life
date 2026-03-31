## LoveModule.gd - 恋爱系统模块
## 继承 GameModule，实现完整的恋爱系统
## 包含5位可攻略女性角色的完整故事线

class_name LoveModule
extends GameModule

# ==================== 恋爱阶段枚举 ====================

enum LovePhase {
	NOT_MET = 0,       # 未遇见
	MET = 1,           # 认识了
	FAMILIAR = 2,      # 熟悉
	AMBIGUOUS = 3,     # 暧昧
	CONFESSION = 4,    # 表白节点
	DATING = 5,        # 交往中
	STABLE = 6,        # 稳定关系
	CONFLICT = 7,      # 冲突/冷战
	BREAKUP = 8,       # 分手
	RECONCILE = 9,     # 复合
	REGRET = 10        # 遗憾结局
}

const PHASE_NAMES: Dictionary = {
	LovePhase.NOT_MET: "未遇见",
	LovePhase.MET: "认识",
	LovePhase.FAMILIAR: "熟悉",
	LovePhase.AMBIGUOUS: "暧昧",
	LovePhase.CONFESSION: "表白节点",
	LovePhase.DATING: "交往中",
	LovePhase.STABLE: "稳定关系",
	LovePhase.CONFLICT: "冷战",
	LovePhase.BREAKUP: "分手",
	LovePhase.RECONCILE: "复合",
	LovePhase.REGRET: "遗憾"
}

# ==================== 角色定义 ====================

const LOVE_INTERESTS: Dictionary = {
	"lin_zhiyi": {
		"display_name": "林知意",
		"meet_action": "library",
		"meet_probability": 0.25,
		"available_from_year": 1,
		"personality_tags": ["安静", "学霸", "英语好"],
		"core_conflict": "她要出国",
		"emotion_tone": "温暖而克制",
		"player_route": "学业型",
		"description": "图书馆偶遇的女孩，安静而优秀"
	},
	"su_xiaowan": {
		"display_name": "苏小晚",
		"meet_action": "club_activity",
		"meet_probability": 0.60,
		"available_from_year": 1,
		"personality_tags": ["强势", "外向", "反差萌"],
		"core_conflict": "性格反差",
		"emotion_tone": "热烈而冲突",
		"player_route": "社交型",
		"description": "社团招新时遇到的辩论社女生"
	},
	"chen_yutong": {
		"display_name": "陈雨桐",
		"meet_action": "auto",  # 开局自动认识
		"meet_probability": 1.0,
		"available_from_year": 1,
		"personality_tags": ["热情", "温柔", "慢热"],
		"core_conflict": "暗恋不自知",
		"emotion_tone": "细水长流",
		"player_route": "平衡型",
		"description": "隔壁班同学，开局就认识"
	},
	"zhou_yiran": {
		"display_name": "周一然",
		"meet_action": "part_time_job",
		"meet_probability": 0.30,
		"available_from_year": 2,  # 大一下/大二
		"personality_tags": ["独立", "坚强", "现实"],
		"core_conflict": "家境差异",
		"emotion_tone": "现实而坚韧",
		"player_route": "打工型",
		"description": "兼职时遇到的打工女孩"
	},
	"shen_yingshuang": {
		"display_name": "沈映霜",
		"meet_action": "postgrad_study",
		"meet_probability": 0.50,
		"available_from_year": 3,  # 大三
		"personality_tags": ["专注", "内敛", "战友"],
		"core_conflict": "同为考研人",
		"emotion_tone": "互相支撑",
		"player_route": "考研型",
		"description": "考研自习室遇到的战友"
	}
}

# ==================== 运行时数据 ====================

## 每个角色的恋爱数据 {role_id: love_data}
var _love_data: Dictionary = {}

## 当前主动追求的角色（同时只能攻略一个主要对象）
var _current_focus: String = ""

## 已触发恋爱事件记录
var _triggered_love_events: Array[String] = []

## 表白冷却期 {role_id: cooldown_days}
var _confession_cooldown: Dictionary = {}

# ==================== 身份方法 ====================

func get_module_id() -> String:
	return "love_system"

func get_module_name() -> String:
	return "恋爱系统"

# ==================== 生命周期钩子 ====================

func on_new_game(init_data: Dictionary) -> void:
	"""新游戏时初始化恋爱数据"""
	_love_data.clear()
	_current_focus = ""
	_triggered_love_events.clear()
	_confession_cooldown.clear()
	
	# 初始化所有角色的恋爱数据
	for role_id: String in LOVE_INTERESTS.keys():
		_love_data[role_id] = _create_default_love_data(role_id)
	
	# 陈雨桐开局自动认识
	if _love_data.has("chen_yutong"):
		_love_data["chen_yutong"]["phase"] = LovePhase.MET
		_love_data["chen_yutong"]["meet_day"] = 0
	
	_log("恋爱系统初始化完成")

func on_day_start(day_index: int, phase: String) -> void:
	"""每天开始时检查各种状态"""
	var year: int = (day_index / 365) + 1
	
	for role_id: String in _love_data.keys():
		var data: Dictionary = _love_data[role_id]
		var interest_data: Dictionary = LOVE_INTERESTS[role_id]
		
		# 检查是否到达可遇见年份
		if data["phase"] == LovePhase.NOT_MET:
			var available_year: int = interest_data.get("available_from_year", 1)
			if year >= available_year:
				# 检查是否触发初遇
				_try_trigger_first_meet(role_id, day_index)
		
		# 更新未互动天数
		if data["phase"] > LovePhase.NOT_MET:
			data["days_since_last_interact"] += 1
		
		# 暧昧期心动值自然衰减
		if data["phase"] == LovePhase.AMBIGUOUS:
			if data["days_since_last_interact"] > 5:
				data["spark"] = max(0, data["spark"] - 1)
				_log("%s 心动值自然衰减至 %d" % [role_id, data["spark"]])
		
		# 检查是否触发消失感
		if data["days_since_last_interact"] == 30:
			_trigger_drift_apart(role_id)
		
		# 更新表白冷却
		if _confession_cooldown.has(role_id):
			_confession_cooldown[role_id] -= 1
			if _confession_cooldown[role_id] <= 0:
				_confession_cooldown.erase(role_id)
	
	# 检查是否触发自动表白场景
	_check_auto_confession(day_index)

func on_action_performed(action_id: String, time_slot: String, context: Dictionary) -> void:
	"""行动执行后处理恋爱相关逻辑"""
	# 检查是否是与恋爱对象的互动
	var target_role: String = context.get("target_role", "")
	if target_role.is_empty():
		return
	
	if not _love_data.has(target_role):
		return
	
	var data: Dictionary = _love_data[target_role]
	
	# 更新互动记录
	data["days_since_last_interact"] = 0
	
	# 根据行动类型增加心动值
	var spark_gain: int = 0
	match action_id:
		"hangout_eat":
			spark_gain = randi() % 3 + 3  # 3-5
		"hangout_game":
			spark_gain = randi() % 2 + 2  # 2-3
		"hangout_study":
			spark_gain = randi() % 3 + 2  # 2-4
		"date":
			spark_gain = randi() % 3 + 3  # 3-5
		"chat_up":
			spark_gain = randi() % 2 + 1  # 1-2
	
	if spark_gain > 0:
		data["spark"] = min(100, data["spark"] + spark_gain)
		_log("与 %s 互动，心动值+%d，当前%d" % [target_role, spark_gain, data["spark"]])
	
	# 检查阶段推进
	_check_phase_advance(target_role)

func on_day_end(day_index: int, phase: String) -> void:
	"""每天结束时处理"""
	# 检查冲突状态
	for role_id: String in _love_data.keys():
		var data: Dictionary = _love_data[role_id]
		
		# 冲突期处理
		if data["phase"] == LovePhase.CONFLICT:
			data["conflict_meter"] += 1
			# 冲突持续太久可能分手
			if data["conflict_meter"] >= 7:
				_trigger_breakup(role_id, "conflict_timeout")

# ==================== 数据注入接口 ====================

func get_available_actions(day_index: int, phase: String, time_slot: String, player_state: Dictionary) -> Array[Dictionary]:
	"""提供恋爱相关的行动"""
	var actions: Array[Dictionary] = []
	
	for role_id: String in _love_data.keys():
		var data: Dictionary = _love_data[role_id]
		var interest_data: Dictionary = LOVE_INTERESTS[role_id]
		
		# 未遇见的不提供行动
		if data["phase"] == LovePhase.NOT_MET:
			continue
		
		# 检查年份限制
		var year: int = (day_index / 365) + 1
		var available_year: int = interest_data.get("available_from_year", 1)
		if year < available_year:
			continue
		
		# 根据阶段提供不同行动
		match data["phase"]:
			LovePhase.MET, LovePhase.FAMILIAR, LovePhase.AMBIGUOUS:
				# 暧昧期及以上解锁"找她"行动
				if time_slot in ["afternoon", "evening"]:
					actions.append({
						"id": "hangout_with_" + role_id,
						"name": "找%s" % interest_data["display_name"],
						"time_slots": ["afternoon", "evening"],
						"effects": {"spark": 2, "mental": 2},
						"target_role": role_id,
						"cost": 0,
						"event_pool": "love_ambiguous_" + role_id
					})
			
			LovePhase.DATING, LovePhase.STABLE:
				# 交往中解锁"约会"行动
				if time_slot in ["afternoon", "evening"]:
					actions.append({
						"id": "date_with_" + role_id,
						"name": "和%s约会" % interest_data["display_name"],
						"time_slots": ["afternoon", "evening"],
						"effects": {"mental": 5, "spark": 3, "living_money": -50},
						"target_role": role_id,
						"cost": 50,
						"conditions": {"min_living_money": 50},
						"event_pool": "love_dating_" + role_id
					})
			
			LovePhase.CONFLICT:
				# 冲突期解锁"找她谈谈"行动
				if time_slot in ["afternoon", "evening"]:
					actions.append({
						"id": "talk_with_" + role_id,
						"name": "找%s谈谈" % interest_data["display_name"],
						"time_slots": ["afternoon", "evening"],
						"effects": {"conflict_resolve": 10},
						"target_role": role_id,
						"cost": 0,
						"event_pool": "love_conflict_" + role_id
					})
	
	return actions

func get_event_injections(day_index: int, phase: String, last_action: String) -> Array[Dictionary]:
	"""注入恋爱事件"""
	var events: Array[Dictionary] = []
	
	# 根据角色阶段注入相应事件
	for role_id: String in _love_data.keys():
		var data: Dictionary = _love_data[role_id]
		
		# 检查是否有可触发的事件
		var injectable_event: Dictionary = _get_injectable_event(role_id, day_index, phase, last_action)
		if not injectable_event.is_empty():
			events.append(injectable_event)
	
	return events

func get_sendable_messages(role_id: String, context: Dictionary) -> Array[Dictionary]:
	"""提供可发送的恋爱消息"""
	var messages: Array[Dictionary] = []
	
	if not _love_data.has(role_id):
		return messages
	
	var data: Dictionary = _love_data[role_id]
	var phase: int = data["phase"]
	var interest_data: Dictionary = LOVE_INTERESTS[role_id]
	
	# 根据阶段和角色性格提供不同消息
	match role_id:
		"lin_zhiyi":
			messages.append_array(_get_lin_zhiyi_messages(phase, context))
		"su_xiaowan":
			messages.append_array(_get_su_xiaowan_messages(phase, context))
		"chen_yutong":
			messages.append_array(_get_chen_yutong_messages(phase, context))
		"zhou_yiran":
			messages.append_array(_get_zhou_yiran_messages(phase, context))
		"shen_yingshuang":
			messages.append_array(_get_shen_yingshuang_messages(phase, context))
	
	return messages

func get_npc_outgoing_messages(day_index: int, phase: String) -> Array[Dictionary]:
	"""提供NPC主动发来的恋爱消息"""
	var messages: Array[Dictionary] = []
	
	for role_id: String in _love_data.keys():
		var data: Dictionary = _love_data[role_id]
		
		# 未遇见或分手的不发消息
		if data["phase"] <= LovePhase.NOT_MET or data["phase"] >= LovePhase.BREAKUP:
			continue
		
		# 检查概率
		if randf() > 0.15:  # 15%概率
			continue
		
		# 根据阶段生成消息
		var msg: Dictionary = _generate_npc_message(role_id, phase)
		if not msg.is_empty():
			messages.append(msg)
	
	return messages

func get_morning_info(day_index: int) -> Array[Dictionary]:
	"""提供恋爱相关的晨间信息"""
	var infos: Array[Dictionary] = []
	
	for role_id: String in _love_data.keys():
		var data: Dictionary = _love_data[role_id]
		var interest_data: Dictionary = LOVE_INTERESTS[role_id]
		
		# 暧昧期提示
		if data["phase"] == LovePhase.AMBIGUOUS:
			if data["days_since_last_interact"] >= 3:
				infos.append({
					"icon": "💕",
					"text": "%s 好像有点想你了" % interest_data["display_name"],
					"priority": 7
				})
		
		# 冲突期提示
		if data["phase"] == LovePhase.CONFLICT:
			infos.append({
				"icon": "💔",
				"text": "和 %s 的关系需要修复" % interest_data["display_name"],
				"priority": 9
			})
		
		# 表白节点提示
		if data["phase"] == LovePhase.CONFESSION:
			infos.append({
				"icon": "💌",
				"text": "和 %s 的关系到了关键时刻" % interest_data["display_name"],
				"priority": 10
			})
	
	return infos

func get_ui_panels() -> Array[Dictionary]:
	"""提供恋爱日记面板"""
	return [{
		"id": "love_diary",
		"name": "恋爱日记",
		"icon": "💕",
		"scene": "res://scenes/modules/LoveDiaryPanel.tscn"
	}]

# ==================== 消息模板（按角色） ====================

func _get_lin_zhiyi_messages(phase: int, context: Dictionary) -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	
	match phase:
		LovePhase.MET:
			messages.append({"id": "lzy_lib_seat", "text": "图书馆有位子吗", "effects": {"spark": 1}})
			messages.append({"id": "lzy_study_help", "text": "有道题想请教你", "effects": {"spark": 2}})
		
		LovePhase.FAMILIAR:
			messages.append({"id": "lzy_lib_seat", "text": "图书馆有位子吗", "effects": {"spark": 1}})
			messages.append({"id": "lzy_share_book", "text": "推荐本书给你", "effects": {"spark": 2}})
			messages.append({"id": "lzy_thanks", "text": "上次谢谢你了", "effects": {"spark": 1}})
		
		LovePhase.AMBIGUOUS:
			messages.append({"id": "lzy_hair", "text": "你今天那个发型好看", "effects": {"spark": 3}})
			messages.append({"id": "lzy_weekend", "text": "周末有空吗", "effects": {"spark": 2}, "unlock_action": "hangout_with_lin_zhiyi"})
			messages.append({"id": "lzy_music", "text": "这首歌好像你", "effects": {"spark": 2}})
			messages.append({"id": "lzy_late", "text": "今天学到好晚", "effects": {"spark": 1}})
			messages.append({"id": "lzy_weather", "text": "今天风很大", "effects": {"spark": 1}})
		
		LovePhase.DATING, LovePhase.STABLE:
			messages.append({"id": "lzy_miss", "text": "想你了", "effects": {"spark": 3}})
			messages.append({"id": "lzy_dinner", "text": "晚上吃什么", "effects": {"spark": 1}})
			messages.append({"id": "lzy_busy", "text": "今天忙吗", "effects": {"spark": 1}})
			messages.append({"id": "lzy_goodnight", "text": "晚安", "effects": {"spark": 2}})
	
	return messages

func _get_su_xiaowan_messages(phase: int, context: Dictionary) -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	
	match phase:
		LovePhase.MET:
			messages.append({"id": "sxw_club", "text": "社团活动还去吗", "effects": {"spark": 1}})
			messages.append({"id": "sxw_debate", "text": "今天辩题是什么", "effects": {"spark": 2}})
		
		LovePhase.FAMILIAR:
			messages.append({"id": "sxw_nickname", "text": "苏大嘴", "effects": {"spark": 2}})
			messages.append({"id": "sxw_food", "text": "发现一家好吃的", "effects": {"spark": 2}})
			messages.append({"id": "sxw_meme", "text": "[表情包]", "effects": {"spark": 1}})
		
		LovePhase.AMBIGUOUS:
			messages.append({"id": "sxw_game", "text": "来两把？", "effects": {"spark": 2}})
			messages.append({"id": "sxw_movie", "text": "新电影看了吗", "effects": {"spark": 2}})
			messages.append({"id": "sxw_bored", "text": "好无聊啊", "effects": {"spark": 1}})
			messages.append({"id": "sxw_compliment", "text": "你今天挺好看的", "effects": {"spark": 3}})
			messages.append({"id": "sxw_care", "text": "别熬太晚", "effects": {"spark": 2}})
		
		LovePhase.DATING, LovePhase.STABLE:
			messages.append({"id": "sxw_miss", "text": "在干嘛", "effects": {"spark": 2}})
			messages.append({"id": "sxw_food", "text": "饿了吗", "effects": {"spark": 1}})
			messages.append({"id": "sxw_cute", "text": "你是不是傻", "effects": {"spark": 2}})
			messages.append({"id": "sxw_voice", "text": "[语音消息]", "effects": {"spark": 1}})
	
	return messages

func _get_chen_yutong_messages(phase: int, context: Dictionary) -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	
	match phase:
		LovePhase.MET:
			messages.append({"id": "cyt_notes", "text": "笔记借我抄抄", "effects": {"spark": 1}})
			messages.append({"id": "cyt_class", "text": "今天什么课", "effects": {"spark": 1}})
		
		LovePhase.FAMILIAR:
			messages.append({"id": "cyt_lunch", "text": "食堂吗", "effects": {"spark": 2}})
			messages.append({"id": "cyt_homework", "text": "作业写完了吗", "effects": {"spark": 1}})
			messages.append({"id": "cyt_weather", "text": "今天好热", "effects": {"spark": 1}})
		
		LovePhase.AMBIGUOUS:
			messages.append({"id": "cyt_walk", "text": "一起走走？", "effects": {"spark": 3}})
			messages.append({"id": "cyt_music", "text": "这首歌好听", "effects": {"spark": 2}})
			messages.append({"id": "cyt_care", "text": "你最近好像很累", "effects": {"spark": 2}})
			messages.append({"id": "cyt_hair", "text": "新发型很适合你", "effects": {"spark": 3}})
			messages.append({"id": "cyt_dream", "text": "昨晚梦到你了", "effects": {"spark": 4}})
		
		LovePhase.DATING, LovePhase.STABLE:
			messages.append({"id": "cyt_gentle", "text": "今天也辛苦了", "effects": {"spark": 2}})
			messages.append({"id": "cyt_future", "text": "以后想做什么", "effects": {"spark": 2}})
			messages.append({"id": "cyt_cook", "text": "想吃什么我给你做", "effects": {"spark": 3}})
	
	return messages

func _get_zhou_yiran_messages(phase: int, context: Dictionary) -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	
	match phase:
		LovePhase.MET:
			messages.append({"id": "zyr_shift", "text": "今天什么班", "effects": {"spark": 1}})
			messages.append({"id": "zyr_tired", "text": "辛苦了", "effects": {"spark": 2}})
		
		LovePhase.FAMILIAR:
			messages.append({"id": "zyr_work", "text": "今天忙吗", "effects": {"spark": 1}})
			messages.append({"id": "zyr_eat", "text": "吃饭了吗", "effects": {"spark": 2}})
			messages.append({"id": "zyr_rest", "text": "别太累", "effects": {"spark": 2}})
		
		LovePhase.AMBIGUOUS:
			messages.append({"id": "zyr_together", "text": "下次排班一起吗", "effects": {"spark": 3}})
			messages.append({"id": "zyr_save", "text": "发现个省钱攻略", "effects": {"spark": 2}})
			messages.append({"id": "zyr_encourage", "text": "你真的很厉害", "effects": {"spark": 3}})
			messages.append({"id": "zyr_share", "text": "这个给你", "effects": {"spark": 2}})
		
		LovePhase.DATING, LovePhase.STABLE:
			messages.append({"id": "zyr_support", "text": "我陪你", "effects": {"spark": 3}})
			messages.append({"id": "zyr_proud", "text": "为你骄傲", "effects": {"spark": 2}})
			messages.append({"id": "zyr_future", "text": "会好起来的", "effects": {"spark": 2}})
	
	return messages

func _get_shen_yingshuang_messages(phase: int, context: Dictionary) -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	
	match phase:
		LovePhase.MET:
			messages.append({"id": "sys_seat", "text": "这个位子有人吗", "effects": {"spark": 1}})
			messages.append({"id": "sys_pencil", "text": "借支笔", "effects": {"spark": 1}})
		
		LovePhase.FAMILIAR:
			messages.append({"id": "sys_progress", "text": "复习到哪了", "effects": {"spark": 2}})
			messages.append({"id": "sys_material", "text": "这个资料你要吗", "effects": {"spark": 2}})
			messages.append({"id": "sys_tired", "text": "休息一下吧", "effects": {"spark": 1}})
		
		LovePhase.AMBIGUOUS:
			messages.append({"id": "sys_together", "text": "一起走吧", "effects": {"spark": 3}})
			messages.append({"id": "sys_encourage", "text": "你可以的", "effects": {"spark": 2}})
			messages.append({"id": "sys_dinner", "text": "一起去吃煎饼", "effects": {"spark": 2}})
			messages.append({"id": "sys_future", "text": "考完了想做什么", "effects": {"spark": 3}})
		
		LovePhase.DATING, LovePhase.STABLE:
			messages.append({"id": "sys_study", "text": "今天也加油", "effects": {"spark": 2}})
			messages.append({"id": "sys_care", "text": "别熬坏身体", "effects": {"spark": 2}})
			messages.append({"id": "sys_together", "text": "一起上岸", "effects": {"spark": 3}})
	
	return messages

# ==================== NPC消息生成 ====================

func _generate_npc_message(role_id: String, phase: String) -> Dictionary:
	var templates: Array[Dictionary] = []
	var interest_data: Dictionary = LOVE_INTERESTS[role_id]
	
	match role_id:
		"lin_zhiyi":
			templates = [
				{"message": "今天图书馆人不多", "time_slot": "morning"},
				{"message": "有道题想请教你", "time_slot": "afternoon"},
				{"message": "明天还去图书馆吗", "time_slot": "evening"}
			]
		"su_xiaowan":
			templates = [
				{"message": "来社团吗", "time_slot": "afternoon"},
				{"message": "晚上开黑吗", "time_slot": "evening", "action_invite": "hangout_game"},
				{"message": "[表情包]", "time_slot": "evening"}
			]
		"chen_yutong":
			templates = [
				{"message": "今天什么课", "time_slot": "morning"},
				{"message": "食堂吗", "time_slot": "afternoon", "action_invite": "hangout_eat"},
				{"message": "作业借我看看", "time_slot": "evening"}
			]
		"zhou_yiran":
			templates = [
				{"message": "今天排班表出来了", "time_slot": "morning"},
				{"message": "下班一起走", "time_slot": "evening"}
			]
		"shen_yingshuang":
			templates = [
				{"message": "今天模考怎么样", "time_slot": "afternoon"},
				{"message": "别学太晚", "time_slot": "evening"}
			]
	
	if templates.is_empty():
		return {}
	
	var template: Dictionary = templates[randi() % templates.size()]
	return {
		"role_id": role_id,
		"message": template["message"],
		"time_slot": template.get("time_slot", "evening"),
		"action_invite": template.get("action_invite", "")
	}

# ==================== 事件注入 ====================

func _get_injectable_event(role_id: String, day_index: int, phase: String, last_action: String) -> Dictionary:
	# 这里应该读取 love_events.json 中的事件数据
	# 简化版：返回空，实际事件由 JSON 文件驱动
	return {}

# ==================== 阶段推进 ====================

func _check_phase_advance(role_id: String) -> void:
	var data: Dictionary = _love_data[role_id]
	var current_phase: int = data["phase"]
	var spark: int = data["spark"]
	
	# 获取好感度（通过RelationshipManager）
	var affinity: int = _get_affinity(role_id)
	
	# 检查阶段推进条件
	match current_phase:
		LovePhase.MET:
			if affinity >= 20 and spark >= 15:
				_set_phase(role_id, LovePhase.FAMILIAR)
		
		LovePhase.FAMILIAR:
			if affinity >= 40 and spark >= 35:
				_set_phase(role_id, LovePhase.AMBIGUOUS)
		
		LovePhase.AMBIGUOUS:
			if affinity >= 55 and spark >= 70:
				_set_phase(role_id, LovePhase.CONFESSION)

func _set_phase(role_id: String, new_phase: int) -> void:
	var data: Dictionary = _love_data[role_id]
	var old_phase: int = data["phase"]
	data["phase"] = new_phase
	
	_log("%s 阶段变化: %s -> %s" % [role_id, PHASE_NAMES[old_phase], PHASE_NAMES[new_phase]])
	
	# 触发阶段变化事件
	if new_phase == LovePhase.DATING:
		data["together_day"] = _get_current_day()

# ==================== 初遇触发 ====================

func _try_trigger_first_meet(role_id: String, day_index: int) -> void:
	var data: Dictionary = _love_data[role_id]
	var interest_data: Dictionary = LOVE_INTERESTS[role_id]
	
	var probability: float = interest_data.get("meet_probability", 0.0)
	
	if randf() <= probability:
		data["phase"] = LovePhase.MET
		data["meet_day"] = day_index
		_log("触发初遇: %s" % role_id)
		
		# 触发初遇事件
		ModuleManager.request_event_trigger("love_first_meet_" + role_id, {"day": day_index})

# ==================== 自动表白场景 ====================

func _check_auto_confession(day_index: int) -> void:
	for role_id: String in _love_data.keys():
		var data: Dictionary = _love_data[role_id]
		
		if data["phase"] == LovePhase.CONFESSION:
			# 检查是否在冷却期
			if _confession_cooldown.has(role_id):
				continue
			
			# 触发表白场景事件
			ModuleManager.request_event_trigger("love_confession_scene_" + role_id, {})

# ==================== 消失感触发 ====================

func _trigger_drift_apart(role_id: String) -> void:
	var interest_data: Dictionary = LOVE_INTERESTS[role_id]
	_log("触发消失感: %s" % role_id)
	
	# 这里应该触发一个独白事件
	ModuleManager.request_event_trigger("love_drift_apart_" + role_id, {})

# ==================== 分手触发 ====================

func _trigger_breakup(role_id: String, reason: String) -> void:
	var data: Dictionary = _love_data[role_id]
	data["phase"] = LovePhase.BREAKUP
	data["breakup_count"] += 1
	
	_log("分手: %s, 原因: %s" % [role_id, reason])
	
	# 触发分手事件
	ModuleManager.request_event_trigger("love_breakup_" + role_id, {"reason": reason})

# ==================== 查询接口 ====================

## 获取角色恋爱数据
func get_love_data(role_id: String) -> Dictionary:
	if _love_data.has(role_id):
		return _love_data[role_id].duplicate()
	return {}

## 获取所有角色恋爱数据
func get_all_love_data() -> Dictionary:
	var result: Dictionary = {}
	for role_id: String in _love_data.keys():
		result[role_id] = _love_data[role_id].duplicate()
	return result

## 获取角色当前阶段
func get_love_phase(role_id: String) -> int:
	if _love_data.has(role_id):
		return _love_data[role_id]["phase"]
	return LovePhase.NOT_MET

## 获取角色阶段名称
func get_love_phase_name(role_id: String) -> String:
	var phase: int = get_love_phase(role_id)
	return PHASE_NAMES.get(phase, "未知")

## 获取角色心动值
func get_spark(role_id: String) -> int:
	if _love_data.has(role_id):
		return _love_data[role_id]["spark"]
	return 0

## 检查是否已遇见
func has_met(role_id: String) -> bool:
	return get_love_phase(role_id) > LovePhase.NOT_MET

## 检查是否在交往中
func is_dating(role_id: String) -> bool:
	var phase: int = get_love_phase(role_id)
	return phase == LovePhase.DATING or phase == LovePhase.STABLE

## 获取当前交往对象
func get_current_partner() -> String:
	for role_id: String in _love_data.keys():
		if is_dating(role_id):
			return role_id
	return ""

## 获取可攻略角色列表
func get_available_love_interests() -> Array[String]:
	return LOVE_INTERESTS.keys()

## 获取角色信息
func get_love_interest_info(role_id: String) -> Dictionary:
	return LOVE_INTERESTS.get(role_id, {}).duplicate()

# ==================== 内部工具 ====================

func _create_default_love_data(role_id: String) -> Dictionary:
	return {
		"role_id": role_id,
		"phase": LovePhase.NOT_MET,
		"spark": 0,
		"memory_points": [],
		"flags": {},
		"rejection_count": 0,
		"breakup_count": 0,
		"days_since_last_interact": 0,
		"conflict_meter": 0,
		"meet_day": -1,
		"together_day": -1,
		"story_progress": 0
	}

func _get_affinity(role_id: String) -> int:
	# 通过RelationshipManager获取好感度
	var state: Dictionary = ModuleManager.get_player_state()
	var relationships: Dictionary = state.get("relationships", {})
	if relationships.has(role_id):
		return relationships[role_id].get("affinity", 0)
	return 0

func _get_current_day() -> int:
	var state: Dictionary = ModuleManager.get_player_state()
	return state.get("day_index", 0)

# ==================== 序列化 ====================

func serialize() -> Dictionary:
	return {
		"love_data": _love_data.duplicate(true),
		"current_focus": _current_focus,
		"triggered_events": _triggered_love_events.duplicate(),
		"confession_cooldown": _confession_cooldown.duplicate()
	}

func deserialize(data: Dictionary) -> void:
	_love_data = data.get("love_data", {})
	_current_focus = data.get("current_focus", "")
	_triggered_love_events = data.get("triggered_events", [])
	_confession_cooldown = data.get("confession_cooldown", {})
	_log("恋爱数据已恢复")

func _log(message: String) -> void:
	print("[LoveModule] %s" % message)
