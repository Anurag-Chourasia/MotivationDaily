import json, sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
expected = json.loads((root / 'Scripts/dependencies.json').read_text())
locks = list(root.glob('*.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved'))
assert len(locks) == 1, locks
pins = json.loads(locks[0].read_text())['pins']
actual = {p['identity']: p['state'] for p in pins}
assert actual == expected, (actual, expected)
print('All exact versions and commit SHAs match the reviewed dependency record')
