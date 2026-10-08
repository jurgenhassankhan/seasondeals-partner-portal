# Server availability — 8 October 2026

## Deployed and tested

- Xano access restored using the existing account; no permissions changed.
- Development internal check #306 executed: approved deal17, 10–12 November, two adults. Available, selling price €241.43, supplier €204.22, margin after reserves €28.41; can_pay=false.
- Refresh #307 compiled and executed successfully, writing only table105. Each run owns an independent row; the reader orders started_at DESC, id DESC. A slower older worker cannot overwrite a newer observation. Pending newest observations and failures hide previous availability.
- Private reader #1141 compiled and tested with existing admin guard. Expired deal17 result returned unknown/available=false in 370ms. Approval, mapping and financial signature plus 60-second expiry are checked on every read.
- Task #28 compiled, manual execution completed in 3.02s. Table105 shows deal17 available and fabricated prior deal16 unknown.
- Selective merge to v1: ONLY five additions (two private APIs, two internal functions, one inactive task). Ten unrelated endpoint differences and branch middleware were excluded; destination backup enabled.
- v1 task #32 has a supported 60-second schedule. Activation published. Automatic execution and signed-in updated Pages catalog are being verified before final completion claim.

## Frontend

The private catalog now reads availability-snapshot from v1. Reading the catalog does not search Nuitée; the server refreshes the reference stay independently. The existing private date selection preview retains fresh direct sandbox checks. No public Webflow changes or payment enablement.

## Limits before production

- This task is sandbox-only, bounded to ten mappings. Production needs fair paging, provider rate limits and bounded snapshot retention; append-only snapshots are intentional for safe independent runs, not a final unlimited history design.
- Each available snapshot expires after 60 seconds; checking/provider failure hides the offer until a new successful result. A minute refresh may cause a short conservative visibility gap.
- No exact room quantity is provided by Nuitée; no booking guarantee is implied.
- Public supplier gates stay closed until production costs, prebook, checkout, payment/order/booking and end-to-end tests pass.
- Historical task sources default inactive to prevent accidental activation on import; active deployment must be deliberately configured.

## Validation

Snapshot and catalog tests pass for expired/future/overlong timestamps, changed approval/price/mapping/conditions, pending/unknown/unavailable responses, wrong environment/deal, payment enabled and restoration after a fresh confirmation. JavaScript syntax check passes.
