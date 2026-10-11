# Nuitée stap 5 — adminportaal

Status: **backend selectief naar v1 samengevoegd; front-enduitrol en ingelogde browsercontrole nog open**  
Datum: 11 oktober 2026

## Branches

- Xano: `nuitee-step5-admin-2026-10-11` (workspacebranch 12)
- GitHub: `feat/nuitee-step5-admin-2026-10-11`

Alleen de private adminreader is naar `v1` samengevoegd met de back-upoptie aan. Partner-, betaal- en boekingsroutes zijn niet aangepast.

## Wat is gebouwd

Het endpoint `GET /seasondeals-admin/supplier-bookings` verrijkt een leveranciersboeking met de gekoppelde SeasonDeals-order, deal, Nuitée-deal, voucher en checkout-intent. Het adminportaal toont per boeking:

- SeasonDeals-order en deal;
- hotel, verblijf en aantal gasten;
- betaalde klantprijs;
- leverancierstarief;
- verwerkingskosten en Stripe-kosten;
- werkelijke SeasonDeals-marge;
- Nuitée-referentie en interne clientreferentie;
- operationele status in het Nederlands;
- voucher- en QR-status;
- status van de bevestigingsmail;
- duidelijke sandbox- of productieaanduiding.

Oude, onvolledige sandboxrecords worden fouttolerant weergegeven en blokkeren het overzicht niet.

## Gecontroleerde sandboxboeking

Boeking #100 is via Xano Run getest met de bestaande gegevens:

| Veld | Waarde |
|---|---|
| Hotel | nhow Amsterdam RAI |
| Verblijf | 10–12 november 2026 |
| Gasten | 2 |
| Klantprijs | €241,43 |
| Leverancier | €205,20 |
| Verwerking | €2,30 |
| Stripe werkelijk | €0,29 |
| Werkelijke marge | €33,64 |
| Nuitée boekings-ID | `l0kp_BVEf` |
| Clientreferentie | `SD-SBX-4-step4-20261011-checkout03` |
| Voucher | `SD-SBX-100-34Z842RA` |
| Bevestiging | verzonden |
| Financiële afstemming | reconciled |
| Omgeving | sandbox |

De endpointtest slaagde met vijf bestaande supplier-bookings. Daarnaast is de gewijzigde front-end JavaScript syntactisch gecontroleerd en is de boekingsdetailweergave met boeking #100 als fixture getest.

## Livegang

De adminreader is selectief samengevoegd; 15 andere toevoegingen, 10 andere endpoints en middleware zijn uitgesloten. De front-end staat in PR #18 klaar voor uitrol. Nog geen geïntegreerde ingelogde browsercontrole uitgevoerd. Productiedata en echte productieboekingen blijven geblokkeerd totdat de bestaande productiepoort en livegangcontroles zijn doorlopen.

## Vervolgverificatie

CONFIRMED + NHOW vindt order100 (1.51s); ACTION_REQUIRED vindt de bestaande mislukte poging (0.89s); productie geeft nul records (0.08s). Filters worden na verrijking en vóór paginering toegepast. De bron staat naast dit bestand in `nuitee-step5-supplier-bookings.xs`.
