# 《三国麻将》Unity 长期开发指导总纲

## 1. 项目定位

《三国麻将》是一款面向 PC 平台的 Unity 单机原型项目，核心方向是“三国题材 + 麻将胡牌构筑 + Roguelike 路径与奖励 + 高动效爆分爽感”。

后续开发以 `unity_proto` 为主工程。Godot 与 Love2D 原型保留为历史实验线，仅作为参考，不再作为主线推进。

核心体验贯穿始终：

- 短期：爆分、弹字、震屏、连锁触发带来的即时爽感。
- 中期：通过锁牌、弃牌、牌型选择、奖励选择完成策略通关。
- 长期：构建牌库、功能牌、武将、武器印记和特殊胡牌体系的成就感。

参考方向：

- 玩法与动效重点借鉴 `Balatro_reference` 中 Balatro 的计分反馈、事件队列、卡牌手感、UI 反馈节奏和功能牌构筑。
- Roguelike 路径、随机奖励、随机惩罚、商店、限制条件和 Boss 节奏参考《杀戮尖塔》。
- 内部原型阶段允许高相似复刻 Balatro 的手感与节奏；Unity 实现必须使用原创 C#、原创资产和独立参数表。未来商业发布前再替换为更原创的视觉语言、参数和素材。

## 2. 每一步开发流程

任何新界面、新玩法、新系统都按以下流程推进：

1. **确定阶段目标**：先确认属于 `1.0` 到 `6.0` 的哪一阶段，禁止提前把后期系统混进当前核心验证。
2. **写清规则或界面意图**：规则先进入 Dev Tuning 表设计；界面先写出信息层级和资产清单。
3. **生成界面意向图**：每个界面先用 GPT Image 2.0 生成 16:9 完整原型图，确认布局、颜色、层级和气氛。
4. **拆解独立资产**：意向图确认后，拆出背景、Logo、按钮、面板、数字、文字、图标、牌、装饰、特效素材。
5. **拼装 Unity 场景**：按原图坐标和比例在 Unity 中重组，所有可交互元素和可变文字数字都必须是独立 GameObject。
6. **接入数据与动效**：规则走 Core/Run State，动效走 Juice/EventSequence，不把玩法逻辑写死在 UI 节点里。
7. **截图对比校准**：保存 Unity 截图，与意向图对比位置、比例、层级、颜色和可读性。
8. **补测试与调试表**：核心规则必须有 EditMode 测试；数值、公式、Buff 和动效强度必须能从 Dev Tuning 表调整。

每次迭代的完成标准：能运行、能编辑、能调参、能截图对比、不会破坏已有阶段目标。

## 3. Unity 主线架构

Unity 主工程：`unity_proto`

推荐分层：

- `Core Rules`：纯规则逻辑，包括牌池、手牌、锁牌、胡牌判定、计分公式。
- `Run State`：一局游戏的状态机，包括轮次、牌山、奖励、商店、路径、Boss。
- `UI Presentation`：Unity 场景、GameObject、按钮、文字、面板、卡牌显示。
- `Juice VFX`：所有动效、缓动、震屏、CRT、粒子、爆字、计分反馈。
- `Dev Tuning`：CSV/JSON 调试表，支持快速改公式、数值、Buff 和动效强度。
- `Prototype Reference`：研究 Balatro/杀戮尖塔的结构与反馈节奏，不作为运行时代码依赖。

核心类型命名：

- `TileDefinition`
- `TileInstance`
- `DeckState`
- `HandState`
- `LockState`
- `WinPatternMatcher`
- `BattleRoundState`
- `DevTuningTable`

动效类型命名：

- `JuiceProfile`
- `MoveTween`
- `CardHoverJuice`
- `ScoreBurstJuice`
- `ScreenShakeJuice`
- `CrtPostProcessJuice`
- `EventSequence`

美术管线命名：

- `ScreenPrototype`
- `AssetManifest`
- `LayerSpec`
- `UnitySceneAssembler`
- `ScreenshotComparator`

## 4. 版本路线图

### 1.0：7 轮内胡牌验证

目标：只验证 7 轮内能否达到胡牌状态，不考虑分数。

规则：

- 牌池 136 张。
- 每轮抓 5 张候选牌，弃 5 张。
- 玩家每轮最多自选锁牌 3 张。
- 手牌保持 14 张。
- 只判定常规胡：`4 面子 + 1 雀头`。
- 面子可以是顺子或刻子。

不做：

- 分数。
- 七对、十三幺。
- 花牌、季牌。
- 武将、武器、印记。
- 商店、路径、Boss。
- 副露、杠、额外奖励。

### 2.0：分数系统

目标：在 1.0 的牌局限制基础上加入分数。

新增：

- 基础分。
- 倍率。
- 完整胡牌扩展。
- 七小对、十三幺等特殊牌型逐步加入。

Dev Tuning：

- 将胡牌公式、基础分、倍率、牌型优先级加入调试表。

### 3.0：额外加分与牌型升级

目标：在分数基础上加入额外加分和牌型成长。

新增：

- 梅兰竹菊牌。
- 春夏秋冬牌。
- 将普通胡牌牌型升级为更高阶牌型的玩法。
- 牌面功能 Buff。

Dev Tuning：

- 将花牌、季牌、牌面功能 Buff 和牌型升级公式加入调试表。

### 4.0：三国特征 Buff

目标：将三国主题深度接入牌局构筑。

新增：

- 三国武将，定位类似功能小丑牌。
- 武将 Buff 作用于风牌、箭牌、梅兰竹菊、春夏秋冬。
- 武器与万/筒/索的印记附身功能。
- 基础牌属性增强。

Dev Tuning：

- 将武将触发条件、武器印记公式、升级数值和牌属性成长加入调试表。

### 5.0：商店

目标：加入局内经济与构筑选择。

新增：

- 购买新胡牌牌型。
- 购买牌型升级。
- 购买武器。
- 购买武将。
- 购买特殊牌库改造。

Dev Tuning：

- 将商店池、价格、稀有度、刷新规则、购买限制加入调试表。

### 6.0：Roguelike 路径与随机性

目标：加入完整 Run 的路径选择和随机事件结构。

新增：

- 路径节点。
- 随机奖励。
- 随机惩罚。
- 商店节点。
- 玩法限制节点。
- 大 Boss。
- 特殊事件。

Dev Tuning：

- 将地图节点池、奖励池、惩罚池、Boss 规则、路径权重和事件权重加入调试表。

## 5. 1.0 规则基线

### 牌池

总计 136 张：

| 类型 | 组成 | 数量 |
|---|---|---:|
| 数牌 | 万/筒/索 1-9，各 4 张 | 108 |
| 风牌 | 东南西北，各 4 张 | 16 |
| 箭牌 | 中发白，各 4 张 | 12 |

### 手牌与轮次

- 初始手牌 14 张。
- 一局最多 7 轮。
- 每轮展示 5 张候选牌。
- 玩家弃 5 张后手牌仍保持 14 张。
- 每轮结算后检测是否胡牌。

### 锁牌

- 每轮最多锁 3 张。
- 锁牌本轮不能被弃。
- 锁牌仅影响当前轮，不默认永久锁定。

### 胡牌

只支持传统常规胡：

```text
4 面子 + 1 雀头
```

面子定义：

- 顺子：同花色连续三张，例如 `三万 四万 五万`。
- 刻子：三张相同牌，例如 `东 东 东`。

雀头定义：

- 两张相同牌，例如 `白 白`。

## 6. 美术方向

整体风格：

- 细致像素风。
- 华丽三国幻想。
- 高动效爽感。
- 暗金、翡翠、漆木、火光、战旗、龙纹、铜钱、玉玺、兵符。
- CRT 扫描线、暗角、色差、发光边缘、粒子火星。

关键词：

```text
detailed pixel art
ornate Three Kingdoms fantasy
dark lacquered wood
jade glow
copper gold trim
CRT scanlines
high contrast
luxury UI frame
explosive card game feedback
```

视觉要求：

- 像素颗粒清晰，不糊不拉伸。
- 核心文字可读。
- 麻将牌面符号醒目。
- 背景华丽但不能压过交互元素。
- 所有数字、按钮、可变文字、牌、图标都必须可单独修改。

## 7. GPT Image 2.0 原型图与拆图流程

每个界面必须先完成原型图，再拆资产，再拼 Unity。

### 7.1 原型图

每个界面先生成一张完整 16:9 意向图，目标包含：

- 最终布局。
- 颜色和光源。
- UI 层级。
- 装饰物。
- 按钮。
- 面板。
- 牌区。
- 文字占位。
- 特效气氛。

原型图命名：

```text
Prototype_<Screen>_v001.png
```

### 7.2 资产拆解

意向图确认后拆解为：

- 背景。
- Logo。
- 按钮。
- 面板。
- 数字。
- 文字。
- 图标。
- 卡牌/麻将牌。
- 装饰物。
- 特效素材。

资产命名：

```text
UI_<Screen>_<Element>_v001.png
```

绿幕源文件、透明成品、Unity 场景、对比截图分目录保存。

推荐目录：

```text
unity_proto/Assets/SangokuMahjong/Art/<Screen>/Prototypes
unity_proto/Assets/SangokuMahjong/Art/<Screen>/GreenScreen
unity_proto/Assets/SangokuMahjong/Art/<Screen>/Sprites
unity_proto/Assets/SangokuMahjong/Art/<Screen>/Comparison
unity_proto/Assets/SangokuMahjong/Data/AssetManifests
```

### 7.3 Unity 拼装

Unity 拼装要求：

- 按意向图坐标还原。
- 使用统一 16:9 坐标基准。
- 固定 PPU。
- Point Filter。
- 无压缩导入。
- 每个元素独立 GameObject。
- 可交互元素必须有稳定英文节点名。
- 可变文字与数字必须使用文本组件，不烘焙进背景。

每个界面保存：

- `prototype_image`
- `asset_manifest`
- `unity_scene`
- `comparison_screenshot`

## 8. 主要界面资产框架

### MainMenu

用途：标题、开始游戏、收藏、设置、退出。

核心资产：

- `UI_MainMenu_Background_v001.png`
- `UI_MainMenu_Logo_v001.png`
- `UI_MainMenu_ButtonStartRun_v001.png`
- `UI_MainMenu_ButtonCollection_v001.png`
- `UI_MainMenu_ButtonOptions_v001.png`
- `UI_MainMenu_ButtonQuit_v001.png`
- `UI_MainMenu_PanelHighestScore_v001.png`
- `UI_MainMenu_PanelBonusMultiplier_v001.png`
- `UI_MainMenu_DecorDragonLeft_v001.png`
- `UI_MainMenu_DecorLanternRight_v001.png`
- `UI_MainMenu_DecorCoins_v001.png`
- `UI_MainMenu_TileWan_v001.png`
- `UI_MainMenu_TileFa_v001.png`
- `UI_MainMenu_TileDong_v001.png`

### Battle

用途：核心胡牌与计分界面。

核心资产：

- `UI_Battle_Background_v001.png`
- `UI_Battle_TopHudFrame_v001.png`
- `UI_Battle_RoundBadge_v001.png`
- `UI_Battle_ScoreBadge_v001.png`
- `UI_Battle_TargetBadge_v001.png`
- `UI_Battle_PlayAreaFrame_v001.png`
- `UI_Battle_HandTray_v001.png`
- `UI_Battle_TileCardBase_v001.png`
- `UI_Battle_TileSelectedGlow_v001.png`
- `UI_Battle_ScorePreviewPanel_v001.png`
- `UI_Battle_ButtonPlaySet_v001.png`
- `UI_Battle_ScoreBurstFrame_v001.png`
- `UI_Battle_MultiplierBurstFrame_v001.png`

### Reward

用途：战斗后选择奖励。

核心资产：

- `UI_Reward_Background_v001.png`
- `UI_Reward_TitleFrame_v001.png`
- `UI_Reward_ChoiceCardBase_v001.png`
- `UI_Reward_ButtonConfirm_v001.png`
- `UI_Reward_RarityGlowCommon_v001.png`
- `UI_Reward_RarityGlowRare_v001.png`
- `UI_Reward_RarityGlowLegendary_v001.png`

### Shop

用途：购买牌型、升级、武器、武将。

核心资产：

- `UI_Shop_Background_v001.png`
- `UI_Shop_MerchantFrame_v001.png`
- `UI_Shop_ItemCardBase_v001.png`
- `UI_Shop_ButtonBuy_v001.png`
- `UI_Shop_ButtonReroll_v001.png`
- `UI_Shop_CurrencyPanel_v001.png`
- `UI_Shop_ExitButton_v001.png`

### Map

用途：Roguelike 路径选择。

核心资产：

- `UI_Map_Background_v001.png`
- `UI_Map_PathLine_v001.png`
- `UI_Map_NodeBattle_v001.png`
- `UI_Map_NodeReward_v001.png`
- `UI_Map_NodeShop_v001.png`
- `UI_Map_NodeEvent_v001.png`
- `UI_Map_NodeBoss_v001.png`
- `UI_Map_PlayerMarker_v001.png`

### Boss

用途：Boss 关卡与限制规则展示。

核心资产：

- `UI_Boss_Background_v001.png`
- `UI_Boss_Banner_v001.png`
- `UI_Boss_RulePanel_v001.png`
- `UI_Boss_ThreatFrame_v001.png`
- `UI_Boss_ButtonBegin_v001.png`

### DevLab

用途：调试规则、公式、Buff、动效强度。

核心资产：

- `UI_DevLab_Background_v001.png`
- `UI_DevLab_TablePanel_v001.png`
- `UI_DevLab_SliderFrame_v001.png`
- `UI_DevLab_ToggleFrame_v001.png`
- `UI_DevLab_ButtonApply_v001.png`
- `UI_DevLab_ButtonReloadTables_v001.png`

## 9. Dev Tuning 表

Dev Tuning 表采用 CSV 或 JSON。第一批表：

- `tile_pool`
- `round_rules`
- `win_patterns`
- `juice_profile`

后续扩展表：

- `score_rules`
- `tile_buffs`
- `flower_season_rules`
- `general_buffs`
- `weapon_marks`
- `shop_pool`
- `map_nodes`
- `boss_rules`

要求：

- 策划可直接改表。
- 运行时可重新加载。
- 表内字段名稳定。
- 数值默认值写在表内，不散落在脚本中。
- 每个新增系统必须说明对应 Dev Tuning 表。

## 10. Balatro-like 动效规则

所有动效走事件队列，不直接瞬间结算。

必须分段播放：

1. 选牌。
2. 出牌。
3. 识别牌型。
4. 基础分。
5. 倍率。
6. Buff。
7. 总分增加。
8. 爆字与震屏。

卡牌手感：

- 每张牌具备独立 Transform。
- 目标位置 `TargetTransform` 与显示位置 `VisualTransform` 分离。
- 显示位置用缓动追随目标位置。
- Hover 放大、倾斜、发光。
- 点击压缩。
- 释放回弹。
- 选中上浮。

计分反馈：

- 大字牌型。
- 逐项弹分。
- 倍率脉冲。
- 短暂停顿。
- 屏幕震动。
- 粒子爆发。
- 音效触发点。

CRT 原型层：

- 扫描线。
- 暗角。
- 轻微色差。
- 背景流动。
- 噪声闪烁。
- 可通过 `juice_profile` 开关。

## 11. 测试标准

### 文档检查

- 路线图 `1.0` 到 `6.0` 完整。
- Unity 主线明确。
- 资产命名覆盖关键界面。
- 原型图流程、拆图流程和动效规则完整。

### Unity EditMode 测试

- 136 张牌池数量与分类正确。
- 常规胡 `4 面子 + 雀头` 可识别。
- 每轮抓 5 弃 5后手牌保持 14 张。
- 锁牌最多 3 张且不能被弃。
- 固定种子牌山可在 7 轮内完成一次胡牌。

### 美术还原测试

- 每个界面存在原型图、资产清单、Unity 场景和对比截图。
- Unity 截图与原型图在布局、比例、层级上保持高度一致。
- 所有可交互元素和可变文字数字都是独立 GameObject。

### 动效测试

- 选牌有 hover、上浮、倾斜、发光。
- 出牌进入事件队列。
- 牌型、基础分、倍率、Buff、总分按顺序分段播放。
- Score Burst、Screen Shake、CRT 层可通过 `juice_profile` 开关和调参。

### 资产管线测试

- 每个界面资产名在 manifest 中存在。
- Sprite 导入为 Point Filter。
- Sprite 无压缩。
- Sprite 使用固定 PPU。
- 可交互元素在 Unity 中是独立 GameObject。

## 12. 默认约定

- 游戏内 UI 默认英文。
- 麻将牌面允许中文符号，例如 `万`、`筒`、`索`、`东南西北`、`中发白`。
- 计划文件本身使用中文。
- 每个界面必须先做 GPT Image 2.0 意向原型图，再拆资产并拼进 Unity。
- 未来商业发布前必须重新检查版权、素材、字体、音效和可识别参考问题。
