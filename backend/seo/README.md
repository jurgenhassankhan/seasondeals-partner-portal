# Deal SEO preparation — not connected to production

`deal-projection.cjs` creates a stable URL, escaped SEO head and complete initial HTML. `deal-renderer.cjs` is generated from the existing customer layout by `python backend/seo/build-renderer.py`; regenerate when that layout changes. No live frontend source was changed.

The future server adapter supplies the existing verified public projection plus approval/deletion metadata from the deal row. Recheck provider=nuitee, environment=production, is_enabled and current approval server-side. Public response `images` is supported; never pass raw supplier mappings. These modules do not replace the existing photo provenance or perceptual duplicate checks.

Persist the first slug in the server mapping and always reuse it. Default indexable=false preserves prelaunch policy. Initial booking controls remain disabled until the existing public service revalidates current data. No inventory or price guarantee is asserted in structured data.

Still required before release:
- Webflow CMS schema and template bindings for HTML, SEO title/description, canonical and Xano identity. Template currently has a wrong historical /cookies canonical; replace as part of template migration. All historical items stay offline.
- Server-only Webflow credential configured in Xano. No token in frontend, Git or chat.
- Transactional durable outbox with per-deal version, exclusive worker lease, persisted CMS id/slug, idempotent create recovery, retries/backoff, and reconciliation. Every retry reads current authoritative status so stale approval cannot republish a withdrawn deal. Update jobs also cover content changes and expiry. A failed public-list fetch is not an empty authoritative snapshot.
- Admin sync status, actual publish/withdraw/sitemap proof and verified server HTML on a real deal. Do not add a second owner approval action.
- CMS capacity from public Premium documentation is 20,000 items/40 collections; account enforcement still to verify before batch import.

Prepared CMS fields and a RichText template binding are now saved, with a draft-only technical fixture. Template metadata placeholders still require a published HTML proof. No runtime, credential, outbox or automatic sync is deployed. See BUILD-20261016-CMS-TEMPLATE in both project documents.
