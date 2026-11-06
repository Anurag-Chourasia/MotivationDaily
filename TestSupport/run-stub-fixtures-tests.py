#!/usr/bin/env python3
"""Verify pinned submodule resources without building/linking its Swift package."""
import json
import plistlib
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
subprocess.run(["python3", "Scripts/verify-submodules.py"], cwd=root, check=True)
project = plistlib.loads(subprocess.check_output([
    "plutil", "-convert", "xml1", "-o", "-", str(root / "MotivationDaily.xcodeproj/project.pbxproj")
]))["objects"]
assert not any(obj.get("isa") == "XCLocalSwiftPackageReference" and "AppStubData" in obj.get("relativePath", "") for obj in project.values())
assert not any(obj.get("productName") == "AppStubData" for obj in project.values())
resource = "A06500000000000000000002"
assert resource in project["346EE2353091AC06006198AF"]["files"], "Missing unit-test resources"
assert resource not in project["344A416A2EC37AE100B74E80"]["files"], "Fixtures linked to app"
for source in (root / "MotivationDaily").rglob("*.swift"):
    assert "import AppStubData" not in source.read_text(), source
resources = root / "Submodules/AppStubData/Sources/AppStubData/Resources"
for endpoint in ("quotes", "authors", "wallpapers"):
    for scenario in ("positive", "empty", "negative"):
        path = resources / f"motivationdaily-{endpoint}-{scenario}.json"
        value = json.loads(path.read_text())
        if scenario == "positive":
            assert isinstance(value, list) and value, path
        elif scenario == "empty":
            assert value == [], path
        else:
            assert isinstance(value, dict) and value, path
print("Nine fixture payloads valid; submodule pinned; endpoint resources test-only; no local SPM linkage.")

catalog = json.loads((resources / "motivationdaily-ui-fixtures.json").read_text())
assert catalog["gradientPalettes"] and catalog["randomQuoteCount"] > 0
assert any(obj.get("name") == "Copy Debug fixture resources" for obj in project.values())
