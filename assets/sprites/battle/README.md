# Battle Asset Framework

This folder holds the Game/Battle screen asset framework.

- Prototype image target: `1920x1080`.
- Godot mapping target: 16:9 canvas view, currently `640 x 360` prototype pixels.
- Tile strategy: draw 34 tile faces plus shared tile layers; generate 136 gameplay tile instances from data.
- 2.5D tile strategy: Godot renders mahjong tiles as reusable 3D bodies; Image 2.0 should generate 34 front-face textures for those bodies, not 136 full tile sprites.
- UI rule: every interactive element, number, variable label, tile, slot, icon, and row must be an independent Godot Node.
- Background rule: `UI_Battle_BG_v001.png` must not include baked buttons, numbers, tile faces, or interactive text.

Fill real `sourceRect` values in `UI_Battle_AssetManifest_v001.json` after the Image 2.0 prototype and green-screen asset sheets are generated.

3D tile texture target:

- `Textures/TileFace_*.png`: 34 orthographic tile face textures, transparent background, currently 1024x1536 each.
- `AssetManifests/UI_Tile3D_FaceManifest_v001.json`: atlas crop rectangles for each tile face.
- Runtime nodes: `HandTile3DShowcase`, `DrawTile3DShowcase`, `MahjongTile3D_*`.
- Runtime hover rule: 2D tile buttons are invisible hit areas only; hover/selected feedback must be visible on the 3D tile body, not as 2D ghost cards.
