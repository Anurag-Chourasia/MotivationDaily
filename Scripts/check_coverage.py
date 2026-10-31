#!/usr/bin/env python3
"""Report exact application line coverage from xcresult; never exclude source files."""
import argparse
import json
import subprocess
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('result', type=Path)
    parser.add_argument('--target', default='MotivationDaily.app')
    parser.add_argument('--minimum', type=float, default=100.0)
    parser.add_argument('--json-output', type=Path)
    args = parser.parse_args()
    result = subprocess.run(
        ['xcrun', 'xccov', 'view', '--report', '--json', str(args.result)],
        check=True, capture_output=True, text=True,
    )
    report = json.loads(result.stdout)
    targets = [target for target in report['targets'] if target['name'] == args.target]
    if len(targets) != 1 or not targets[0]['executableLines']:
        parser.error(f'Expected one non-empty coverage target: {args.target}')
    target = targets[0]
    covered, executable = target['coveredLines'], target['executableLines']
    percentage = 100 * covered / executable
    print(f'{args.target}: {covered}/{executable} executable lines ({percentage:.4f}%)')
    print('Files below 100%:')
    for item in sorted(target['files'], key=lambda item: item['executableLines'] - item['coveredLines'], reverse=True):
        missing = item['executableLines'] - item['coveredLines']
        if missing:
            print(f"  {missing:4d} uncovered  {item['name']} ({item['coveredLines']}/{item['executableLines']})")
    if args.json_output:
        args.json_output.write_text(json.dumps(target, indent=2) + '\n')
    # Compare unrounded values: 99.9999% does not pass a 100% requirement.
    return 0 if covered * 100 >= executable * args.minimum else 1


if __name__ == '__main__':
    sys.exit(main())
