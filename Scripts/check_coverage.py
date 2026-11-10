#!/usr/bin/env python3
"""Report exact application line coverage from xcresult; validates governance thresholds."""
import argparse
import json
import subprocess
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('result', type=Path)
    parser.add_argument('--target', default='MotivationDaily.app')
    parser.add_argument('--minimum', type=float, default=None)
    parser.add_argument('--governance', action='store_true', help='Validate 85% Domain/Data and 80% ViewModels')
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
    files = target['files']

    covered, executable = target['coveredLines'], target['executableLines']
    percentage = 100 * covered / executable
    print(f'{args.target}: {covered}/{executable} executable lines ({percentage:.4f}%)')

    if args.governance:
        # AGENTS.md §5.2: Host Apps: Domain & Data >= 85.0%, Presentation (ViewModels) >= 80.0%
        domain_data_files = [f for f in files if '/Domain/' in f.get('path', '') or '/Data/' in f.get('path', '')]
        dd_cov = sum(f['coveredLines'] for f in domain_data_files)
        dd_exe = sum(f['executableLines'] for f in domain_data_files)
        dd_pct = (100 * dd_cov / dd_exe) if dd_exe else 0.0
        print(f'Domain & Data Coverage: {dd_cov}/{dd_exe} ({dd_pct:.2f}%) [Gate: 85.0%]')

        vm_files = [f for f in files if '/Presentation/ViewModels/' in f.get('path', '') or 'ViewModel' in f.get('name', '')]
        vm_cov = sum(f['coveredLines'] for f in vm_files)
        vm_exe = sum(f['executableLines'] for f in vm_files)
        vm_pct = (100 * vm_cov / vm_exe) if vm_exe else 0.0
        print(f'ViewModels Coverage: {vm_cov}/{vm_exe} ({vm_pct:.2f}%) [Gate: 80.0%]')

        if args.json_output:
            args.json_output.write_text(json.dumps({
                'domain_data': {'covered': dd_cov, 'executable': dd_exe, 'percentage': dd_pct},
                'view_models': {'covered': vm_cov, 'executable': vm_exe, 'percentage': vm_pct},
            }, indent=2) + '\n')

        if dd_pct < 85.0 or vm_pct < 80.0:
            print("ERROR: Code coverage below governance threshold!", file=sys.stderr)
            return 1
        return 0

    if args.minimum is not None:
        return 0 if covered * 100 >= executable * args.minimum else 1

    return 0


if __name__ == '__main__':
    sys.exit(main())
