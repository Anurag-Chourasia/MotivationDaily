#!/usr/bin/env python3
"""Enforce strict flake quarantine policy with mandatory owner, SLAs, and removal criteria (IOS-24)."""

import json
import sys
from datetime import datetime, date
from pathlib import Path

MAX_QUARANTINE_BUDGET = 2
MAX_QUARANTINE_DAYS = 7

root = Path(__file__).resolve().parents[1]
registry_file = root / "FLAKE_QUARANTINE.json"

if not registry_file.exists():
    print("No FLAKE_QUARANTINE.json found; creating empty registry.")
    registry_file.write_text("[]\n")
    sys.exit(0)

try:
    data = json.loads(registry_file.read_text())
except Exception as exc:
    sys.exit(f"Invalid JSON in FLAKE_QUARANTINE.json: {exc}")

if not isinstance(data, list):
    sys.exit("FLAKE_QUARANTINE.json root must be a JSON array of quarantine records.")

if len(data) > MAX_QUARANTINE_BUDGET:
    sys.exit(
        f"Quarantine budget exceeded! Active: {len(data)}, Maximum allowed: {MAX_QUARANTINE_BUDGET}. "
        "Resolve existing flaky tests before adding more."
    )

today = date.today()
required_keys = [
    "test_identifier",
    "owner",
    "ticket",
    "quarantined_date",
    "target_removal_date",
    "root_cause_hypothesis",
    "removal_criteria",
]

for idx, record in enumerate(data):
    if not isinstance(record, dict):
        sys.exit(f"Quarantine record #{idx} must be an object.")
    
    for key in required_keys:
        if key not in record or not str(record[key]).strip():
            sys.exit(f"Quarantine record #{idx} missing required non-empty field: '{key}'.")
    
    try:
        q_date = datetime.strptime(record["quarantined_date"], "%Y-%m-%d").date()
    except ValueError:
        sys.exit(f"Quarantine record #{idx} invalid quarantined_date format (must be YYYY-MM-DD).")
    
    try:
        r_date = datetime.strptime(record["target_removal_date"], "%Y-%m-%d").date()
    except ValueError:
        sys.exit(f"Quarantine record #{idx} invalid target_removal_date format (must be YYYY-MM-DD).")
    
    duration = (r_date - q_date).days
    if duration > MAX_QUARANTINE_DAYS:
        sys.exit(
            f"Quarantine record '{record['test_identifier']}' exceeds maximum {MAX_QUARANTINE_DAYS}-day SLA "
            f"({duration} days specified: {record['quarantined_date']} -> {record['target_removal_date']})."
        )
    
    if r_date < today:
        sys.exit(
            f"Quarantine expired for '{record['test_identifier']}' on {record['target_removal_date']}! "
            f"Owner: {record['owner']}, Ticket: {record['ticket']}. Must fix or complete removal criteria."
        )

print(f"Flake quarantine policy verified: {len(data)} test(s) quarantined within active SLA (budget: {MAX_QUARANTINE_BUDGET}).")
