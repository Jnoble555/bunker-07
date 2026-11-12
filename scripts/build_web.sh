#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
web_output="${1:-$repo_root/work/site}"
mkdir -p "$web_output"
web_output="$(cd "$web_output" && pwd)"
# Import first so a fresh runner has the GLB cache before packaging resources.
godot --headless --editor --path "$repo_root/godot" --import
godot --headless --path "$repo_root/godot" --export-release Web "$web_output/index.html"
cp "$repo_root/classic.html" "$web_output/classic.html"
cp -R "$repo_root/src" "$repo_root/styles" "$web_output/"
touch "$web_output/.nojekyll"
python3 "$repo_root/scripts/finish_web.py" "$web_output" "${GITHUB_SHA:-local}"
