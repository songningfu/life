# Godot 结构与 UI 结构说明

> 面向当前项目（`LIFE`）的 Godot 场景/脚本/UI 结构总览。

## 1. 项目入口与全局

- 项目名：`LIFE`
- 主场景：`res://scenes/studio_logo.tscn`
- Autoload（全局单例）：
  - `SaveManager`
  - `AudioManager`
  - `NamePool`
  - `ModuleManager`
  - `ModLoader`
  - `RelationshipManager`
  - `WechatSystem`

## 2. 场景层级（主干）

### 2.1 启动链路

1. `studio_logo.tscn`（`StudioLogo.gd`）
2. 进入 `main_menu.tscn`（`MainMenu.gd`）
3. 开新档后进入角色创建：`CharacterCreation.tscn`（`CharacterCreation.gd`）
4. 初始化完成进入主游戏：`Game.tscn`（`Game.gd`）

### 2.2 核心场景文件

- `scenes/studio_logo.tscn`：启动/工作室过场
- `scenes/main_menu.tscn`：主菜单 + 存档页 + 角色创建入口
- `scenes/CharacterCreation.tscn`：分页式创建角色流程（6页）
- `scenes/Game.tscn`：主玩法界面（状态栏 + 左主叙事 + 右数据面板）
- `scenes/PlayerInfoPanel.tscn`：游戏内人物档案覆盖层

## 3. 脚本结构（按职责）

### 3.1 根级核心脚本（`scripts/`）

- `Game.gd`：主循环、分阶段状态机、UI绑定、事件推进
- `MainMenu.gd`：主菜单逻辑、存档槽位、新档启动流程
- `CharacterCreation.gd`：角色创建 6 步流程、选项构建、样式控制
- `PlayerInfoPanel.gd`：人物档案面板展示与刷新
- `CampusMap.gd`：校园地图控件
- `PhoneSystem.gd` / `WechatSystem.gd`：手机与社交相关系统
- `SaveManager.gd`：存读档
- `AudioManager.gd`：BGM/音效
- `RelationshipManager.gd`：人际关系
- 其余：文本特效、命名池、工作室场景逻辑等

### 3.2 模块系统（`scripts/core/` + `scripts/modules/`）

- `core/`
  - `ModuleManager.gd`：模块生命周期与调度
  - `ModLoader.gd`：模块加载
  - `GameModule.gd`：模块基类/约定
  - `DataPackModule.gd`：数据包模块
- `modules/`
  - `LoveModule.gd`
  - `TalentModule.gd`

> `Game.gd` 与 `CharacterCreation.gd` 中都调用了 `ModuleManager.ensure_modules_loaded()`，说明模块为运行前置依赖。

## 4. UI 结构总览

## 4.1 主菜单 `main_menu.tscn`

- 根：`MainMenu (Control)`
- 全屏背景：`Background (ColorRect)`
- 中心内容：`Center/MainVBox`
  - 标题 `Title`（RichText）
  - 副标题 `Subtitle`
  - 按钮组：`NewBtn` / `ContinueBtn` / `QuitBtn`
- 弹层系统：
  - `Overlay`（遮罩）
  - `SavePanel`（存档槽位）
  - `CharPanel`（旧版快速建角面板）
- 加载页：`LoadPage`
  - `CardList`（动态存档卡片列表）
  - `LoadCardTemplate`（卡片模板）

UI 风格关键词：深色基底、蓝色强调、PanelContainer + StyleBoxFlat 为主。

## 4.2 角色创建 `CharacterCreation.tscn`

- 根：`CharacterCreation (Control)`
- 背景层：`Background`
- 分页容器：`PageContainer`
  - `Page1_Name`：姓名
  - `Page2_Gender`：性别
  - `Page3_Background`：家庭背景
  - `Page4_University`：院校选择
  - `Page5_Major`：专业选择（含分页器）
  - `Page6_Talent`：天赋抽取/确认

特征：
- 多页切换而非单页弹窗
- 数据驱动列表（背景、院校、专业）动态构建
- 统一按钮/输入框主题函数控制（脚本中 `_style_*` 系列）

## 4.3 主游戏 `Game.tscn`

根：`GameRoot (VBoxContainer)`，主要分三段：

1. `StatusBar`
   - 提示文本 `StatusHint`
   - 日进度条 `DayProgress`

2. `TimeControlBar`（时间与快捷操作）
   - 暂停/倍速：`PauseBtn` `Speed1xBtn` `Speed2xBtn` `Speed4xBtn`
   - 快捷入口：`PhoneBtn` `ProfileBtn`
   - 资源信息：生活费/GPA/学习/学分/日期

3. `MainHBox`
   - 左侧 `LeftPanel`（叙事与选择）
     - 当前阶段卡片 `CurrentCard`
     - 选项容器 `ChoicesContainer`
     - 日志文本 `EventText`
     - 下一步按钮 `NextButton`
   - 右侧 `RightPanel`（状态/地图）
     - `CampusMapPanel/CampusMap`
     - 多组属性行（GPA/社交/能力/金钱/心理/健康/标签等）

并且包含：
- `BackgroundWindow` + `SceneBackground` 背景层
- 大量 `StyleBoxFlat` 子资源定义视觉风格（圆角、半透明、描边、阴影）

## 4.4 人物档案层 `PlayerInfoPanel.tscn`

- 根：`PlayerInfoPanel (CanvasLayer)`（`layer=150`，覆盖主游戏）
- 结构：
  - 遮罩 `Overlay`
  - 主壳体 `Shell`
  - 顶部 `HeaderPanel`
  - 中部 `ScrollContainer`
    - `QuickStatsPanel`
    - 左列（基本信息/进度/天赋/标签）
    - 右列（剧情/学业/宿舍/关系/详细数据）

定位：信息密度较高的“二级信息界面”，用于深度查看角色状态。

## 5. 资源与数据结构

- 数据：`data/*.json`
  - `actions.json`（行动定义）
  - `events.json`（事件）
  - `love_events.json`、`love_interests.json`（恋爱相关）
  - `npc_behaviors.json`、`sendable_messages.json` 等
- 场景图像：`images/backgrounds/`、`images/phone_icons/`
- 音频：`audio/menu_bgm.mp3`、`audio/game_bgm.mp3`

## 6. 当前 UI 架构结论（简版）

- 架构模式：`场景分层 + Autoload全局 + 模块系统`
- UI 组织：
  - 主流程界面（菜单/建角/主游戏）与功能覆盖层（人物档案）分离
  - 主游戏采用“左叙事 + 右状态面板”双栏布局
  - 视觉上以深色、半透明卡片和蓝色强调统一风格
- 扩展点：
  - 通过 `ModuleManager + modules/` 扩展玩法
  - 通过 `data/*.json` 扩展行动与事件
