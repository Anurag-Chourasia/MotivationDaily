#!/usr/bin/env python3
"""Inspect the Release app, excluding embedded XCTest bundles."""
import subprocess
import sys
from pathlib import Path

app = Path(sys.argv[1])
assert app.is_dir(), f"Missing app: {app}"
unexpected = [str(path.relative_to(app)) for path in app.rglob("*")
              if "PlugIns" not in path.relative_to(app).parts
              and ("AppStubData" in path.name
                   or (path.name.startswith("motivationdaily-") and path.suffix == ".json"))]
assert not unexpected, f"Shared fixture resources in Release app: {unexpected}"
symbols = subprocess.check_output(["xcrun", "nm", str(app / "MotivationDaily")], text=True)
for name in ("UITestWallpaperRepository", "PreviewQuoteRepository", "makeUITestStore", "makeUITestSnapshot",
             "renderUITestImage", "seedUITestFavoritesIfNeeded", "MotivationDailyStubProvider", "UITestFixtureCatalog"):
    assert name not in symbols, f"Debug fixture symbol in Release app: {name}"
print("Release fixture boundary verified: no shared fixture resources or Debug fixture symbols.")
