# 🎮 LIFE 游戏事件编辑器

> 独立的可视化事件编辑工具 - 无需代码知识即可创建游戏事件

## 📦 工具简介

这是一个为《大学四年（LIFE）》游戏开发的独立事件编辑器工具，可以让你在不懂代码的情况下轻松创建、修改和管理游戏事件。

## 🚀 快速开始

### 1. 安装使用

#### 方法A：在主项目中使用
1. 将 `EventEditorTool` 文件夹放在游戏项目根目录
2. 在 Godot 中打开 `EventEditorTool/scenes/EventEditor.tscn`
3. 按 F6 运行编辑器

#### 方法B：独立使用
1. 在 Godot 中创建新项目
2. 将 `EventEditorTool` 文件夹内容复制到新项目
3. 设置主场景为 `scenes/EventEditor.tscn`
4. 运行项目

### 2. 连接到游戏数据

编辑器会自动读取和保存到：
```
res://data/events.json
```

如果你的游戏数据在其他位置，需要修改脚本中的路径。

## 📁 文件结构

```
EventEditorTool/
├── scenes/              # 场景文件
│   ├── EventEditor.tscn      # 主编辑器界面
│   └── ChoiceEditor.tscn     # 选项编辑组件
├── scripts/             # 脚本文件
│   ├── EventEditor.gd        # 基础编辑器逻辑
│   ├── EventEditorEnhanced.gd # 增强版编辑器
│   └── ChoiceEditor.gd       # 选项编辑逻辑
├── docs/                # 文档
│   ├── 快速入门.md           # 5分钟上手指南
│   └── 使用说明.md           # 完整功能说明
└── README.md            # 本文件
```

## ✨ 核心功能

### 基础功能
- ✅ 创建新事件
- ✅ 编辑现有事件
- ✅ 删除事件
- ✅ 搜索和筛选
- ✅ 可视化编辑所有字段
- ✅ 动态添加/删除选项
- ✅ 属性效果设置
- ✅ 标签管理
- ✅ 自动保存备份

### 增强功能（使用 EventEditorEnhanced.gd）
- ✅ 事件模板
- ✅ 事件复制
- ✅ 实时验证
- ✅ 事件预览
- ✅ 标签帮助
- ✅ 状态提示

## 📖 文档

### 新手推荐
👉 **先看 `docs/快速入门.md`** - 5分钟学会创建事件

### 完整文档
📚 **查看 `docs/使用说明.md`** - 了解所有功能

## 🎯 使用示例

### 创建一个简单的日常事件

```
1. 点击"新建事件"
2. 填写信息：
   - 事件ID: daily_study_library
   - 标题: 图书馆学习
   - 类型: daily
   - 年级: 1-4
   - 描述: 你来到图书馆...
3. 添加选项：
   选项1: 认真学习
     学习: +10
     健康: -5
   选项2: 随便看看
     学习: +3
     社交: +5
4. 点击"应用修改"
5. 点击"保存到文件"
```

## 🔧 配置说明

### 修改数据路径

如果需要修改事件文件路径，编辑 `scripts/EventEditor.gd`：

```gdscript
func _load_events():
    var file_path = "res://data/events.json"  # 修改这里
    # ...
```

### 使用增强版编辑器

1. 打开 `scenes/EventEditor.tscn`
2. 选择根节点
3. 在检查器中将脚本改为 `EventEditorEnhanced.gd`
4. 保存场景

## 💡 使用技巧

1. **经常保存** - 编辑器会自动备份，但养成保存习惯更安全
2. **从简单开始** - 先创建简单的日常事件练手
3. **参考现有事件** - 查看 `data/events.json` 了解事件结构
4. **使用模板** - 增强版编辑器提供事件模板功能
5. **测试验证** - 使用验证功能检查事件是否有错误

## 🎨 支持的属性

### 玩家属性
- **学习点** (study_points): -50 到 +50
- **社交** (social): -50 到 +50
- **能力** (ability): -50 到 +50
- **生活费** (living_money): -500 到 +500 元
- **心理** (mental): -50 到 +50
- **健康** (health): -50 到 +50

### 标签系统
- 社团标签: debate_club, tech_club, student_union
- 关系标签: crush, in_relationship, broke_up
- 路线标签: want_postgrad, want_job, want_stable
- 成就标签: debate_winner, first_project, competition_exp

## ❓ 常见问题

### Q: 编辑器无法加载事件？
A: 检查 `data/events.json` 文件是否存在且格式正确。

### Q: 保存后游戏中看不到新事件？
A: 需要重新运行游戏场景以加载新数据。

### Q: 如何恢复误删的事件？
A: 查看 `data/` 文件夹中的备份文件（events_backup_时间戳.json）。

### Q: 可以在其他项目中使用吗？
A: 可以！只需修改数据文件路径即可适配其他项目。

## 🔄 版本信息

- **当前版本**: 1.0
- **适用游戏版本**: LIFE v5.1+
- **Godot 版本**: 4.6+
- **最后更新**: 2026/3/25

## 📝 更新日志

### v1.0 (2026/3/25)
- ✅ 初始版本发布
- ✅ 基础编辑功能
- ✅ 增强版编辑器
- ✅ 完整文档

## 🤝 贡献

欢迎提出改进建议和功能需求！

## 📄 许可

本工具与 LIFE 游戏项目使用相同的许可协议。

---

## 🎉 开始使用

1. 📖 阅读 `docs/快速入门.md`
2. 🚀 运行 `scenes/EventEditor.tscn`
3. ✨ 创建你的第一个事件
4. 🎮 在游戏中测试效果

**祝你创作愉快！**
