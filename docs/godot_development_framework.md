# 《三国麻将》Godot 长期开发指导总纲

## 1. 项目定位

《三国麻将》是一款面向 PC 平台的 Godot 单机原型项目，核心方向是“三国题材 + 武将对战麻将 + Roguelike 路径与奖励 + 高动效爆发爽感”。

后续开发以当前 Godot 工程根目录为主工程。Love2D 原型保留为历史实验线，仅作为参考，不再作为主线推进。

核心体验贯穿始终：

- 短期：爆分、弹字、震屏、连锁触发带来的即时爽感。
- 中期：通过出牌、弃牌、胡牌大招、奖励选择完成策略通关。
- 长期：构建牌库、功能牌、武将、武器印记和特殊胡牌体系的成就感。

参考方向：

- 玩法与动效重点借鉴外部参考目录 `/Users/frankfan/Desktop/Project/Balatro_src` 中 Balatro 的计分反馈、事件队列、卡牌手感、UI 反馈节奏和功能牌构筑。
- Roguelike 路径、随机奖励、随机惩罚、商店、限制条件和 Boss 节奏参考《杀戮尖塔》。
- 内部原型阶段允许高相似复刻 Balatro 的手感与节奏；Godot 实现必须使用原创 GDScript、原创资产和独立参数表。未来商业发布前再替换为更原创的视觉语言、参数和素材。

## 2. 每一步开发流程

任何新界面、新玩法、新系统都按以下流程推进：

1. **确定阶段目标**：先确认属于 `1.0` 到 `6.0` 的哪一阶段，禁止提前把后期系统混进当前核心验证。
2. **写清规则或界面意图**：规则先进入 Dev Tuning 表设计；界面先写出信息层级和资产清单。
3. **生成界面意向图**：每个界面先用 GPT Image 2.0 生成 16:9 完整原型图，确认布局、颜色、层级和气氛。
4. **拆解独立资产**：意向图确认后，拆出背景、Logo、按钮、面板、数字、文字、图标、牌、装饰、特效素材。
5. **拼装 Godot 场景**：按原图坐标和比例在 Godot 中重组，所有可交互元素和可变文字数字都必须是独立 Node。
6. **接入数据与动效**：规则走 Core/Run State，动效走 Juice/EventSequence，不把玩法逻辑写死在 UI 节点里。
7. **截图对比校准**：保存 Godot 截图，与意向图对比位置、比例、层级、颜色和可读性。
8. **补测试与调试表**：核心规则必须有 GUT 测试；数值、公式、Buff 和动效强度必须能从 Dev Tuning 表调整。

每次迭代的完成标准：能运行、能编辑、能调参、能截图对比、不会破坏已有阶段目标。

## 3. Godot 主线架构

Godot 主工程：当前仓库根目录的 `project.godot`

推荐分层：

- `Core Rules`：纯规则逻辑，包括牌池、手牌、刻子/顺子/对子+单张/散牌识别、胡牌判定、战斗收益和大招公式。
- `Run State`：一局游戏的状态机，包括轮次、牌山、敌方武将、奖励、商店、路径、Boss。
- `UI Presentation`：Godot 场景、Node、按钮、文字、面板、卡牌显示。
- `Juice VFX`：所有动效、缓动、震屏、CRT、粒子、爆字、计分反馈。
- `Dev Tuning`：CSV/JSON 调试表，支持快速改公式、数值、Buff 和动效强度。
- `Prototype Reference`：研究 Balatro/杀戮尖塔的结构与反馈节奏，不作为运行时代码依赖。

核心类型命名：

- `TileDefinition`
- `TileInstance`
- `DeckState`
- `HandState`
- `WinPatternMatcher`
- `MeldPlay`
- `OpenMeldLedger`
- `ConcealedMeldCandidate`
- `PairCandidate`
- `ShantenState`
- `CombatStats`
- `EnemyWarlordDefinition`
- `DuelBattleState`
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
- `GodotSceneAssembler`
- `ScreenshotComparator`

2.5D 麻将牌管线：

- Battle 中的麻将牌默认使用 Godot 3D 牌体显示，详见 `docs/mahjong_3d_tile_pipeline.md`。
- 3D 牌体由 `BoxMesh + QuadMesh + Label3D/Sprite3D` 组成，当前先用程序材质和中文 `Label3D` 占位。
- 后续 Image 2.0 只生成 34 种正面牌面贴图，不生成 136 张独立牌图。
- 136 张实际牌继续由数据实例生成，牌体和贴图可复用。
- Battle 整体风格定为 2.5D：HUD/面板保持 2D 清晰，手牌、抓牌、出牌、大招回放使用 3D 悬浮表现。

## 4. 版本路线图

### 1.0：武将对战核心 Demo

目标：做出可玩的单场武将对战。玩家每回合可打出 1-3 张，打出几张，下一轮就抓几张补回手牌；通过单牌、对子、顺子、刻子、对子+单张、散牌触发战斗效果，并用明组、暗组和将牌组成胡牌大招。

规则：

- 牌池 136 张。
- 起手摸 16 张，玩家选择 13 张作为初始手牌，剩余 3 张弃置。
- 手牌上限 13 张。
- 无锁牌。
- 每回合玩家选择 1-3 张打出。
- 打出几张，下一轮从牌库摸几张并补回手牌。
- 打出的牌按优先级判定：刻子 > 顺子 > 对子+单张 > 对子 > 单牌 > 散牌。
- 顺子和刻子进入 `OpenMeldLedger` 明组区。
- 当前手牌中的顺子和刻子作为暗组候选高亮，不移出手牌。
- 条/中造成 Damage。
- 饼/白增加 Defense。
- 万/发增加 Money。
- 风牌触发 Tempo 节奏效果。
- 敌方武将按 3 回合循环行动：准备、轻量干扰、主要攻击。
- 胡牌触发 `Ultimate Win`：明组、暗组、将牌和散打牌按权重结算，再乘以胡牌倍率。
- 胜利条件：敌方 HP 归零。
- 失败条件：玩家 HP 归零。

不做：

- 复杂分数。
- 七对、十三幺。
- 花牌、季牌。
- 武将技能、武器、印记。
- 商店、路径、Boss。
- 副露、杠、额外奖励。

### 2.0：牌型倍率与战斗数值

目标：在 1.0 对战循环基础上加入牌型倍率、牌型等级和更完整的战斗数值。

新增：

- 胡牌倍率。
- 牌型等级。
- 组合基础收益。
- 伤害、防御、资金公式。
- 七小对、十三幺、清一色、全刻、全顺等特殊牌型逐步加入。

Dev Tuning：

- 将组合基础收益、胡牌倍数、敌人 HP、敌人攻击力、敌人行动循环和关卡限制加入调试表。

### 3.0：花牌季牌与战斗 Buff

目标：加入梅兰竹菊、春夏秋冬，让它们成为局内 Buff，而不是普通打出牌材料。

新增：

- 梅兰竹菊牌。
- 春夏秋冬牌。
- 万收益提升。
- 索/条伤害提升。
- 筒/饼防御提升。
- 胡牌大招倍率提升。
- 敌方攻击延迟。
- `FlowerSeasonBuffBar` 和 8 个 Buff 槽。

Dev Tuning：

- 将花牌、季牌、牌面功能 Buff 和升级公式加入调试表。

### 4.0：三国武将与武器系统

目标：将三国主题深度接入武将对战和牌局构筑。

新增：

- 玩家携带 3 名武将。
- 每名武将可装备 2 件武器，共 6 个武器槽。
- 武将 Buff 作用于风牌、箭牌、花季牌、万筒索收益和胡牌大招。
- 武器提供印记，附着在万/筒/索上，改变该牌打出或大招重算时的效果。
- 敌方武将开始拥有不同攻击模式。

Dev Tuning：

- 将武将触发条件、武器印记公式、升级数值、牌属性成长和敌方攻击模式加入调试表。

### 5.0：商店与局内经济

目标：让 Money 正式成为购买资源，形成战斗收益到构筑成长的闭环。

新增：

- 购买新胡牌牌型。
- 购买牌型升级。
- 购买武器。
- 购买武将。
- 购买花季 Buff。
- 购买一次性道具。
- 购买特殊牌库改造。
- 3 个消耗性道具栏。

Dev Tuning：

- 将商店池、价格、稀有度、刷新规则、购买限制加入调试表。

### 6.0：Roguelike 路径与敌方武将关卡

目标：加入完整 Run 的路径选择、随机事件结构和有差异的敌方武将关卡。

新增：

- 路径节点。
- 随机奖励。
- 随机惩罚。
- 商店节点。
- 玩法限制节点。
- 大 Boss。
- 特殊事件。
- 当前关名称提示：`StageNameBadge`、`StageTypeIcon`、`StageModifierLabel`。
- Boss 可改变规则，例如提高攻击频率、禁用某花色收益、削弱胡牌大招倍率。

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

- 战斗开始从牌库摸 16 张。
- 玩家选择 13 张作为初始手牌。
- 剩余 3 张进入弃牌区，不触发效果。
- 手牌上限为 13 张。
- 每回合玩家选择 1-3 张打出。
- 打出后手牌先减少；下一轮从牌库摸同等数量的牌并补回 13 张。
- 每回合结算后检测是否满足胡牌大招条件。

### 打出类型判定

打出的 3 张牌只允许被判定为以下四类之一：

1. 刻子。
2. 顺子。
3. 对子 + 单张。
4. 散牌。

判定优先级：

1. 先判断刻子。
2. 再判断顺子。
3. 再判断对子 + 单张。
4. 最后判断散牌。

顺子规则：

- 格式为 `ABC`。
- 3 张牌必须同一花色。
- 3 张牌必须数字连续。
- 只有万、饼、条可以组成顺子。
- 风牌和箭牌不能组成顺子。
- 顺子触发强即时效果，并进入明组区。

刻子规则：

- 格式为 `AAA`。
- 3 张牌必须完全相同。
- 万、饼、条、风牌、箭牌都可以组成刻子。
- 刻子触发强即时效果，并进入明组区。

对子 + 单张规则：

- 格式为 `AA + B`。
- 两张完全相同的牌触发弱效果。
- 第三张单张触发基础效果。
- 对子 + 单张不进入明组区。

散牌规则：

- 格式为 `A + B + C`。
- 不满足刻子、顺子、对子 + 单张。
- 散牌只触发其中 1 张牌的基础效果。

### 资源映射

- 条 = 攻击。
- 饼 = 防御。
- 万 = 金钱。
- 中 = 攻击型字牌。
- 发 = 金钱型字牌。
- 白 = 防御型字牌。
- 东、南、西、北 = 节奏型字牌。

效果强度：

- 顺子/刻子 = 强效果。
- 对子 = 弱效果。
- 单张 = 基础效果。
- 散牌 = 只触发 1 张牌的基础效果。

### 明组与暗组

明组：

- 玩家打出的 3 张牌形成顺子或刻子后，保存到 `OpenMeldLedger` 明组区。
- 明组立即触发战斗效果。
- 明组计入胡牌所需的 4 组面子。
- 明组参与胡牌大招结算。
- 明组结算权重低于暗组。

暗组：

- 当前手牌中已经可以组成顺子或刻子的 3 张牌。
- 暗组不移出手牌，不立即触发强战斗效果。
- 暗组计入胡牌所需的 4 组面子。
- 暗组参与胡牌大招结算。
- 暗组结算权重高于明组。
- UI 中需要高亮暗组候选。

### 敌方武将

- 1.0 默认敌方为训练武将。
- 敌方按 3 回合循环行动。
- 第 1 回合：准备行动。
- 第 2 回合：轻量干扰。
- 第 3 回合：主要攻击。
- 敌方必须显示下次行动意图、剩余倒计时、攻击伤害和特殊效果。
- 敌方攻击先扣 Defense。
- 防御不足时，溢出伤害扣玩家 HP。
- 敌人攻击后，防御清空或衰减，防御不应永久无限累计。

### 胡牌大招

只支持传统常规胡作为大招触发条件：

```text
4 面子 + 1 雀头
```

面子定义：

- 顺子：同花色连续三张，例如 `三万 四万 五万`。
- 刻子：三张相同牌，例如 `东 东 东`。
- 面子可以来自明组区，也可以来自当前手牌中的暗组候选。

雀头定义：

- 两张相同牌，例如 `白 白`。
- 将牌必须来自当前手牌。
- 已经打出的牌不能回溯组成将牌。

大招效果：

- 明组、暗组、将牌和散打牌分别计算攻击、防御、金钱和节奏收益。
- 暗组 = 高权重。
- 明组 = 标准权重。
- 将牌 = 中权重。
- 散牌 = 低权重。
- 普通弃牌 = 不结算。
- 基础胡牌倍率为 `2`。
- 每个暗组使胡牌倍率增加 `0.5`。
- 每个明组使胡牌倍率增加 `0.25`。
- 玩家当前生命值低于最大生命值 30% 时，胡牌倍率增加 `0.5`。
- 敌人攻击倒计时为 1 时胡牌，胡牌倍率增加 `0.5`。

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

每个界面必须先完成原型图，再拆资产，再拼 Godot。

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

绿幕源文件、透明成品、Godot 场景、对比截图分目录保存。

推荐目录：

```text
assets/sprites/<Screen>/Prototypes
assets/sprites/<Screen>/GreenScreen
assets/sprites/<Screen>/Textures
assets/sprites/<Screen>/Comparison
assets/sprites/<Screen>/AssetManifests
```

### 7.3 Godot 拼装

Godot 拼装要求：

- 按意向图坐标还原。
- 使用统一 16:9 坐标基准。
- 固定像素坐标和纹理导入规则。
- Nearest/Point Filter。
- 无压缩导入。
- 每个元素独立 Node。
- 可交互元素必须有稳定英文节点名。
- 可变文字与数字必须使用文本组件，不烘焙进背景。

每个界面保存：

- `prototype_image`
- `asset_manifest`
- `godot_scene`
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

用途：核心武将对战界面，包含玩家 HP、防御、资金、敌方 HP、敌方攻击倒计时、明组区、暗组候选、将牌候选、向听数、手牌、抓牌和胡牌大招。

核心资产：

- `UI_Battle_Background_v001.png`
- `UI_Battle_TopHudFrame_v001.png`
- `UI_Battle_PlayerHpBadge_v001.png`
- `UI_Battle_DefenseBadge_v001.png`
- `UI_Battle_MoneyBadge_v001.png`
- `UI_Battle_EnemyHpBadge_v001.png`
- `UI_Battle_EnemyAttackCountdownBadge_v001.png`
- `UI_Battle_RoundBadge_v001.png`
- `UI_Battle_PlayAreaFrame_v001.png`
- `UI_Battle_OpenMeldLedgerPanel_v001.png`
- `UI_Battle_ConcealedMeldHintPanel_v001.png`
- `UI_Battle_PairCandidateHintPanel_v001.png`
- `UI_Battle_ShantenBadge_v001.png`
- `UI_Battle_WinMultiplierBadge_v001.png`
- `UI_Battle_HandTray_v001.png`
- `UI_Battle_TileCardBase_v001.png`
- `UI_Battle_TileSelectedGlow_v001.png`
- `UI_Battle_ScorePreviewPanel_v001.png`
- `UI_Battle_ButtonPlayTiles_v001.png`
- `UI_Battle_ButtonUltimateWin_v001.png`
- `UI_Battle_ButtonDiscard_v001.png`
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
- `meld_effects`
- `win_patterns`
- `enemy_warlords`
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
3. 识别刻子、顺子、对子 + 单张、散牌或胡牌。
4. 即时 Money/Damage/Defense。
5. 敌方 HP、防御或资金变化。
6. Buff。
7. 胡牌大招重算与倍率。
8. 爆字与震屏。

卡牌手感：

- 每张牌具备独立 Transform。
- 目标位置 `TargetTransform` 与显示位置 `VisualTransform` 分离。
- 显示位置用缓动追随目标位置。
- Hover 放大、倾斜、发光。
- 点击压缩。
- 释放回弹。
- 选中上浮。

战斗反馈：

- 大字牌型。
- 逐项弹资源。
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
- Godot 主线明确。
- 资产命名覆盖关键界面。
- 原型图流程、拆图流程和动效规则完整。

### Godot GUT 测试

- 136 张牌池数量与分类正确。
- 常规胡 `4 面子 + 雀头` 可识别。
- 起手 16 选 13，剩余 3 张进入弃牌区。
- 每回合可打出 1-3 张，下一轮抓牌数量等于上轮打出数量，补回 13 张。
- 无锁牌逻辑。
- 打出的牌可被判定为单牌、对子、刻子、顺子、对子 + 单张、散牌。
- 顺子和刻子进入 `OpenMeldLedger` 明组区。
- 当前手牌中的顺子和刻子可作为暗组候选。
- 条/中造成伤害，饼/白增加防御，万/发增加资金，风牌触发节奏效果。
- 敌方按 3 回合循环行动，主要攻击优先扣防御再扣 HP。
- 胡牌时触发大招，按明组、暗组、将牌、散打牌重新结算并乘以胡牌倍数。
- 敌方 HP 归零胜利；玩家 HP 归零失败。

### 美术还原测试

- 每个界面存在原型图、资产清单、Godot 场景和对比截图。
- Godot 截图与原型图在布局、比例、层级上保持高度一致。
- 所有可交互元素和可变文字数字都是独立 Node。

### 动效测试

- 选牌有 hover、上浮、倾斜、发光。
- 出牌进入事件队列。
- 牌型、基础收益、Buff、大招倍率和总伤害按顺序分段播放。
- Score Burst、Screen Shake、CRT 层可通过 `juice_profile` 开关和调参。

### 资产管线测试

- 每个界面资产名在 manifest 中存在。
- Texture 导入为 Nearest/Point Filter。
- Texture 无压缩。
- Texture 使用固定像素坐标和纹理导入规则。
- 可交互元素在 Godot 中是独立 Node。

### Game 战斗界面资产表

- 战斗界面资产框架以 `assets/sprites/battle/UI_Battle_AssetManifest_v001.json` 为准。
- 原型图目标分辨率为 `1920x1080`，Godot 中等比映射到 16:9 游戏视图。
- 麻将牌采用 `34` 个牌面资产 + `136` 个数据实例，不画 136 张独立 PNG。
- `1.0` 实际启用玩家 HP、防御、资金、敌方 HP、敌方攻击倒计时、手牌、按打出数量抓牌、打出 1-3 张、明组区、暗组候选、将牌候选、向听数、大招和结束战斗；`3.0` 花季 Buff、`4.0` 武将/武器、`5.0` 消耗品、`6.0` 关卡提示先预留独立节点。
- 每次 Image 2.0 生成完整 Game 意向图后，必须更新 manifest 中对应资产的 `sourceSheet` 与 `sourceRect`，再拼进 Godot 场景。

## 12. 默认约定

- 游戏内 UI 默认英文。
- 麻将牌面允许中文符号，例如 `万`、`筒`、`索`、`东南西北`、`中发白`。
- 计划文件本身使用中文。
- 每个界面必须先做 GPT Image 2.0 意向原型图，再拆资产并拼进 Godot。
- 未来商业发布前必须重新检查版权、素材、字体、音效和可识别参考问题。
