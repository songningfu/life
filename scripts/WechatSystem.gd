extends Node
# ══════════════════════════════════════════════
#          微信聊天系统
# ══════════════════════════════════════════════

# 消息结构: {sender: "npc"/"player", text: String, day: int}
# 对话结构: {role_id: String, messages: Array, pending_reply: Dictionary or null}

var conversations: Dictionary = {}  # role_id -> {messages, pending_reply, last_msg_day}

# ========== 消息模板 ==========
# key = role_id, value = Array of {条件, 消息, 回复选项}
var message_templates: Dictionary = {
	"roommate_gamer": [
		{
			"min_day": 3, "max_day": 30, "phase": "开学季",
			"text": "哥们，晚上开黑不？五排差一个人",
			"replies": [
				{"text": "来了来了！等我洗个澡", "effects": {"social": 3, "gpa": -1}, "affinity": 3,
				 "response": "好嘞！我先开一把等你"},
				{"text": "今天不了，我想复习一下", "effects": {"gpa": 2}, "affinity": -1,
				 "response": "行吧...卷王"},
				{"text": "看情况吧", "effects": {}, "affinity": 0,
				 "response": "那你快点决定啊"},
			]
		},
		{
			"min_day": 60, "max_day": 120, "phase": "日常",
			"text": "食堂新出了个炸鸡排，贼好吃，要不要带一份？",
			"replies": [
				{"text": "带带带！谢了兄弟", "effects": {"money": -2, "health": -1}, "affinity": 4,
				 "response": "没事，8块钱，回来给我就行"},
				{"text": "不用了，我减肥", "effects": {"health": 1}, "affinity": 0,
				 "response": "你那体型还减啥..."},
			]
		},
		{
			"min_day": 100, "max_day": 200,
			"text": "我挂了一门...怎么办啊",
			"replies": [
				{"text": "补考好好准备，我帮你划重点", "effects": {"social": 2}, "affinity": 5,
				 "response": "真的吗！太感谢了兄弟！"},
				{"text": "你天天打游戏能不挂吗", "effects": {}, "affinity": -3,
				 "response": "...你说的对，但是听着好难受"},
				{"text": "没事，大一挂科很正常", "effects": {}, "affinity": 1,
				 "response": "真的吗？那我稍微安心了一点"},
			]
		},
		{
			"min_day": 200, "max_day": 400,
			"text": "我发现了一个超好玩的新游戏，要不要一起？",
			"replies": [
				{"text": "什么游戏？发我看看", "effects": {"social": 2, "mental": 3}, "affinity": 3,
				 "response": "【链接】这个！评价超高的"},
				{"text": "最近忙，下次吧", "effects": {}, "affinity": 0,
				 "response": "好吧好吧，忙完叫我"},
			]
		},
		{
			"min_day": 350, "max_day": 600,
			"text": "你说我要不要也开始准备考研啊...",
			"replies": [
				{"text": "看你自己规划吧，想清楚最重要", "effects": {}, "affinity": 2,
				 "response": "唉，我也不知道自己想干嘛"},
				{"text": "以你的基础，好好准备应该可以", "effects": {"social": 1}, "affinity": 4,
				 "response": "谢谢你这么说，我认真想想"},
				{"text": "你先把游戏戒了再说", "effects": {}, "affinity": -2,
				 "response": "扎心了..."},
			]
		},
	],
	"roommate_studious": [
		{
			"min_day": 5, "max_day": 40, "phase": "开学季",
			"text": "明天早上图书馆一起自习吗？我占了两个位子",
			"replies": [
				{"text": "好的，几点？", "effects": {"gpa": 3}, "affinity": 4,
				 "response": "七点半，不要迟到哦"},
				{"text": "明天想睡懒觉...", "effects": {"mental": 2}, "affinity": -1,
				 "response": "好吧，那我把位子让给别人了"},
			]
		},
		{
			"min_day": 80, "max_day": 130,
			"text": "高数作业第三题你会吗？我算了两遍答案不一样",
			"replies": [
				{"text": "我看看...我算的是42", "effects": {"gpa": 2, "social": 1}, "affinity": 3,
				 "response": "对！我第二遍也是这个，谢了"},
				{"text": "我也不会，要不问问别人？", "effects": {"social": 1}, "affinity": 1,
				 "response": "行，我去问问课代表"},
				{"text": "我还没做...", "effects": {}, "affinity": 0,
				 "response": "...明天就交了啊"},
			]
		},
		{
			"min_day": 91, "max_day": 120, "phase": "复习考试",
			"text": "我整理了一份复习笔记，要不要发你一份？",
			"replies": [
				{"text": "要！太感谢了！", "effects": {"gpa": 5}, "affinity": 3,
				 "response": "【文件】给你，重点我标红了"},
				{"text": "不用了，我自己整理的差不多了", "effects": {"gpa": 1}, "affinity": 0,
				 "response": "厉害，那考试加油"},
			]
		},
		{
			"min_day": 300, "max_day": 500,
			"text": "竞赛报名开始了，要不要组队参加？",
			"replies": [
				{"text": "好啊！正好想试试", "effects": {"ability": 5, "social": 2}, "affinity": 5,
				 "response": "太好了！我已经开始看往年题了，周末讨论一下？",
				 "add_tags": ["competition_exp"]},
				{"text": "我怕自己水平不够...", "effects": {}, "affinity": 1,
				 "response": "没事，重在参与，对简历也有好处"},
				{"text": "没时间，最近太忙了", "effects": {}, "affinity": -1,
				 "response": "好吧，那我找别人了"},
			]
		},
	],
	"roommate_quiet": [
		{
			"min_day": 15, "max_day": 60,
			"text": "...",
			"replies": [
				{"text": "怎么了？", "effects": {}, "affinity": 2,
				 "response": "没什么。就是不小心点开了对话框"},
				{"text": "(不回复)", "effects": {}, "affinity": 0,
				 "response": ""},
			]
		},
		{
			"min_day": 80, "max_day": 200,
			"text": "你阳台上的衣服好像要被风吹走了",
			"replies": [
				{"text": "啊！谢谢提醒！", "effects": {}, "affinity": 3,
				 "response": "嗯"},
			]
		},
		{
			"min_day": 200, "max_day": 400,
			"text": "推荐你一部电影。《入殓师》",
			"replies": [
				{"text": "谢谢推荐，我今晚看看", "effects": {"mental": 3}, "affinity": 4,
				 "response": "看完可以聊聊感想"},
				{"text": "好的，收藏了", "effects": {}, "affinity": 1,
				 "response": "嗯"},
			]
		},
		{
			"min_day": 400, "max_day": 700,
			"text": "其实能和你们当室友挺好的",
			"replies": [
				{"text": "我也觉得，咱们宿舍氛围真不错", "effects": {"mental": 5, "social": 3}, "affinity": 6,
				 "response": "嗯...大学最好的回忆可能就是宿舍了"},
				{"text": "突然煽情了啊哈哈", "effects": {"social": 1}, "affinity": 2,
				 "response": "...就随便说说"},
			]
		},
	],
	"crush_target": [
		{
			"min_day": 30, "max_day": 100,
			"requires": ["crush"],
			"text": "同学你好，上次借的笔记我整理好了，怎么还你？",
			"replies": [
				{"text": "我去教室找你拿吧", "effects": {"social": 3}, "affinity": 4,
				 "response": "好的，我下午三点在3号教学楼"},
				{"text": "发电子版就行，谢谢", "effects": {}, "affinity": 1,
				 "response": "好的，稍等我拍一下"},
			]
		},
		{
			"min_day": 100, "max_day": 250,
			"requires": ["crush"],
			"text": "最近有一部电影好像挺好看的...",
			"replies": [
				{"text": "一起去看吗？我请你", "effects": {"money": -5, "social": 5}, "affinity": 8,
				 "response": "好呀！那周末？"},
				{"text": "是哪部？我也想看", "effects": {"social": 2}, "affinity": 3,
				 "response": "就是那个新上的，评分挺高的"},
				{"text": "最近没时间看电影", "effects": {}, "affinity": -1,
				 "response": "好吧~"},
			]
		},
		{
			"min_day": 250, "max_day": 500,
			"requires": ["crush"],
			"text": "今天天气好好，校园的樱花开了你看到了吗",
			"replies": [
				{"text": "看到了！特别美，拍了好多照片", "effects": {"mental": 3}, "affinity": 4,
				 "response": "发我看看！我下课没来得及去"},
				{"text": "没注意看，我一会去看看", "effects": {}, "affinity": 1,
				 "response": "快去！落花前的最后几天了"},
			]
		},
	],
	"debate_senior": [
		{
			"min_day": 20, "max_day": 80,
			"requires": ["debate_club"],
			"text": "这周的辩论赛选题出来了，你来参加吗？",
			"replies": [
				{"text": "来！我想试试", "effects": {"ability": 4, "social": 2}, "affinity": 5,
				 "response": "好，我发你资料，提前准备一下",
				 "add_tags": ["debate_winner"]},
				{"text": "我还不太有信心...", "effects": {}, "affinity": 1,
				 "response": "没事，先来观摩也行，下次再上场"},
			]
		},
		{
			"min_day": 150, "max_day": 350,
			"requires": ["debate_club"],
			"text": "学弟，社团下学期的部长选举，有没有兴趣竞选？",
			"replies": [
				{"text": "我考虑一下，谢谢学长推荐", "effects": {"ability": 3, "social": 3}, "affinity": 4,
				 "response": "你能力够了，好好准备"},
				{"text": "我觉得我还需要多锻炼", "effects": {}, "affinity": 2,
				 "response": "谦虚是好事，但别太低估自己"},
			]
		},
	],
	"tech_senior": [
		{
			"min_day": 20, "max_day": 80,
			"requires": ["tech_club"],
			"text": "有个小项目要人，你来不来？做个校园工具类App",
			"replies": [
				{"text": "来！正好想实践一下", "effects": {"ability": 6}, "affinity": 5,
				 "response": "行。周三晚上开会，先把Git装好",
				 "add_tags": ["first_project"]},
				{"text": "我基础太差了怕拖后腿", "effects": {}, "affinity": 1,
				 "response": "边做边学。新手都这样"},
			]
		},
		{
			"min_day": 200, "max_day": 400,
			"requires": ["tech_club"],
			"text": "有个大厂内推机会，你要不要试试？",
			"replies": [
				{"text": "要！麻烦学长了！", "effects": {"ability": 5, "social": 2}, "affinity": 6,
				 "response": "把简历发我，我帮你改改再投",
				 "add_tags": ["big_company_intern"]},
				{"text": "我觉得我还没准备好", "effects": {}, "affinity": 0,
				 "response": "那就继续练，机会以后还会有"},
			]
		},
	],
	"neighbor_classmate": [
		{
			"min_day": 10, "max_day": 60,
			"text": "嗨！你是隔壁班的吧？上次课上看你记笔记超认真的",
			"replies": [
				{"text": "哈哈谢谢！你也是", "effects": {"social": 3}, "affinity": 4,
				 "response": "下次能借我看看吗？有几个地方没听懂"},
				{"text": "还好啦", "effects": {}, "affinity": 1,
				 "response": "谦虚！"},
			]
		},
		{
			"min_day": 100, "max_day": 250,
			"text": "期末复习资料我整理了一份，要不要？",
			"replies": [
				{"text": "太好了！可以交换，我也整理了一些", "effects": {"gpa": 4, "social": 2}, "affinity": 5,
				 "response": "好呀！那我们图书馆见？"},
				{"text": "好的谢谢！", "effects": {"gpa": 3}, "affinity": 3,
				 "response": "不客气~考试加油"},
			]
		},
	],
	"union_minister": [
		{
			"min_day": 15, "max_day": 60,
			"requires": ["student_union"],
			"text": "下周有个活动需要人帮忙布置场地，周六上午有空吗？",
			"replies": [
				{"text": "有空，我来", "effects": {"ability": 2, "social": 3}, "affinity": 4,
				 "response": "好的，早上8点教活中心集合"},
				{"text": "周六有事去不了，抱歉", "effects": {}, "affinity": -2,
				 "response": "行吧"},
			]
		},
		{
			"min_day": 100, "max_day": 300,
			"requires": ["student_union"],
			"text": "这次拉赞助的任务交给你了，有信心吗？",
			"replies": [
				{"text": "没问题，我试试", "effects": {"ability": 4, "money": 3}, "affinity": 5,
				 "response": "好，我把联系方式发你",
				 "add_tags": ["sponsor_experience"]},
				{"text": "我没做过，能不能带我一次？", "effects": {"ability": 2}, "affinity": 2,
				 "response": "行，那你先跟我跑一家"},
			]
		},
	],
	"counselor": [
		{
			"min_day": 3, "max_day": 20,
			"text": "同学你好，开学适应情况怎么样？有什么问题随时找我",
			"replies": [
				{"text": "挺好的老师，谢谢关心", "effects": {"mental": 2}, "affinity": 2,
				 "response": "好的，有事随时联系我"},
				{"text": "还在适应中，有点想家", "effects": {"mental": 3}, "affinity": 3,
				 "response": "刚开学都这样，慢慢就好了。如果需要聊聊可以来办公室找我"},
			]
		},
		{
			"min_day": 100, "max_day": 300,
			"conditions": {"gpa": {"max": 40}},
			"text": "你最近成绩下滑比较多，方便来办公室聊一下吗？",
			"replies": [
				{"text": "好的老师，我这周去找您", "effects": {"gpa": 3, "mental": 2}, "affinity": 3,
				 "response": "好的，我周三下午有空，来之前先想想原因"},
				{"text": "最近有点忙，下周可以吗", "effects": {}, "affinity": 0,
				 "response": "行，但不要一直拖"},
			]
		},
	],
}

# ========== 消息队列 ==========
var pending_messages: Array = []  # 等待发送的消息
var message_cooldowns: Dictionary = {}  # role_id -> last_sent_day
var sent_template_keys: Array = []  # 已发送的模板标识

func _ready():
	pass

# ══════════════════════════════════════════════
#            初始化
# ══════════════════════════════════════════════
func init_conversations():
	conversations.clear()
	pending_messages.clear()
	message_cooldowns.clear()
	sent_template_keys.clear()

# ══════════════════════════════════════════════
#          每日检查（Game.gd 调用）
# ══════════════════════════════════════════════
func check_daily_messages(day_index: int, tags: Array, stats: Dictionary):
	for role_id in message_templates:
		# 冷却检查：同一个NPC至少间隔15天
		if role_id in message_cooldowns:
			if day_index - message_cooldowns[role_id] < 15:
				continue
		# 未认识的NPC不发消息
		if not RelationshipManager.is_met(role_id):
			continue
		# 遍历模板
		var templates = message_templates[role_id]
		for i in templates.size():
			var tmpl = templates[i]
			var key = "%s_%d" % [role_id, i]
			if key in sent_template_keys:
				continue
			if not _check_template_conditions(tmpl, day_index, tags, stats):
				continue
			# 概率触发：每天12%
			if randf() > 0.12:
				continue
			# 发送消息
			_send_npc_message(role_id, tmpl, key, day_index)
			break  # 每个NPC每天最多发一条

func _check_template_conditions(tmpl: Dictionary, day_index: int, tags: Array, stats: Dictionary) -> bool:
	if day_index < tmpl.get("min_day", 0):
		return false
	if day_index > tmpl.get("max_day", 9999):
		return false
	# phase 检查
	if tmpl.has("phase"):
		var phase = tmpl["phase"]
		# 简单匹配：当前阶段名是否包含关键词
		var game_node = get_tree().get_first_node_in_group("game")
		if game_node and game_node.has_method("get_date_info"):
			var info = game_node.get_date_info()
			if phase == "开学季" and "开学" not in info.phase and "军训" not in info.phase:
				return false
			elif phase == "日常" and "日常" not in info.phase:
				return false
			elif phase == "复习考试" and "复习" not in info.phase and "考试" not in info.phase:
				return false
	# requires 检查
	for tag in tmpl.get("requires", []):
		if tag not in tags:
			return false
	# conditions 检查（属性条件）
	var conditions = tmpl.get("conditions", {})
	for attr in conditions:
		var val = stats.get(attr, 50.0)
		var cond = conditions[attr]
		if cond.has("min") and val < float(cond["min"]):
			return false
		if cond.has("max") and val > float(cond["max"]):
			return false
	return true

func _send_npc_message(role_id: String, tmpl: Dictionary, key: String, day_index: int):
	# 初始化对话
	if role_id not in conversations:
		conversations[role_id] = {
			"messages": [],
			"pending_reply": null,
			"last_msg_day": -1,
		}
	# 替换名字
	var text = tmpl["text"]
	var conv = conversations[role_id]
	conv.messages.append({
		"sender": "npc",
		"text": text,
		"day": day_index,
	})
	conv.pending_reply = {
		"replies": tmpl.get("replies", []),
		"template_key": key,
	}
	conv.last_msg_day = day_index
	# 标记已发送
	sent_template_keys.append(key)
	message_cooldowns[role_id] = day_index
	# 设置未读
	if RelationshipManager.npc_data.has(role_id):
		RelationshipManager.npc_data[role_id].unread_messages += 1

# ══════════════════════════════════════════════
#         玩家回复（PhoneSystem 调用）
# ══════════════════════════════════════════════
func player_reply(role_id: String, reply_index: int, day_index: int) -> Dictionary:
	if role_id not in conversations:
		return {}
	var conv = conversations[role_id]
	if conv.pending_reply == null:
		return {}
	var replies = conv.pending_reply.get("replies", [])
	if reply_index < 0 or reply_index >= replies.size():
		return {}

	var reply = replies[reply_index]
	# 添加玩家消息
	conv.messages.append({
		"sender": "player",
		"text": reply["text"],
		"day": day_index,
	})
	# 添加NPC回复
	var response = reply.get("response", "")
	if response != "":
		conv.messages.append({
			"sender": "npc",
			"text": response,
			"day": day_index,
		})
	# 清除待回复
	conv.pending_reply = null
	# 清除未读
	if RelationshipManager.npc_data.has(role_id):
		RelationshipManager.npc_data[role_id].unread_messages = 0

	# 返回效果
	return {
		"effects": reply.get("effects", {}),
		"affinity": reply.get("affinity", 0),
		"add_tags": reply.get("add_tags", []),
		"response": response,
	}

# ══════════════════════════════════════════════
#         获取对话数据
# ══════════════════════════════════════════════
func get_conversation(role_id: String) -> Dictionary:
	if role_id in conversations:
		return conversations[role_id]
	return {"messages": [], "pending_reply": null, "last_msg_day": -1}

func has_unread(role_id: String) -> bool:
	if RelationshipManager.npc_data.has(role_id):
		return RelationshipManager.npc_data[role_id].get("unread_messages", 0) > 0
	return false

func get_total_unread() -> int:
	var total = 0
	for role_id in RelationshipManager.npc_data:
		total += RelationshipManager.npc_data[role_id].get("unread_messages", 0)
	return total

func get_active_conversations() -> Array:
	var result = []
	for role_id in conversations:
		if conversations[role_id].messages.size() > 0:
			result.append(role_id)
	# 按最近消息排序
	result.sort_custom(func(a, b):
		var day_a = conversations[a].get("last_msg_day", 0)
		var day_b = conversations[b].get("last_msg_day", 0)
		return day_a > day_b
	)
	return result

# ══════════════════════════════════════════════
#              序列化
# ══════════════════════════════════════════════
func serialize() -> Dictionary:
	return {
		"conversations": conversations.duplicate(true),
		"message_cooldowns": message_cooldowns.duplicate(),
		"sent_template_keys": sent_template_keys.duplicate(),
	}

func deserialize(data: Dictionary):
	conversations = data.get("conversations", {}).duplicate(true)
	message_cooldowns = data.get("message_cooldowns", {}).duplicate()
	sent_template_keys = data.get("sent_template_keys", []).duplicate()
