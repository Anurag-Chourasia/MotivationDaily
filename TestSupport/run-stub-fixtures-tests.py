#!/usr/bin/env python3
"""Verify AppStubData submodule integration and fixtures decoding for Motivation Daily."""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
submodule_path = root / "Submodules" / "AppStubData"

if not submodule_path.exists():
    print(f"Error: Submodule directory not found at {submodule_path}")
    sys.exit(1)

# 1. Verify Submodule Git Status
res = subprocess.run(["git", "submodule", "status"], cwd=root, capture_output=True, text=True, check=True)
print("Git submodule status:", res.stdout.strip())

# 2. Compile and run Fixture verification using swift test
cmd = [
    "xcrun", "swift", "test",
    "--package-path", str(submodule_path),
    "--scratch-path", "/tmp/MotivationDailySubmoduleBuild",
    "--filter", "FixturesTests/testAllMotivationDailyEndpointsAndScenarios"
]
print("Running command:", " ".join(cmd))
test_run = subprocess.run(cmd, capture_output=True, text=True)
if test_run.returncode != 0:
    print("Test run failed:\n", test_run.stderr)
    sys.exit(test_run.returncode)

print(test_run.stdout)
print("All Motivation Daily stub fixtures verified successfully!")
