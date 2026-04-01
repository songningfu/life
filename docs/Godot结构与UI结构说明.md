# Godot 结构与 UI 结构说明

> 适用版本：当前仓库（Godot 4.6）  
> 文档目的：建立“场景结构 + 脚本职责 + 数据驱动 + 模块体系 + 插件接入”的统一认知。  
> 推荐搭配：先读 `docs/README.md`，再读本文。

---

## 1. 项目架构总览

项目整体是“**场景层 + 逻辑层 + 数据层 + 插件层**”四层协同：

1. 场景层（`scenes/`）
   - 定义页面结构、节点层级、视觉布局
2. 逻辑层（`scripts/`）
   - 负责状态机、交互处理、渲染刷新
3. 数据层（`data/*.json`）
   - 配置行动、事件、恋爱、消息、成就定义
4. 插件层（`addons/`）
   - 提供通知系统、场景过渡、剧情编辑能力

跨场景共享通过 Autoload 单例实现，Game 主场景只做“调度与显示”，核心状态由系统模块维护。

---

## 2. 启动链路与页面职责

### 2.1 启动顺序

1. `scenes/studio_logo.tscn`（启动页）
2. `scenes/main_menu.tscn`（主菜单 / 新游戏 / 继续）
3. `scenes/CharacterCreation.tscn`（角色创建）
4. `scenes/Game.tscn`（主循环玩法）

### 2.2 场景切换机制

当前统一由：

- `scripts/utils/SceneTransitions.gd`（语义封装）
- `addons/scene_manager`（实际过渡执行）

即业务脚本不再直接硬切，而是调用：

- `logo_to_menu()`
- `menu_to_creation()`
- `creation_to_game()`
- `back_to_menu()`
- `day_transition()`（仅过渡不切场景）

---

## 3. 全局单例（Autoload）

当前项目核心 Autoload：

- `SaveManager`：存档管理
- `AudioManager`：音频管理
- `Notify`：统一 toast / 警告 / 成就提示
- `SceneTransitions`：业务层场景过渡封装
- `NamePool`：名字池
- `ModuleManager`：模块生命周期广播与聚合
- `ModLoader`：模块加载器
- `RelationshipManager`：关系与好感
- `WechatSystem`：聊天与消息系统
- `ToastParty`：toast 插件 autoload
- `SceneManager`：过渡插件 autoload

---

## 4. 脚本分层与职责

### 4.1 主流程脚本

- `scripts/MainMenu.gd`
  - 主菜单 UI 与存档入口
  - 新游戏/读档跳转链路
- `scripts/CharacterCreation.gd`
  - 六步建角流程
  - 角色初始数据组装并写入临时初始化缓存
- `scripts/Game.gd`
  - 日循环状态机
  - 行动与事件处理
  - 主界面刷新
  - 结局计算 + 成就模块结算回调

### 4.2 游戏系统脚本

- `scripts/PhoneSystem.gd`：手机面板动态 UI
- `scripts/PlayerInfoPanel.gd`：档案页渲染与统计
- `scripts/SaveManager.gd`：存档序列化入口
- `scripts/RelationshipManager.gd`：关系数据管理
- `scripts/WechatSystem.gd`：聊天记录与消息机制

### 4.3 模块系统（可扩展）

- `scripts/core/GameModule.gd`：模块接口基类
- `scripts/core/ModuleManager.gd`：统一广播（day/action/semester 等）
- `scripts/core/ModLoader.gd`：加载内置模块和外部模组

当前内置模块：

- `TalentModule.gd`
- `LoveModule.gd`
- `AchievementModule.gd`

---

## 5. 主要 UI 结构（按页面）

## 5.1 主菜单 `main_menu.tscn`

结构核心：

- `MainMenu (Control)`
  - `Background`
  - `Center/MainVBox`（标题与主按钮）
  - `Overlay`
  - `SavePanel`
  - `CharPanel`
  - `LoadPage`（卡片化读档区）

职责：入口页 + 存档流转。

---

## 5.2 角色创建 `CharacterCreation.tscn`

结构核心：

- `PageContainer`
  - `Page1_Name`
  - `Page2_Gender`
  - `Page3_Background`
  - `Page4_University`
  - `Page5_Major`
  - `Page6_Talent`
- `ProgressIndicator`

职责：收集初始角色条件，生成开局 init 数据。

---

## 5.3 主游戏 `Game.tscn`

结构核心：

- 顶栏：状态、时间控制、快捷入口
- 左栏：当前阶段叙事 + 选择按钮 + 日志
- 右栏：属性与信息面板

职责：主玩法承载页（行动 → 反馈 → 状态变化）。

---

## 5.4 档案页 `PlayerInfoPanel.tscn`

作为 `CanvasLayer` 覆盖面板，当前右列已包含：

- `StoryPanel`
- `AcademicPanel`
- `AchievementPanel`（新增）
- `DormPanel`
- `RelationshipsPanel`
- `DataPanel`

其中成就区显示：

- 完成度（已解锁数 / 总数）
- 单项成就状态与进度
- 列表排序：未解锁优先

---

## 6. 数据驱动关系

关键数据文件：

- `data/actions.json`：行动定义
- `data/events.json` / `data/flavor_texts.json`：事件池
- `data/love_*.json`：恋爱系统配置
- `data/sendable_messages.json` / `data/npc_behaviors.json`：社交消息
- `data/achievements.json`：成就定义（28项）

运行时模式：

- Game + ModuleManager 聚合静态配置与动态模块数据
- UI 层只读状态并渲染，不直接保存业务状态

---

## 7. 插件接入说明

当前已接入插件：

1. `toastparty`
   - 用于通知气泡
   - 通过 `Notify` 统一调用
2. `scene_manager`
   - 提供过渡 shader/pattern
   - 由 `SceneTransitions` 封装业务入口
3. `dialogic`
   - 已规范安装到 `addons/dialogic`
   - 当前项目可用，但是否深入使用由剧情系统演进决定

---

## 8. 故障定位建议

1. 场景打不开 / 报切换错：
   - 先查 `SceneTransitions.gd` 场景映射
   - 再查 `project.godot` 中 `SceneManager` 是否可用

2. 成就不解锁：
   - 查 `AchievementModule` 是否已在 `ModLoader` 注册
   - 查 `data/achievements.json` 定义字段
   - 查档案页成就区是否读到 overview

3. 档案页显示不完整：
   - 查 `PlayerInfoPanel.tscn` 节点是否存在
   - 查 `PlayerInfoPanel.gd` 对应 onready 路径

4. 插件类解析报错（如 Dialogic）：
   - 优先确认插件路径必须在 `res://addons/<plugin_name>/`
   - 避免把插件源码包直接放在临时目录下被工程扫描

---

## 9. 后续建议

1. 在文档层建立“版本化架构快照”（每次大改后更新）
2. 为成就系统补一份独立说明（规则、阈值、调参方法）
3. 给 `SceneTransitions` 补转场参数约定表（颜色/速度/pattern）
4. 把 `Dialogic` 使用边界写清楚（是否与现有事件系统并行）
