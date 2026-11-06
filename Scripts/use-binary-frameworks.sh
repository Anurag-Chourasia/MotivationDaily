#!/bin/bash
set -euo pipefail

# Scripts/use-binary-frameworks.sh
# Toggles Xcode project between Remote SPM dependencies and Local XCFramework binaries.
# Usage:
#   bash Scripts/use-binary-frameworks.sh --apply    # Switch to local binary mode
#   bash Scripts/use-binary-frameworks.sh --restore  # Switch back to remote SPM mode

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(cd "$REPO_ROOT/.." && pwd)"

PROJ_DIR=$(find "$REPO_ROOT" -maxdepth 1 -name "*.xcodeproj" | head -n 1)
if [ -z "$PROJ_DIR" ]; then
    echo "Error: No .xcodeproj found in $REPO_ROOT" >&2
    exit 1
fi
PBXPROJ="$PROJ_DIR/project.pbxproj"
BAK_FILE="$PROJ_DIR/project.pbxproj.spm.bak"
LOCAL_PKG_DIR="$REPO_ROOT/LocalPackages/SharedKitsBinary"

action="${1:---apply}"

case "$action" in
    --apply)
        echo "Switching $PROJ_DIR to local binary XCFrameworks..."

        # 1. Backup original project.pbxproj if not already backed up
        if [ ! -f "$BAK_FILE" ]; then
            cp "$PBXPROJ" "$BAK_FILE"
            echo "Created backup: $BAK_FILE"
        fi

        # 2. Ensure Frameworks directory exists with XCFrameworks
        if [ ! -d "$REPO_ROOT/Frameworks" ]; then
            if [ -d "$WORKSPACE_ROOT/XCFrameworks" ]; then
                mkdir -p "$REPO_ROOT/Frameworks"
                cp -R "$WORKSPACE_ROOT/XCFrameworks/"*.xcframework "$REPO_ROOT/Frameworks/"
                echo "Copied XCFrameworks from $WORKSPACE_ROOT/XCFrameworks to $REPO_ROOT/Frameworks"
            else
                echo "Error: Neither $REPO_ROOT/Frameworks nor $WORKSPACE_ROOT/XCFrameworks found." >&2
                exit 1
            fi
        fi

        # 3. Create LocalPackages/SharedKitsBinary
        mkdir -p "$LOCAL_PKG_DIR"
        cat <<'EOF' > "$LOCAL_PKG_DIR/Package.swift"
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SharedKitsBinary",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "FoundationKit", targets: ["FoundationKit"]),
        .library(name: "LocalizationKit", targets: ["LocalizationKit"]),
        .library(name: "DesignTokensKit", targets: ["DesignTokensKit"]),
        .library(name: "CommonNetworkingKit", targets: ["CommonNetworkingKit"]),
        .library(name: "SnapshotTestingKit", targets: ["SnapshotTestingKit"]),
        .library(name: "SnapshotTestKit", targets: ["SnapshotTestingKit"]),
        .library(name: "UIComponentsKit", targets: ["UIComponentsKit"]),
        .library(name: "DeveloperProfileKit", targets: ["DeveloperProfileKit"]),
        .library(name: "AuthKit", targets: ["AuthKit"]),
        .library(name: "AuthKitUI", targets: ["AuthKitUI"])
    ],
    targets: [
        .binaryTarget(name: "FoundationKit", path: "../../Frameworks/FoundationKit.xcframework"),
        .binaryTarget(name: "LocalizationKit", path: "../../Frameworks/LocalizationKit.xcframework"),
        .binaryTarget(name: "DesignTokensKit", path: "../../Frameworks/DesignTokensKit.xcframework"),
        .binaryTarget(name: "CommonNetworkingKit", path: "../../Frameworks/CommonNetworkingKit.xcframework"),
        .binaryTarget(name: "SnapshotTestingKit", path: "../../Frameworks/SnapshotTestingKit.xcframework"),
        .binaryTarget(name: "UIComponentsKit", path: "../../Frameworks/UIComponentsKit.xcframework"),
        .binaryTarget(name: "DeveloperProfileKit", path: "../../Frameworks/DeveloperProfileKit.xcframework"),
        .binaryTarget(name: "AuthKit", path: "../../Frameworks/AuthKit.xcframework"),
        .binaryTarget(name: "AuthKitUI", path: "../../Frameworks/AuthKitUI.xcframework")
    ]
)
EOF

        # 4. Patch project.pbxproj
        python3 - <<PYEOF
import re

pbx_path = "$PBXPROJ"
with open(pbx_path, "r") as f:
    content = f.read()

local_ref_id = "LOCALPKG00000000000000001"
local_ref_entry = f'\t\t{local_ref_id} /* XCLocalSwiftPackageReference "SharedKitsBinary" */ = {{\\n\t\t\tisa = XCLocalSwiftPackageReference;\\n\t\t\trelativePath = "LocalPackages/SharedKitsBinary";\\n\t\t}};'

content = re.sub(
    r'(packageReferences = \()[\s\S]*?(\);)',
    f'\\\\1\\n\t\t\t\t{local_ref_id} /* XCLocalSwiftPackageReference "SharedKitsBinary" */,\\n\t\t\t\\\\2',
    content
)

content = re.sub(
    r'(isa = XCSwiftPackageProductDependency;\s+package = )[A-Za-z0-9]+[^;]*;',
    f'\\\\1{local_ref_id} /* XCLocalSwiftPackageReference "SharedKitsBinary" */;',
    content
)

content = re.sub(
    r'/\* Begin XCRemoteSwiftPackageReference section \*/[\s\S]*?/\* End XCRemoteSwiftPackageReference section \*/',
    f'/* Begin XCLocalSwiftPackageReference section */\\n{local_ref_entry}\\n/* End XCLocalSwiftPackageReference section */',
    content
)

with open(pbx_path, "w") as f:
    f.write(content)

print("✓ Successfully patched project.pbxproj to local binary mode.")
PYEOF
        ;;

    --restore)
        echo "Restoring $PROJ_DIR to original SPM configuration..."
        if [ -f "$BAK_FILE" ]; then
            cp "$BAK_FILE" "$PBXPROJ"
            rm -f "$BAK_FILE"
            echo "✓ Restored from $BAK_FILE"
        else
            git checkout "$PBXPROJ" 2>/dev/null || true
            echo "✓ Checked out original $PBXPROJ from git"
        fi
        rm -rf "$LOCAL_PKG_DIR"
        echo "✓ Removed $LOCAL_PKG_DIR"
        ;;

    *)
        echo "Usage: $0 [--apply | --restore]" >&2
        exit 1
        ;;
esac
