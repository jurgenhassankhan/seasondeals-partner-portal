# Server availability — 8 October 2026

## Deployment state

- Existing private GET availability #1140 is published and tested on Xano branch nuitee-availability-2026-10-08; v1/public supplier gates remain closed.
- PR14 merged c4e3f8057bd232b9171330f5997f8ad6bcd481ba. Signed-in Pages catalog verified: one of two approved sandbox deals available; nhow Amsterdam RAI €241.43, image present. Invalid dates invalidate the prior result; 45-second browser refresh observed.
- Additive table supplier_availability_snapshots #105 created empty in Xano (38 tables total). Shared datasource live; no orders/deals changed.
- Internal function supplier/availability/check #306 created from the tested #1140 logic. Compile/save succeeded, but this new function itself has not been run.
- Browser credential protection prevents further Xano interactions even after documented navigation/new-tab recovery. No refresh function, snapshot endpoint or background task has been created/activated.

## Prepared code, not deployed

supplier-availability-refresh.xs refreshes the saved reference stay only, invalidates the old cache before searching, catches provider failures, reuses one sandbox snapshot per deal and checks the current generation before saving.

supplier-availability-snapshot.xs is a private admin-only GET reader. It rechecks current approval, status, approved price, travel period, occupancy/mapping, provider and pricing configuration against a canonical signature; accepts only 60-second fresh snapshots and never enables payment.

nuitee-sandbox-availability-refresh.xs is deliberately inactive. It requests at most ten sandbox mappings sequentially every 45 seconds. This bound is for the current two-deal sandbox test, not production scale. Verify task scheduling limits and overlaps before activation. The generation read/write guard is not an atomic compare-and-set; prevent overlapping workers or replace it with a tested transactional/atomic guard before production.

## Exact continuation

1. Restore Xano browser interaction without changing admin account permissions.
2. Run #306 on deal17, 2026-11-10 → 2026-11-12, two adults; compare with #1140.
3. Create/compile/run refresh function. Verify a single #105 snapshot, success and repeat refresh without duplicate; validate failure clears previous availability.
4. Create/compile/test snapshot API with existing admin guard. Test expired result, draft/reapproval, edited pricing/mapping and provider failure without mutating existing hotel/order workflows; use isolated sandbox fixtures when mutation tests are needed.
5. Create inactive task, manually run, inspect result and record isolation, then activate only on this development branch after scheduling/overlap validation.
6. Switch only the private test catalog to snapshot GET once server updates are proven without an open browser. Current catalog remains working through direct #1140 checks meanwhile.
7. Public catalog/detail release must remain production-gated until production costs, prebook, payment/order/booking flow and end-to-end tests are complete. Never publish sandbox deals to Webflow.
8. Update SEASONDEALS_STATUS.md with actual evidence; this draft is not a completed public step3.

## Validation

Local snapshot policy test passes: expiration, future/overlong timestamps, stale approval signature, changed price/status/approval/minimum nights/mapping/minimum margin, pending snapshot, wrong environment/deal and enabled payment all hide availability. Existing policy/controller/catalog tests passed before PR14 merge; no need to repeat absent changes.
