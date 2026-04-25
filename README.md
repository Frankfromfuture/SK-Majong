# Sangoku Mahjong

三国题材 + 自创「巡目得分流」麻将 Roguelike 原型。

## 当前阶段

Phase 0: Godot 项目脚手架。

## 技术约定

- Godot 4.3+
- GDScript
- 2D 像素风，逻辑 viewport 为 `640x360`
- 核心逻辑放在 `src/core/`，不依赖 UI、Node 或 Scene
- 测试框架计划使用 GUT

## 运行

安装 Godot 4.3+ 后，打开本目录的 `project.godot`，运行主场景。

如果本机配置了 Godot CLI，可执行：

```sh
godot --path . --headless --quit
```

运行 GUT 测试：

```sh
godot --path . --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

## MVP 边界

MVP 只验证一个 Run 的核心循环：13 张手牌、4 巡打分、3 关战役、招贤馆、8 名武将、4 个国玺。暂不做存档、设置、本地化、Steamworks、字牌、立直、宝牌、副露或兵法系统。
