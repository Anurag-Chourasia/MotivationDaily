"""Require successful, nonempty unit, UI and snapshot suites in an xcresult."""
import json
import subprocess
import sys

report = json.loads(subprocess.check_output([
    'xcrun', 'xcresulttool', 'get', 'test-results', 'tests', '--path', sys.argv[1]
], text=True))
expected = {'MotivationDailyTests': [], 'MotivationDailyUITests': [], 'MotivationDailySnapshotTests': []}

def visit(node, bundle=None):
    name = node.get('name', '').removesuffix('.xctest')
    if name in expected:
        bundle = name
    if node.get('nodeType') == 'Test Case' and bundle:
        expected[bundle].append(node.get('result'))
    for child in node.get('children', []):
        visit(child, bundle)

for node in report['testNodes']:
    visit(node)
for bundle, results in expected.items():
    if not results or any(result != 'Passed' for result in results):
        sys.exit(f'{bundle}: expected nonempty, all-passing tests; found {results}')
    print(f'{bundle}: {len(results)} passed')
