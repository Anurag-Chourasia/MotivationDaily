import json, tempfile, subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
expected = json.loads((root / 'Scripts/dependencies.json').read_text())
names = {
    'developerprofilekit': 'DeveloperProfileKit',
    'commonnetworking': 'CommonNetworking',
    'foundationkit': 'FoundationKit',
    'localizationkit': 'LocalizationKit',
    'designtokenskit': 'DesignTokensKit',
    'uicomponentskit': 'UIComponentsKit',
    'snapshottestkit': 'SnapshotTestKit'
}
with tempfile.TemporaryDirectory(prefix='verified-kits-') as temp:
    for identity, pin in expected.items():
        if identity not in names:
            continue
        name = names[identity]
        p = Path(temp) / name
        subprocess.run(['git', 'clone', '--quiet', 'https://github.com/Anurag-Chourasia/' + name + '.git', str(p)], check=True)
        subprocess.run(['git', '-C', str(p), 'checkout', '--detach', pin['revision']], check=True)
        assert subprocess.check_output(['git', '-C', str(p), 'rev-parse', 'HEAD'], text=True).strip() == pin['revision']
        # SnapshotTestKit tests run on iOS target, others on macosx
        if identity != 'snapshottestkit':
            subprocess.run(['xcrun', 'swift', 'test', '--package-path', str(p), '--triple', 'arm64-apple-macosx14.0', '-Xswiftc', '-strict-concurrency=complete', '-Xswiftc', '-warnings-as-errors'], check=True)
print('All SPM dependencies cloned, pinned revisions verified, and package tests passed!')
