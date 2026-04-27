using System.Collections.Generic;
using System.IO;
using SangokuMahjong;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace SangokuMahjong.Editor
{
    public static class SangokuMainMenuBuilder
    {
        private const float PixelsPerUnit = 100f;
        private const int CanvasWidth = 640;
        private const int CanvasHeight = 360;
        private const string ArtRoot = "Assets/SangokuMahjong/Art/MainMenu";
        private const string ScenePath = "Assets/Scenes/MainMenu.unity";

        private readonly struct LayerSpec
        {
            public readonly string Name;
            public readonly string FileName;
            public readonly RectInt Rect;
            public readonly float FloatPixels;
            public readonly float WobbleDegrees;
            public readonly float Pulse;
            public readonly string Action;

            public LayerSpec(string name, string fileName, RectInt rect, float floatPixels = 0f, float wobbleDegrees = 0f, float pulse = 0f, string action = "")
            {
                Name = name;
                FileName = fileName;
                Rect = rect;
                FloatPixels = floatPixels;
                WobbleDegrees = wobbleDegrees;
                Pulse = pulse;
                Action = action;
            }
        }

        private static readonly IReadOnlyList<LayerSpec> Layers = new[]
        {
            new LayerSpec("LogoSprite", "logo_sangoku_mahjong.png", new RectInt(122, 10, 398, 148), 3f, 0f, 0.018f),
            new LayerSpec("StartRunButton", "button_start_run.png", new RectInt(218, 166, 204, 48), 0f, 0f, 0f, "start"),
            new LayerSpec("CollectionButton", "button_collection.png", new RectInt(218, 207, 204, 45)),
            new LayerSpec("OptionsButton", "button_options.png", new RectInt(218, 245, 204, 45)),
            new LayerSpec("QuitButton", "button_quit.png", new RectInt(218, 282, 204, 45), 0f, 0f, 0f, "quit"),
            new LayerSpec("HighestScorePanel", "panel_highest_score.png", new RectInt(6, 292, 150, 62), 0.7f),
            new LayerSpec("BonusMultiplierPanel", "panel_bonus_multiplier.png", new RectInt(486, 292, 150, 62), 0.7f),
            new LayerSpec("PrototypeBuildLabel", "prototype_build.png", new RectInt(242, 326, 156, 26)),
            new LayerSpec("MenuTileWanLeft", "tile_wan_left.png", new RectInt(150, 218, 54, 86), 3.4f, 1.4f),
            new LayerSpec("MenuTileFaRight", "tile_fa_right.png", new RectInt(424, 212, 50, 77), 2.5f, -1.2f),
            new LayerSpec("MenuTilePinRight", "tile_pin_right.png", new RectInt(466, 206, 50, 80), 2.1f, 0.8f),
            new LayerSpec("MenuTileDongRight", "tile_dong_right.png", new RectInt(506, 216, 58, 86), 2.8f, -1f)
        };

        [MenuItem("Sangoku Mahjong/Create Main Menu Scene")]
        public static void CreateMainMenuScene()
        {
            Directory.CreateDirectory("Assets/Scenes");
            AssetDatabase.ImportAsset(ArtRoot, ImportAssetOptions.ImportRecursive | ImportAssetOptions.ForceUpdate);

            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var camera = CreateCamera();
            CreateSprite("BackgroundSprite", "background.png", new RectInt(0, 0, CanvasWidth, CanvasHeight), -10, false, "");

            for (var i = 0; i < Layers.Count; i++)
            {
                var layer = Layers[i];
                var go = CreateSprite(layer.Name, layer.FileName, layer.Rect, i, layer.Action.Length > 0, layer.Action);
                var floating = go.AddComponent<FloatingLayer>();
                floating.floatPixels = layer.FloatPixels;
                floating.wobbleDegrees = layer.WobbleDegrees;
                floating.pulse = layer.Pulse;
                floating.phase = i * 0.83f;
            }

            Selection.activeGameObject = camera.gameObject;
            EditorSceneManager.SaveScene(scene, ScenePath);
            AssetDatabase.Refresh();
            Debug.Log($"Created editable Sangoku Mahjong main menu scene at {ScenePath}");
        }

        private static Camera CreateCamera()
        {
            var go = new GameObject("MainCamera");
            var camera = go.AddComponent<Camera>();
            camera.orthographic = true;
            camera.orthographicSize = CanvasHeight / PixelsPerUnit / 2f;
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = Color.black;
            go.transform.position = new Vector3(0f, 0f, -10f);
            return camera;
        }

        private static GameObject CreateSprite(string objectName, string fileName, RectInt rect, int order, bool isButton, string action)
        {
            var sprite = AssetDatabase.LoadAssetAtPath<Sprite>($"{ArtRoot}/{fileName}");
            if (sprite == null)
            {
                throw new FileNotFoundException($"Missing sprite asset: {ArtRoot}/{fileName}");
            }

            var go = new GameObject(objectName);
            go.transform.position = PixelRectToWorldCenter(rect);

            var renderer = go.AddComponent<SpriteRenderer>();
            renderer.sprite = sprite;
            renderer.sortingOrder = order;

            if (isButton)
            {
                var collider = go.AddComponent<BoxCollider2D>();
                collider.size = new Vector2(rect.width / PixelsPerUnit, rect.height / PixelsPerUnit);
                var button = go.AddComponent<MainMenuButton>();
                button.action = action;
            }

            return go;
        }

        private static Vector3 PixelRectToWorldCenter(RectInt rect)
        {
            var centerX = rect.x + rect.width * 0.5f;
            var centerY = rect.y + rect.height * 0.5f;
            return new Vector3((centerX - CanvasWidth * 0.5f) / PixelsPerUnit, (CanvasHeight * 0.5f - centerY) / PixelsPerUnit, 0f);
        }
    }
}

