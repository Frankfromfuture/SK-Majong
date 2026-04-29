# Warlord1 System (曹操骑马武将拆件演出)

## 1) 系统说明
- 入口角色：`res://characters/warlord1/scenes/Warlord1.tscn`
- 主控制脚本：`res://characters/warlord1/scripts/warlord1.gd`
- 独立测试场景：`res://characters/warlord1/dev/Warlord1DevScene.tscn`
- 特效节点：`res://characters/warlord1/scenes/WarlordEffect2D.tscn`
- 目标：在不影响 battle 主逻辑前提下，先独立验证骑马武将动作与特效。

## 2) Image 2.0 Prompt 使用
素材提示词文件在：
- `res://characters/warlord1/assets/prompts/warlord1_parts_prompt.txt`
- `res://characters/warlord1/assets/prompts/warlord1_horse_parts_prompt.txt`
- `res://characters/warlord1/assets/prompts/warlord1_weapon_prompt.txt`
- `res://characters/warlord1/assets/prompts/warlord1_effects_prompt.txt`
- `res://characters/warlord1/assets/prompts/warlord1_reference_prompt.txt`

把文本直接复制到 Image 2.0 生成器使用即可。

## 3) 生成素材目录
- 原始绿幕图放：`res://characters/warlord1/assets/raw_generated/`
- 自动裁切输出：`res://characters/warlord1/assets/cut/`
- 最终人工整理拆件：`res://characters/warlord1/assets/parts/`
- 特效图：`res://characters/warlord1/assets/effects/`

## 4) 自动裁切运行方式
### Godot 内运行
脚本：`res://characters/warlord1/scripts/green_screen_auto_cutter.gd`
- 这是 `EditorScript`，可在编辑器中运行。
- 会把接近 `#00FF00` 的绿幕转透明。
- 按连通区域切成独立 PNG。
- 输出 `cut_index.json`（含来源、裁切矩形、尺寸）。

### 外部 Python 运行
脚本：`/Users/frankfan/Desktop/Project/SK Majong/tools/cut_green_screen_assets.py`
- 依赖 Pillow（没有就先 `pip install Pillow`）。
- 输入：`characters/warlord1/assets/raw_generated/`
- 输出：`characters/warlord1/assets/cut/`

## 5) 如何填 warlord1_parts_map.json
文件：`res://characters/warlord1/assets/parts/warlord1_parts_map.json`

填写方式：
1. 把每个部件 key 对应到裁切出的 png 路径（支持 `res://...` 或仅文件名）。
2. `effects` 字段填写帧序列数组（按播放顺序）。
3. `warlord1.gd` 会在读取时做轻量关键词自动匹配（仅补空字段），但不会强制覆盖你手工填写。

额外工具：
- Map 草稿脚本：`/Users/frankfan/Desktop/Project/SK Majong/tools/generate_warlord1_map_draft.py`
- 智能初配脚本（按 cut_index 版面顺序）：`/Users/frankfan/Desktop/Project/SK Majong/tools/build_warlord1_map_from_cut_index.py`
- 可视化绑定界面：`res://characters/warlord1/dev/Warlord1PartsMapperScene.tscn`
  - 左侧选 cut PNG
  - 右侧选分类与部件
  - `Assign` / `Append Frame` / `Save Map`

## 6) 打开 Warlord1DevScene
- 直接运行：`res://characters/warlord1/dev/Warlord1DevScene.tscn`
- 或在 battle 界面点击 `Warlord Dev` 按钮进入。
- 在 Dev 场景可点 `Open Mapper` 进入可视化部件绑定界面。

## 7) 从 battle 进入 Warlord Dev
- battle 按钮已接入：`Warlord Dev`
- 点击切到：`res://characters/warlord1/dev/Warlord1DevScene.tscn`
- dev 场景中 `Back To Battle` 可返回 `res://src/scenes/battle/battle.tscn`

## 8) 如何新增动作
在 `res://characters/warlord1/scripts/warlord1.gd`：
1. 新增 `play_xxx()` 公共方法。
2. 在 `_ensure_animations()` 注册新动画。
3. 新建 `_make_xxx_animation()`，用 `_track()` 添加关键帧。
4. 在 `_on_animation_finished()` 添加收招状态规则。

## 9) 如何替换武器
1. 在 map 中替换 `weapon` 区域路径。
2. 如果新武器挂点不同，调整 `WeaponRoot` 或 `Spear` 初始位置。
3. 如需不同动作弧线，改 `attack_thrust` / `attack_slash` 关键帧。

## 10) 后续部署到 battle
建议流程：
1. 在 dev 场景调好动作与特效。
2. 固化 `parts_map`。
3. 在 battle 的角色轨道节点实例化 `Warlord1.tscn`。
4. 用 battle 事件驱动 `play_*` 接口（不改麻将核心结算）。

## 像素导入建议（重要）
对 warlord1 贴图：
1. Filter 设为 `Nearest`（关闭模糊）。
2. 关闭会导致边缘发糊的压缩策略。
3. 保留透明边缘清晰。
4. 统一缩放建议通过 `pixel_scale` 控制。
5. Sprite2D 使用 centered（已默认）并按关节节点微调 pivot。
