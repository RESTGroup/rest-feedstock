import os
import pathlib
import runpy


recipe_dir = os.environ.get("RECIPE_DIR")
if not recipe_dir:
    raise RuntimeError("RECIPE_DIR is not set")

script = pathlib.Path(recipe_dir) / "build_util_scripts.py"
runpy.run_path(str(script), run_name="__main__")
