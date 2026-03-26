extends Node
# ══════════════════════════════════════════════
#              NPC 姓名池
# ══════════════════════════════════════════════

var surnames: Array = [
	"张", "李", "王", "刘", "陈", "杨", "赵", "黄", "周", "吴",
	"徐", "孙", "胡", "朱", "高", "林", "何", "郭", "马", "罗",
	"梁", "宋", "郑", "谢", "韩", "唐", "冯", "于", "董", "萧",
	"程", "曹", "袁", "邓", "许", "傅", "沈", "曾", "彭", "吕",
	"苏", "卢", "蒋", "蔡", "贾", "丁", "魏", "薛", "叶", "阎",
	"余", "潘", "杜", "戴", "夏", "钟", "汪", "田", "任", "姜",
	"范", "方", "石", "姚", "谭", "廖", "邹", "熊", "金", "陆",
	"郝", "孔", "白", "崔", "康", "毛", "邱", "秦", "江", "史",
	"顾", "侯", "邵", "孟", "龙", "万", "段", "雷", "钱", "严",
]

var male_given_names: Array = [
	"磊", "涛", "鹏", "翔", "宇", "杰", "浩", "强", "军", "明",
	"亮", "伟", "刚", "勇", "峰", "超", "波", "辉", "斌", "飞",
	"健", "凯", "毅", "昊", "睿", "旭", "晨", "霖", "坤", "博",
	"志远", "天宇", "浩然", "子轩", "俊杰", "文博", "思远", "嘉伟",
	"明辉", "泽宇", "晨曦", "一帆", "家豪", "海洋", "建国", "国栋",
	"伟东", "志强", "鸿飞", "彦祖", "子墨", "逸飞", "皓轩", "宇航",
	"佳明", "立恒", "铭泽", "启航", "书豪", "振华", "承泽", "锦程",
	"若谦", "清扬", "文昊", "景行", "远山", "星辰", "雨泽", "慕白",
]

var female_given_names: Array = [
	"静", "婷", "敏", "雪", "琳", "颖", "萱", "瑶", "洁", "璐",
	"莹", "蕊", "岚", "薇", "瑾", "珊", "霏", "悦", "彤", "萌",
	"思琪", "雨晴", "梦瑶", "欣怡", "紫萱", "诗涵", "佳琪", "雅婷",
	"若兰", "梓萱", "晓月", "雪莲", "文静", "慧敏", "小雨", "梦洁",
	"芷若", "清歌", "念安", "书瑶", "语嫣", "沐晴", "安然", "初夏",
	"锦书", "如意", "千寻", "怀瑾", "映雪", "听雨", "凝香", "落薇",
]

var _assigned_names: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _used_full_names: Array = []

func init_new_game(seed_value: int = -1):
	_assigned_names.clear()
	_used_full_names.clear()
	if seed_value < 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value

func generate_name(gender: String = "male") -> Dictionary:
	var name_data = _generate_name_data(gender, true)
	return name_data

func preview_name(gender: String = "male") -> Dictionary:
	return _generate_name_data(gender, false)

func _generate_name_data(gender: String, reserve: bool) -> Dictionary:
	var pool = male_given_names if gender == "male" else female_given_names
	var attempts = 0
	var full_name = ""
	var sur = ""
	var given = ""

	while attempts < 200:
		sur = surnames[_rng.randi() % surnames.size()]
		given = pool[_rng.randi() % pool.size()]
		full_name = sur + given
		if (not reserve) or full_name not in _used_full_names:
			break
		attempts += 1

	if reserve:
		_used_full_names.append(full_name)
	var nickname = _make_nickname(sur, given, gender)

	return {
		"full_name": full_name,
		"surname": sur,
		"given": given,
		"gender": gender,
		"nickname": nickname,
	}

func assign_name(role_id: String, gender: String = "male") -> Dictionary:
	if _assigned_names.has(role_id):
		return _assigned_names[role_id]
	var name_data = generate_name(gender)
	name_data["role_id"] = role_id
	_assigned_names[role_id] = name_data
	return name_data

func assign_existing_name(role_id: String, name_data: Dictionary) -> Dictionary:
	var assigned = name_data.duplicate(true)
	assigned["role_id"] = role_id
	_assigned_names[role_id] = assigned
	var full_name = str(assigned.get("full_name", ""))
	if full_name != "" and full_name not in _used_full_names:
		_used_full_names.append(full_name)
	return assigned

func get_npc_name(role_id: String) -> Dictionary:
	if _assigned_names.has(role_id):
		return _assigned_names[role_id]
	return {}

func get_nickname(role_id: String) -> String:
	if _assigned_names.has(role_id):
		return _assigned_names[role_id].nickname
	return "未命名"

func get_full_name(role_id: String) -> String:
	if _assigned_names.has(role_id):
		return _assigned_names[role_id].full_name
	return "未命名"

func _make_nickname(sur: String, given: String, _gender: String) -> String:
	var roll = _rng.randi() % 100
	if given.length() == 1:
		if roll < 50:
			return "小" + sur
		else:
			return "阿" + given
	else:
		var first_char = given[0]
		var last_char = given[given.length() - 1]
		if roll < 30:
			return "小" + first_char
		elif roll < 55:
			return "阿" + first_char
		elif roll < 80:
			return sur + last_char
		else:
			return "小" + sur

func serialize() -> Dictionary:
	return {
		"assigned_names": _assigned_names.duplicate(true),
		"used_full_names": _used_full_names.duplicate(),
		"rng_state": _rng.state,
		"rng_seed": _rng.seed,
	}

func deserialize(data: Dictionary):
	_assigned_names = data.get("assigned_names", {})
	_used_full_names = data.get("used_full_names", [])
	if data.has("rng_state"):
		_rng.state = data["rng_state"]
	if data.has("rng_seed"):
		_rng.seed = data["rng_seed"]
