# LIFE 事件编辑器（EventEditorTool）

用于可视化编辑 `data/events.json` 的独立工具，适合策划或内容编辑人员快速维护事件数据。

## 功能概览

- 事件列表检索与筛选
- 新建/编辑/删除事件
- 选项分支编辑（属性变化、标签增减、提示文本）
- 保存回 `res://data/events.json`

## 启动方式

1. 在 Godot 中打开本项目
2. 打开 `EventEditorTool/scenes/EventEditor.tscn`
3. 运行当前场景（F6）

## 目录

- `scenes/EventEditor.tscn`：编辑器主界面
- `scenes/ChoiceEditor.tscn`：选项编辑组件
- `scripts/EventEditor.gd`：主逻辑
- `scripts/EventEditorEnhanced.gd`：增强逻辑
- `scripts/ChoiceEditor.gd`：选项组件逻辑
- `docs/`：工具文档

## 注意

- 保存后需要重新运行游戏场景，游戏才会读取新事件数据
- 建议在大改前备份 `data/events.json`
