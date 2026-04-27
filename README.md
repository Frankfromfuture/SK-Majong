# Sangoku Mahjong

三国题材 + 自创「巡目得分流」麻将 Roguelike 原型。

## Unity 主线总纲

当前主线计划已切换到 Unity PC 原型。长期开发、资产生成、规则迭代、调试表和动效框架以 [`docs/unity_development_framework.md`](docs/unity_development_framework.md) 为准。

## 当前阶段

Unity 主线处于 `1.0` 胡牌验证规划阶段；旧 Godot/Love2D 内容保留为历史原型和参考线。

## Godot 历史原型

- Godot 4.3+
- GDScript
- 2D 像素风，逻辑 viewport 为 `640x360`
- 核心逻辑放在 `src/core/`，不依赖 UI、Node 或 Scene
- 测试框架计划使用 GUT

### 运行

安装 Godot 4.3+ 后，打开本目录的 `project.godot`，运行主场景。

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

## Love2D 内部实验原型

新增 `love2d_proto/` 作为 Balatro-like 视觉与手感实验线，Godot 原型保留不动。

当前机器如未安装 Love2D，可先安装运行环境：

```sh
brew install --cask love
```

运行 Love2D 原型：

```sh
love love2d_proto
```

Love2D 原型使用程序生成像素 atlas，避免 AI 单图比例不可控：

```sh
python3 love2d_proto/tools/generate_ui_atlas.py
python3 love2d_proto/tools/extract_main_menu_layers.py
python3 love2d_proto/tools/verify_project.py
```

Lua 逻辑测试文件在 `love2d_proto/tests/logic_spec.lua`。安装 Lua 或 Love2D 后可接入测试 runner 执行。

## MVP 边界

MVP 只验证一个 Run 的核心循环：13 张手牌、4 巡打分、3 关战役、招贤馆、8 名武将、4 个国玺。暂不做存档、设置、本地化、Steamworks、字牌、立直、宝牌、副露或兵法系统。
