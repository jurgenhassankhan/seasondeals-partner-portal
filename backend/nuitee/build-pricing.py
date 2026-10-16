"""Keep admin calculation, server save and import defaults identical."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[2]
source = (root / 'backend/nuitee/pricing.js').read_text().split("if (typeof module")[0].rstrip()
block = '// BEGIN GENERATED PRICING\n' + source + '\n// END GENERATED PRICING'
for name in ['admin/js/deal-detail-v5.js', 'backend/xano/approval-publication/pricing.xs', 'backend/xano/production/import-first-nhow-draft.xs', 'backend/xano/production/availability.xs', 'backend/xano/production/prepare.xs']:
    path = root / name
    text = re.sub(r'// BEGIN GENERATED PRICING\n[\s\S]*?// END GENERATED PRICING', '// PRICING_POLICY', path.read_text())
    assert text.count('// PRICING_POLICY') == 1, name
    path.write_text(text.replace('// PRICING_POLICY', block))
