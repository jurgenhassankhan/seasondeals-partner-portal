# Sandbox availability — 8 October 2026

Private API: `GET /supplier-deals/{deal_id}/availability?checkin=YYYY-MM-DD&checkout=YYYY-MM-DD&guests=2`, admin authentication and superadmin/platform_admin only, `X-Branch: nuitee-availability-2026-10-08`.

The route reads existing records, searches fresh Nuitée rates, matches the approved hotel/room/board/occupancy/cancellation terms, keeps the approved selling price, checks the stored minimum margin, and detects changed local charges. It never writes deals, books, pays, or publishes anything. One room, the approved adult occupancy, EUR and sandbox only. Search is capped at 50 rates; absence of a compatible rate means unavailable **for this deal/query**, not proof the entire hotel is sold out.

`quantity=null` is intentional. The tested response does not give an exact stock count; rate-array length must never be used as a room count. Snapshots last at most 60 seconds; this does not reserve a room or guarantee availability. The authenticated website preview refreshes after 45 seconds, invalidates on input changes and discards late responses. Network failures show unknown, not an old available state. No payment path is included.

Pricing uses stored costs, conservative cent rounding and a sandbox processing reserve of at least EUR 1.30 from the previously tested booking. These are **reserves**, not final Stripe/Nuitée charges. Production requires fresh prebook, payment-method costs, server-side checkout binding/idempotency and financial reconciliation. It must never trust a client-provided price or offer ID.

Observed API test: deal 17, nhow Amsterdam RAI, 10–12 November 2026, 2 adults. A new search returned EUR 198.96 supplier price and EUR 21.92 excluded local fees. The approved selling price stayed EUR 241.43. The final policy blocked the result as `conditions_changed`; the original deal had no excluded fees. Existing deal records were not changed. Invalid same-day checkout was blocked before search in 50ms.

Entry page: `nuitee-availability-preview.html?portal=admin&id=17`. The preview uses the existing admin session. Changes are prepared on the feature branch; browser-to-private-API/CORS and visual end-to-end verification remain required before portal release.

Public Webflow and Xano v1 supplier publication/checkout guards remain intact. This is a sandbox implementation checkpoint, **not completion of the public production availability rollout**. Production reference-date/window synchronization and automatic public removal/restoration remain to be connected after production booking validation; a failure for one chosen date must not globally archive the deal. Metadata/freshness must be persisted server-side for catalog filtering, with unknown/expired snapshots hidden until refreshed.

Run `node tests/nuitee-availability-policy.test.js` and `node tests/supplier-availability-controller.test.js`.


## Server-side room photos — 16 October 2026

Xano v1 helper804 `supplier/production/select_room_photos` downloads original JPEG/PNG bytes from the approved provider image host, rejects redirects, limits file size/decoded dimensions/time/candidate count, and checks SHA256 plus a 64-bit grayscale area hash. At most five distinct pictures are returned. Unsupported or damaged images are skipped; zero valid pictures blocks the operation. This detects identical/reencoded/resized pictures, not every possible crop or heavily edited duplicate. It does not certify the supplier's photography independently.

The helper is embedded from `photo-selector.js` using `python backend/nuitee/build-photo-selector.py`. Jimp is pinned to1.6.0. Its area-based hash is versioned `sha256+dhash64-area-v2`; the earlier Pillow/Lanczos `sha256+dhash64-v1` remains supported for existing galleries, and hashes from those algorithms must not be mixed in one gallery. Run `npm ci --prefix backend/nuitee --ignore-scripts` then `npm test --prefix backend/nuitee`.

Import802 obtains roomMapping=true and only uses room.photos matching the actual offer's mappedRoomId. All photo work happens before the transaction that creates the draft and supplier record. The existing bounded Amsterdam example, standard room-only/non-refundable and included-fee requirements remain; this is not a nationwide scheduler. Optional import_id enables one explicitly identified import and retries under the existing owner lock. Text now uses the actual offered room name.

Refresh803 accepts deal_id and optional save. With save=false/omitted it previews the confirmed room candidates without writing. With save=true it calls804 itself, then rechecks the draft and unchanged supplier mapping under locks before replacing gallery metadata. It no longer accepts caller-provided photo hashes. Workflow903 accepts both known algorithm versions and still requires review before approval.

Verified live:804 selected five real room photos in11.11s; published803 automatically refreshed draft18 in10.53s with five matched photos. Import802 correctly refused the currently returned offers before database writes because no mapped standard NRFN room-only offer met the included-fee rule. A new-draft positive end-to-end import remains unproven. Do not mark nationwide automation complete or weaken price/fee constraints just to make the photo test pass.
