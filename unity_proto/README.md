# Sangoku Mahjong Unity Prototype

This Unity project is a parallel editor-friendly prototype for the main menu.

## Open

1. Activate a Unity license in Unity Hub.
2. Open this folder as a Unity project:
   `/Users/frankfan/Desktop/Project/SK Majong/unity_proto`
3. After Unity imports assets, use the top menu:
   `Sangoku Mahjong > Create Main Menu Scene`

The generated scene is saved to:
`Assets/Scenes/MainMenu.unity`

## Editing Rules

- The background and every visible menu element are separate GameObjects.
- Source PNGs live in `Assets/SangokuMahjong/Art/MainMenu`.
- The scene uses a 640x360 reference canvas mapped through a pixel-perfect orthographic camera.
- Texture import is forced to Sprite, Point filter, no compression, and 100 pixels per unit.

