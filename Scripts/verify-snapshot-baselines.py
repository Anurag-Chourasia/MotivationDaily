"""Fail before XCTest if any declared component baseline is missing."""
import re
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / 'MotivationDailySnapshotTests/ComponentSnapshotTests.swift'
text = source.read_text()
cases = re.findall(r'func (test\w+)\(\).*?named: "([^"]+)"', text, re.S)
if not cases:
    sys.exit('No snapshot declarations found')
for test, name in cases:
    for variant in ['light', 'dark', 'accessibility']:
        baseline = source.parent / '__Snapshots__' / source.stem / f'{test}.{name}-{variant}.png'
        if not baseline.is_file():
            sys.exit(f'Missing reviewed baseline: {baseline}')
print(f'Found {len(cases) * 3} reference images; visual review remains required.')
