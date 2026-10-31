"""Reject visual literals in app source; keep data/algorithm constants out of this policy."""
from pathlib import Path
import json, re, sys
from collections import Counter
root = Path(__file__).resolve().parents[1]
source = root / 'MotivationDaily'
files = list(source.rglob('*.swift'))
if not files:
    sys.exit('No MotivationDaily Swift source files found; refusing an empty scan.')
patterns = {
    'shorthand color': r'(?<![\w.])\.(?:primary|secondary|accentColor|white|black|gray|red|green|blue|yellow|orange|clear)\b',
    'inline font role': r'\.font\(\.(?:largeTitle|title|title2|title3|headline|subheadline|body|callout|footnote|caption|caption2)\b',
    'raw color': r'\b(?:Color|UIColor)\s*\(|\bColor\.(?:primary|secondary|accentColor|white|black|gray|red|green|blue|yellow|orange|clear)\b',
    'numeric visual argument': r'\b(?:spacing|width|height|minWidth|minHeight|maxWidth|maxHeight|minimum|cornerRadius|lineWidth|radius|minLength|size)\s*:\s*\d',
    'numeric visual modifier': r'\.(?:padding|cornerRadius|opacity|scaleEffect|lineLimit)\(\s*\d',
    'numeric edge padding': r'\.padding\((?:\.[A-Za-z]+|\[[^]]+\])\s*,\s*\d',
    'raw point property': r'\b(?:var|let)\s+\w+\s*:\s*CGFloat\s*(?:=\s*\d|\{\s*\d)',
    'conditional line limit': r'\.lineLimit\([^\n]*(?:\?|:)\s*\d',
    'implicit padding': r'\.padding\((?:\.[A-Za-z]+)?\)',
}
failures=[]
for path in files:
    if '.generated.' in path.name: continue
    for number, line in enumerate(path.read_text().splitlines(), 1):
        if line.lstrip().startswith('//'): continue
        # Mutable model state is not a design dimension. Hex parsing is a data conversion utility.
        if '@Published var scrollOffset:' in line: continue
        for rule, pattern in patterns.items():
            if re.search(pattern, line): failures.append(f'{path.relative_to(root)}:{number}: {rule}: {line.strip()}')
# Track legacy violations by file/rule/text, allowing line numbers to move.
counts = Counter(re.sub(r":\d+: ", ": ", item, count=1) for item in failures)
baseline_path = root / 'Scripts/design-token-baseline.json'
if '--record-baseline' in sys.argv:
    baseline_path.write_text(json.dumps(dict(sorted(counts.items())), indent=2) + '\n')
    print(f'Recorded {sum(counts.values())} existing violations across {len(files)} Swift files.')
    sys.exit(0)
baseline = Counter(json.loads(baseline_path.read_text())) if baseline_path.exists() else Counter()
new = counts - baseline
if new:
    print('New design-token violations:\n' + '\n'.join(new))
    sys.exit(1)
print(f'Scanned {len(files)} Swift files; no new violations. {sum(counts.values())} legacy violations remain.')
