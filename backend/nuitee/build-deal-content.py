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
    'admin/js/deal-detail-v5.js': '  const core = ',
}
for name, marker in targets.items():
    path = root / name
    source = re.sub(r'// BEGIN GENERATED NUITEE CONTENT\n[\s\S]*?// END GENERATED NUITEE CONTENT\n', '', path.read_text())
    assert source.count(marker) == 1, name
    path.write_text(source.replace(marker, block + marker, 1))

path = root / 'backend/xano/production/import-first-nhow-draft.xs'
source = path.read_text()
marker = 'const p=$var.prepared,r=p.offer.rates[0]'
source = source.replace(marker, block + marker, 1)
path.write_text(source)

labels = (root / 'backend/nuitee/amenity-label.js').read_text().split("if (typeof module")[0].rstrip()
label_block = '// BEGIN GENERATED AMENITY LABELS\n' + labels + '\n// END GENERATED AMENITY LABELS\n'
for name in ['js/shared-deal-preview.js','public-preview/js/deal.js','admin/js/deal-detail-v5.js']:
    path = root / name
    source = re.sub(r'// BEGIN GENERATED AMENITY LABELS\n[\s\S]*?// END GENERATED AMENITY LABELS\n', '', path.read_text())
    source = source.replace('  "use strict";\n', '  "use strict";\n' + label_block, 1)
    path.write_text(source)
