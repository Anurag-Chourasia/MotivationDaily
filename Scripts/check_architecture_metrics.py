#!/usr/bin/env python3
"""
check_architecture_metrics.py
Validates the Ecosystem Architectural Governance Specification Section 4.3 Component Sizing
and Section 5 Quality Gates across Motivation Daily.
"""

import os
import sys
import argparse

# Component Size Budget Matrix
BUDGETS = {
    "views": {"file_max": 100, "role": "SwiftUI View (*View.swift)"},
    "components": {"file_max": 70, "role": "Atomic UI Component (in Components/)"},
    "view_models": {"file_max": 200, "role": "ViewModel (*ViewModel.swift)"},
    "use_cases": {"file_max": 50, "role": "Domain UseCase (*UseCase.swift)"},
    "entities": {"file_max": 80, "role": "Domain Entity (*Entity.swift / *Model.swift)"},
    "protocols": {"file_max": 40, "role": "Repository Protocol (*Repository.swift)"},
    "errors": {"file_max": 50, "role": "Domain Error (*Error.swift)"},
    "repositories": {"file_max": 150, "role": "Repository Impl (*Repository.swift in Data/)"},
    "container": {"file_max": 150, "role": "Composition Root (AppContainer.swift)"},
}

MAX_LINE_CONTENT_LEN = 120

def classify_component(rel_path):
    filename = os.path.basename(rel_path)
    if "Tests" in rel_path:
        return None
    if filename == "AppContainer.swift":
        return "container"
    if rel_path.startswith("Domain/UseCases/") or filename.endswith("UseCase.swift"):
        return "use_cases"
    if rel_path.startswith("Domain/Repositories/"):
        return "protocols"
    if rel_path.startswith("Domain/Entities/"):
        return "entities"
    if rel_path.startswith("Domain/Errors/"):
        return "errors"
    if rel_path.startswith("Data/Repositories/"):
        return "repositories"
    if "Components/" in rel_path and filename.endswith("View.swift"):
        return "components"
    if filename.endswith("ViewModel.swift"):
        return "view_models"
    if filename.endswith("View.swift"):
        return "views"
    return None

def check_file(full_path, rel_path):
    with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()
    
    file_length = len(lines)
    comp_type = classify_component(rel_path)
    
    line_violations = []
    trailing_ws = []
    
    for idx, raw_line in enumerate(lines, start=1):
        # Trailing whitespace
        if raw_line.rstrip("\n") != raw_line.rstrip():
            trailing_ws.append(idx)
        # Content length without leading indent
        stripped = raw_line.lstrip(" \t").rstrip("\r\n")
        if len(stripped) > MAX_LINE_CONTENT_LEN:
            line_violations.append((idx, len(stripped)))
            
    size_violation = None
    if comp_type and comp_type in BUDGETS:
        limit = BUDGETS[comp_type]["file_max"]
        if file_length > limit:
            size_violation = {
                "type": comp_type,
                "role": BUDGETS[comp_type]["role"],
                "length": file_length,
                "limit": limit,
                "excess": file_length - limit
            }
            
    return {
        "file": rel_path,
        "length": file_length,
        "comp_type": comp_type,
        "trailing_ws": trailing_ws,
        "line_violations": line_violations,
        "size_violation": size_violation
    }

def main():
    parser = argparse.ArgumentParser(description="Check Architecture Component Sizing Metrics")
    parser.add_argument("--root", default="MotivationDaily", help="Root directory to scan")
    parser.add_argument("--strict", action="store_true", help="Fail if any sizing violation exists")
    parser.add_argument("--strict-formatting", action="store_true", default=True,
                        help="Fail on trailing whitespace or line content length violations")
    args = parser.parse_args()

    project_dir = os.path.abspath(args.root)
    if not os.path.exists(project_dir):
        print(f"Error: Directory {project_dir} not found.")
        sys.exit(1)

    results = []
    for root, _, files in os.walk(project_dir):
        for f in files:
            if not f.endswith(".swift"):
                continue
            full_path = os.path.join(root, f)
            rel_path = os.path.relpath(full_path, project_dir)
            results.append(check_file(full_path, rel_path))

    formatting_errors = 0
    size_violations = []

    print("=" * 80)
    print("🏛️  ECOSYSTEM ARCHITECTURAL SIZING & FORMATTING AUDIT")
    print("=" * 80)

    for r in results:
        if r["trailing_ws"]:
            print(f"❌ [Trailing Whitespace] {r['file']}: lines {r['trailing_ws']}")
            formatting_errors += len(r["trailing_ws"])
        if r["line_violations"]:
            for line_no, length in r["line_violations"]:
                print(f"❌ [Line Content > 120] {r['file']}:{line_no} ({length} chars)")
                formatting_errors += 1
        if r["size_violation"]:
            size_violations.append(r)

    print("-" * 80)
    print(f"Formatting Invariants: {'✅ PASSED' if formatting_errors == 0 else f'❌ {formatting_errors} VIOLATIONS'}")
    print(f"Component Size Violations: {len(size_violations)} files exceeding budget")
    print("-" * 80)

    if size_violations:
        print("\nOversized Components Breakdown:")
        for r in sorted(size_violations, key=lambda x: x["size_violation"]["excess"], reverse=True):
            sv = r["size_violation"]
            print(f"  • {r['file']} ({sv['role']}):")
            print(f"      Actual: {sv['length']} lines | Limit: {sv['limit']} lines (Excess: +{sv['excess']})")

    print("=" * 80)

    if formatting_errors > 0:
        sys.exit(1)
        
    if args.strict and size_violations:
        print("❌ Sizing budget violations detected in strict mode.")
        sys.exit(1)

    print("✅ Audit complete.")
    sys.exit(0)

if __name__ == "__main__":
    main()
