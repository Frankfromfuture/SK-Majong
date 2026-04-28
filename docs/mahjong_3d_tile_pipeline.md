# 2.5D Mahjong Tile Pipeline

本文件指导 Godot 中的 3D 麻将牌体、Image 2.0 绿幕贴图生成和后续 battle 2.5D 表现。

## 目标

- 所有麻将牌先做成 Godot 3D 牌体，而不是只用 2D 按钮图。
- 34 种牌面共用同一套 3D 牌体结构；136 张牌仍由数据实例生成。
- Battle 界面采用 2.5D：背景和 HUD 主要是 2D，麻将牌、亮牌、爆发演出使用 3D 悬浮展示。
- 当前原型先用 Godot 内置 `BoxMesh`、`QuadMesh`、`Label3D` 生成可运行版本；后续用 Image 2.0 生成高精度牌面贴图替换 `Label3D`。

## 进度

| 步骤 | 状态 | 说明 |
|---|---|---|
| MahjongTile3D 基础 BoxMesh+Label3D | ✅ 完成 | 初版 |
| MahjongTile3D 升级：bevel边框、角饰、材质 | ✅ 完成 | 象牙牌体+铜角饰+倒角+选中呼吸动画 |
| MahjongTileShowcase3D 三点光照 | ✅ 完成 | key/fill/rim + transparent SubViewport |
| Texture 自动加载（Sprite3D fallback Label3D） | ✅ 完成 | 有贴图用贴图，没贴图用 Label3D |
| UI_Tile3D_FaceManifest_v001.json | ✅ 完成 | 34 张标准牌面文件名清单 |
| 用户绿幕贴图切分 | ✅ 完成 | 4 张 3x3 绿幕图已切成 34 张透明 PNG |
| 高清牌面重导出 | ✅ 完成 | 单张 1024x1536，供 3D Sprite 使用 |
| 2D 牌面移除 | ✅ 完成 | 只保留透明点击热区，hover/selected 由 3D 牌体表现 |

## Godot 实现方式

当前实现文件：

- `src/ui/mahjong_tile_3d.gd`
- `src/ui/mahjong_tile_showcase_3d.gd`
- `src/scenes/battle/battle.gd`

节点策略：

- `MahjongTile3D`：单张 3D 麻将牌。
  - `TileBodyMesh`：厚牌体，使用象牙色高光材质（Schlick-GGX）。
  - `BevelTop/Bottom/Left/Right`：四条倒角边缘，半透明铜金色。
  - `TileFacePlate`：正面象牙底板。
  - `TileFaceSprite`（有贴图时）：用 Sprite3D 加载牌面 PNG。
  - `TileFaceLabel`（无贴图时）：Label3D 中文牌面作为临时替代。
  - `CornerTrim_00-03`：四角铜金色装饰。
  - `TileFaceShine`：顶部反光条，有轻微上下浮动动画。
  - `TileHoverGlow`：鼠标悬停态发光和上浮。
  - `TileSelectedGlow`：选中态呼吸发光，Alpha 和 emission 脉冲动画。
- `HandTile3DShowcase`：底部 13 张手牌的 3D 悬浮展示。
- `DrawTile3DShowcase`：本回合 3 张候选牌的 3D 悬浮展示。

交互策略：

- 3D 牌负责所有可见 hover/selected 反馈。
- 原来的 `HandTile_00-12` 和 `DrawTile_00-02` 按钮只保留为完全透明点击热区。
- 鼠标进入透明热区后，会转发给对应 3D 牌体，让 3D 牌上浮、倾斜、发光；不会再显示 2D 幽灵牌。
- 这样后续调 3D 角度、贴图、动画时，不会破坏点击、选牌和战斗规则。

## 3D 牌体尺寸建议

Godot 内部标准：

| 项目 | 建议 |
|---|---|
| 牌体比例 | 宽 0.58，高 0.82，厚 0.16 |
| 正面贴图比例 | 约 7:10 |
| 正面贴图分辨率 | 当前单张 1024x1536 |
| 图集方式 | 34 个牌面可做单图，也可做一张 atlas |
| 过滤方式 | Pixel/Nearest，避免像素风被糊掉 |
| 材质 | 牌体用程序材质，牌面用透明 PNG 或 atlas region |

## Image 2.0 绿幕资产要求

优先生成两类图：

1. `UI_Tile3D_FaceSheet_v001.png`
   - 只包含 34 种牌面正面图。
   - 每个牌面正视图、无透视、无阴影。
   - 绿幕背景或透明背景。
   - 不要画厚度，不要画侧边，只画正面图案。

2. `UI_Tile3D_MaterialRefs_v001.png`
   - 象牙牌体材质、侧边暗部、磨损边缘、高光参考。
   - 可作为 Godot 材质调色参考，不直接整张贴到牌体。

## Image 2.0 推荐提示词

### 方案 A：一次性生成 34 张牌面图集

```text
Create a green-screen asset sheet for a Three Kingdoms fantasy mahjong roguelike game.
Detailed pixel art, ornate but clean, 2.5D game asset style.
Generate 34 front-facing mahjong tile face designs only, no tile thickness, no shadows, no perspective.
Each tile face is a flat rectangular ivory face panel with crisp pixel art symbols.
Include suits: Wan 1-9 using Chinese character 万 in red, Tong 1-9 using circle motifs in black/red/green, Suo 1-9 using bamboo motifs in green, winds 东 南 西 北 in black, dragons 中 red 发 green 白 black.
Uniform size, aligned grid, green screen background, high contrast, readable symbols, no English UI text, no copyrighted logos, no Balatro text.
Asset sheet, clean margins, consistent lighting, pixel sharp.
```

### 方案 B：逐张生成单个牌面（推荐，质量更好）

对 34 张牌面分别生成，每次替换 `[TILE_SYMBOL]` 和 `[COLOR_DESC]`：

```text
Create one front-facing mahjong tile face texture for a 2.5D Three Kingdoms fantasy roguelike game.
Tile face only, flat orthographic view, no side thickness, no shadow, green screen background.
Ivory face plate, ornate copper corner trim, crisp pixel art symbol: [TILE_SYMBOL].
Symbol color: [COLOR_DESC].
Resolution 1024x1536, high contrast, readable at small size, pixel sharp, no English text, no copyrighted logos.
```

替换表：

| 牌 | [TILE_SYMBOL] | [COLOR_DESC] |
|---|---|---|
| 1万-9万 | `Chinese numeral N with 万 below` | `deep red` |
| 1筒-9筒 | `N circle dot motifs arranged symmetrically` | `black and red` |
| 1索-9索 | `N bamboo sticks arranged vertically` | `green` |
| 东 | `Chinese character 东 (East wind)` | `black` |
| 南 | `Chinese character 南 (South wind)` | `black` |
| 西 | `Chinese character 西 (West wind)` | `black` |
| 北 | `Chinese character 北 (North wind)` | `black` |
| 中 | `Chinese character 中 (Red dragon)` | `red` |
| 发 | `Chinese character 发 (Green dragon)` | `green` |
| 白 | `Empty frame or 白 (White dragon)` | `light gray/white` |

## 后续替换贴图步骤

1. ✅ 建立 `UI_Tile3D_FaceManifest_v001.json`，记录 34 个标准牌面的文件名。
2. ✅ 在 `MahjongTile3D` 中实现 `Sprite3D` 自动加载 + `Label3D` fallback。
3. ✅ 用用户提供的绿幕图切分 34 张牌面 PNG。
4. ✅ 将图放入 `assets/sprites/battle/Textures/`，命名遵循 manifest。
5. ✅ 绿幕已去除，并重导出为 1024x1536 透明 PNG。
6. 保留透明点击热区，不改战斗逻辑。
7. 调整 `MahjongTileShowcase3D` 的 camera size、tile spacing、rotation，让 battle 视图保持 2.5D 悬浮手感。

## Battle 2.5D 方向

- 手牌：底部轻微扇形排列，选中后上浮、发光、前倾。
- 抓牌区：中下方 3 张候选牌悬浮，强调"本回合可打出"。
- 战斗区：出牌时 3D 牌飞入中央，组合成顺/刻/杠，然后触发钱/伤害/防御反馈。
- 胡牌大招：已打出的明组重新以 3D 牌队列回放，再乘以胡牌倍率冲向敌方武将。
- UI 面板：仍保持 2D 清晰读数，避免 3D 特效压过规则信息。
