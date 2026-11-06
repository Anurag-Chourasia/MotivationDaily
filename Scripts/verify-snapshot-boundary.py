#!/usr/bin/env python3
"""Enforce test-only SnapshotTestKit linkage and optional Release binary exclusion."""
import plistlib
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
projects = list(root.glob("*.xcodeproj/project.pbxproj"))
if len(projects) != 1:
    raise SystemExit("Expected exactly one host project")
project = plistlib.loads(subprocess.check_output(["plutil", "-convert", "xml1", "-o", "-", str(projects[0])]))
objects = project["objects"]
packages = {key for key, value in objects.items()
            if value.get("isa") == "XCRemoteSwiftPackageReference"
            and value.get("repositoryURL", "").rstrip("/").removesuffix(".git").endswith("/SnapshotTestKit")}
if len(packages) != 1:
    raise SystemExit("Expected one canonical SnapshotTestKit package")
package = objects[next(iter(packages))]
if package.get("requirement") != {"kind": "exactVersion", "version": "1.0.4"}:
    raise SystemExit("SnapshotTestKit must be pinned exactly to 1.0.4")
products = {key for key, value in objects.items() if value.get("package") in packages}
consumers = []
for target in objects.values():
    if target.get("isa") != "PBXNativeTarget":
        continue
    linked = set(target.get("packageProductDependencies", [])) & products
    for phase_id in target.get("buildPhases", []):
        for file_id in objects[phase_id].get("files", []):
            if objects[file_id].get("productRef") in products:
                linked.add(objects[file_id]["productRef"])
    if linked:
        if target.get("productType") not in ("com.apple.product-type.bundle.unit-test", "com.apple.product-type.bundle.ui-testing"):
            raise SystemExit(f"Snapshot engine linked to production target: {target['name']}")
        consumers.append(target["name"])
if not consumers:
    raise SystemExit("No snapshot test consumer found")
if len(sys.argv) > 1:
    binary = Path(sys.argv[1])
    if not binary.is_file():
        raise SystemExit(f"Missing Release binary: {binary}")
    symbols = subprocess.check_output(["xcrun", "nm", "-a", str(binary)], stderr=subprocess.DEVNULL, text=True)
    libraries = subprocess.check_output(["xcrun", "otool", "-L", str(binary)], text=True)
    if "$s15SnapshotTestKit" in symbols or "XCTest.framework" in libraries or "SnapshotTestKit" in libraries:
        raise SystemExit("Release binary links snapshot engine or XCTest")
print("Verified test-only canonical snapshot consumers:", ", ".join(consumers))
