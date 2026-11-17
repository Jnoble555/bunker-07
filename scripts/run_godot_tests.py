"""Run the native regression gate; an assertion, script error or timeout fails CI."""
import argparse
import os
from pathlib import Path
import subprocess
import sys
import tempfile

SUITES = (
    "security_director_test", "security_director_integration_test",
    "security_radio_test", "security_radio_integration_test",
    "security_search_integration_test",
    "visual_benchmark_test",
    "deep_signal_enemy_test", "tactical_enemy_test", "operation_level_test",
    "operation_combat_test", "tactical_movement_test", "tactical_operation_test",
    "operation_integration_test", "operation_menu_test", "inventory_test",
    "shotgun_test", "shotgun_integration_test", "milestone_test", "campaign_test",
    "close_smoke",
)
ROOT = Path(__file__).resolve().parents[1]


def run(godot, logs):
    logs.mkdir(parents=True, exist_ok=True)
    failures = []
    with tempfile.TemporaryDirectory(prefix="bunker07-tests-") as profile:
        env = os.environ.copy()
        for key in ("APPDATA", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
            env[key] = str(Path(profile) / key.lower())
            Path(env[key]).mkdir()
        for suite in SUITES:
            try:
                result = subprocess.run(
                    [godot, "--headless", "--path", str(ROOT / "godot"),
                     "--script", f"res://tests/{suite}.gd"],
                    env=env, capture_output=True, text=True, encoding="utf-8",
                    errors="replace", timeout=240,
                )
                output = result.stdout + result.stderr
                unexpected_error = any(line.startswith("ERROR:") and
                    "Failed to read the root certificate store." not in line
                    for line in output.splitlines())
                bad = result.returncode != 0 or "SCRIPT ERROR:" in output or unexpected_error or any(
                    line.startswith("FAIL ") for line in output.splitlines())
                (logs / f"{suite}.log").write_text(output, encoding="utf-8")
                print(f"{suite}: exit={result.returncode} {'FAIL' if bad else 'PASS'}", flush=True)
                for line in output.splitlines():
                    if any(word in line for word in ("passed", "CHECKS", "failures", "SKIP", "WINDOW CLOSE", "FAIL ")):
                        print(line, flush=True)
                if bad:
                    print(output, file=sys.stderr)
                    failures.append(suite)
            except subprocess.TimeoutExpired:
                failures.append(suite)
                (logs / f"{suite}.log").write_text("TIMEOUT after 240 seconds\n", encoding="utf-8")
                print(f"{suite}: TIMEOUT", flush=True)
    return failures


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--logs", type=Path, required=True)
    args = parser.parse_args()
    failed = run(args.godot, args.logs)
    print(f"Godot programs: {len(SUITES) - len(failed)}/{len(SUITES)} passed")
    raise SystemExit(1 if failed else 0)
