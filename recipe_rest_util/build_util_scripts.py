import os
import pathlib
import shutil


prefix = pathlib.Path(os.environ["PREFIX"])
target = (
    os.environ.get("TARGET_PLATFORM")
    if "TARGET_PLATFORM" in os.environ
    else os.environ.get("target_platform")
)
if not target:
    raise RuntimeError("Missing required environment variable: TARGET_PLATFORM (or target_platform)")

destination = prefix / ("Scripts" if target.startswith("win-") else "bin")
destination.mkdir(parents=True, exist_ok=True)

script_dir = pathlib.Path(__file__).resolve().parent
candidate_dirs = [script_dir / "utilities", pathlib.Path.cwd() / "utilities"]
sources = []
utilities_dir = None
for candidate_dir in candidate_dirs:
    candidate_sources = sorted(candidate_dir.glob("*.py"))
    if candidate_sources:
        sources = candidate_sources
        utilities_dir = candidate_dir
        break

if not sources:
    raise FileNotFoundError(
        f"No utility scripts found in any expected directory: {', '.join(str(path) for path in candidate_dirs)}"
    )

for source in sources:
    shutil.copy2(source, destination / source.name)
