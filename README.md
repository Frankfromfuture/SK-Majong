# Sangoku Mahjong

三国题材 + 武将对战麻将 + Roguelike 路径与奖励 + 高动效爆发爽感原型。

## Godot 主线

当前主线已切回 **Godot PC 原型**。长期开发、资产生成、规则迭代、调试表、Image 2.0 拆图流程和动效框架以 [`docs/godot_development_framework.md`](docs/godot_development_framework.md) 为准。

Unity 线已废弃并移除，后续不要再使用 Unity 工程推进。

## 当前阶段

主线处于 `1.0` 武将对战核心 Demo 阶段：

- 136 张标准麻将牌。
- 起手摸 16 张，选择 13 张作为初始手牌，剩余 3 张弃置。
- 每回合可打出 1-3 张，打出几张，下一轮就抓几张补回手牌。
- 无锁牌。
- 打出的牌按优先级判定为刻子、顺子、对子+单张、对子、单牌、散牌。
- 顺子和刻子进入明组区；手牌中的顺子和刻子作为暗组候选。
- 条/中造成攻击，饼/白增加防御，万/发增加金钱，风牌提供节奏效果。
- 敌方武将按 3 回合循环行动：准备、干扰、主要攻击。
- 胡牌触发 `Ultimate Win`：明组、暗组、将牌、散打牌按权重重算，再乘以胡牌倍率。
- 胜利条件是敌方 HP 归零；失败条件是玩家 HP 归零。
- 暂不启用复杂分数、花牌季牌、武将技能、武器、商店和地图。

## 运行 Demo

安装 Godot 4.3+ 后，打开本目录的 `project.godot`，点击运行主场景。

主菜单点击 `Start Run` 进入战斗 demo。

如果本机配置了 Godot CLI，可执行：

```sh
godot --path . --headless --quit
```

运行 GUT 测试：

```sh
godot --path . --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

重新导出牌型表：

```sh
godot --path . --headless -s res://tools/data_export/export_pattern_table.gd
```

## 目录

- `src/core/`：纯规则逻辑。
- `src/scenes/main_menu/`：主菜单。
- `src/scenes/battle/`：1.0 战斗 demo。
- `src/ui/`：可复用 UI 控件。
- `assets/sprites/main_menu/`：主菜单资产。
- `assets/sprites/battle/`：Game/Battle 战斗界面资产框架与 manifest。
- `docs/godot_development_framework.md`：长期开发总纲。
- `tests/`：GUT 测试。

## Love2D 历史实验

`love2d_proto/` 保留为 Balatro-like 视觉与手感实验线，仅作参考，不再作为主线推进。
