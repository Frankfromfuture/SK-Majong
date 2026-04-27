from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
required = [
    "main.lua",
    "conf.lua",
    "src/core/moveable.lua",
    "src/core/event_manager.lua",
    "src/render/atlas.lua",
    "src/scenes/main_menu.lua",
    "src/scenes/battle.lua",
    "src/game/pattern_matcher.lua",
    "assets/generated/ui_atlas.png",
    "assets/generated/ui_atlas.lua",
    "assets/main_menu_layers/background.png",
    "assets/main_menu_layers/layers.lua",
]

for rel in required:
    path = ROOT / rel
    assert path.exists(), f"missing {rel}"

subprocess.check_call([sys.executable, str(ROOT / "tools" / "verify_assets.py")])
print("project structure ok")
