"""Embed the same supplier content projection in each runtime; no hand-maintained copies."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[2]
js = (root / 'backend/nuitee/deal-content.js').read_text().split("if (typeof module")[0].rstrip()
block = '// BEGIN GENERATED NUITEE CONTENT\n' + js + '\n// END GENERATED NUITEE CONTENT\n'
targets = {
    'backend/xano/production/import-first-nhow-draft.xs': '        const response=$var.rates_http.response',
    'backend/xano/approval-publication/workflow.xs': 'const supplier=$var.supplier,hotel=',
    'backend/xano/approval-publication/list.xs': 'const fields = ',
    'backend/xano/approval-publication/detail64.xs': 'const fields = ',
    'backend/xano/approval-publication/detail71.xs': 'const fields = ',
    'js/shared-deal-preview.js': '  const params = ',
}
for name, marker in targets.items():
    path = root / name
    source = re.sub(r'// BEGIN GENERATED NUITEE CONTENT\n[\s\S]*?// END GENERATED NUITEE CONTENT\n', '', path.read_text())
    assert source.count(marker) == 1, name
    path.write_text(source.replace(marker, block + marker, 1))
