# SeasonDeals — livegang- en overzetlijst

Laatst bijgewerkt: **11 oktober 2026, Europe/Amsterdam**. Eerste inventaris op basis van de actuele GitHub-status, de gecontroleerde stap-5-uitrol en de Xano-branch/draftcontrole van 11 oktober. Dit is geen claim dat alle historische branches regel voor regel zijn gecontroleerd.

Vast onderhoud: [SEASONDEALS_WERKPROTOCOL.md](SEASONDEALS_WERKPROTOCOL.md). Voortgang en testbewijs: [SEASONDEALS_STATUS.md](SEASONDEALS_STATUS.md).

**Hoofdregel:** stap 4 is sandbox bewezen; stap 5 is als privé-adminfunctionaliteit gepubliceerd en gecontroleerd. Echte Nuitée-productieboekingen zijn nog niet vrijgegeven.

## A. Al geplaatst — niet opnieuw blind overzetten

| ID | Onderdeel | Bron / bestemming | Plaatsing en bewijs | Nog nodig voor publieke productie |
|---|---|---|---|---|
| SD-01 | Nuitée-basisadapter, prijsberekening en boekingopslag | Ontwikkelbranch `nuitee-integration-2026-10-05` → v1; exacte actuele functie-ID's/versies vóór een volgende wijziging TE VERIFIËREN | Volgens status op 6 oktober selectief samengevoegd; sandboxketen en idempotente opslag bewezen | Productiecredentials, kosten/voorwaarden en productiegebruik afzonderlijk verifiëren |
| SD-02 | Private supplier-dealreader, prijsbeheer en workflow | v1 Admin: GET #901, pricing #902, workflow #903; portal main, PR #9 | Aanwezig op v1; prijs/indienen/sandboxgoedkeuring getest | Productieaanbod en importvrijgave ontbreken; admin-goedkeuring alleen opent de publieke poort niet |
| SD-03 | Beschikbaarheid, snapshots, verversing en beveiligde preview | v1 Admin #1260/#1261; taak #32; main PR #15–17. Bronbranches `nuitee-availability-2026-10-08`, `nuitee-step3-final-2026-10-09` | Volgens vastgelegde tests werkzaam in privéportaal, met sandboxaanbod; PR #17 `7044524ff8a7747db4accdaab64d377ab8b45de9` | Providerquota, capaciteit, snapshotbewaring en publieke Webflow-aansluiting |
| SD-04 | Stap 5 adminreader | Xano workspace1 branch12 `nuitee-step5-admin-2026-10-11`, Admin #1666 → v1 Admin #550 | Selectief overgezet en op v1 met order100 getest: 223 statements, 1.23s. Bron: [reader](backend/xano/nuitee-step5-supplier-bookings.xs) | Alleen toekomstige uitbreiding bij SD-12; deze overzetactie is klaar |
| SD-05 | Stap 5 adminpagina's | GitHub `feat/nuitee-step5-admin-2026-10-11` → main/Pages | PR [#18](https://github.com/jurgenhassankhan/seasondeals-partner-portal/pull/18), merge `69a3c855ad7ec2e65832ffe7ebf2cb76c428c459`; Pages run `38168178348` geslaagd; ingelogde filters/details/financiën/voucher/mail gecontroleerd | Geen resterende stap-5-portaluitrol |
| SD-06 | Publieke sandboxblokkades | v1 Public API #63/#64/#71, checkout #68, order #65 | Volgens status sandboxdeals uit publieke routes geweerd; behouden bij stap-5-uitrol | Pas gecontroleerd aanpassen binnen SD-13 na productie-go/no-go |

## B. Nog voorbereiden / overzetten / vrijgeven

“Doel TE VERIFIËREN” betekent dat de exacte productieroute nog niet is vastgesteld. Deze rijen zijn geen automatische mergelijst.

| ID | Onderdeel | Juiste bron / huidige staat | Volgende actie en afhankelijkheid | Doel / vrijgave |
|---|---|---|---|---|
| SD-07 | Stap 4 betaal- en boekingsorchestratie | Xano branch11 `nuitee-step4-2026-10-11`; #452 betaalverificatie, #453 claim, #454 prepare, #455 sandboxsession, #456 fulfillment. GitHub `feat/nuitee-step4-2026-10-11`, map `xano/nuitee-step4-2026-10-11/` | Sandbox bewezen. Actuele gepubliceerde bron en exact broncommit vastleggen; productieversie maken zonder testspecifieke aannames; afhankelijk van SD-10/11/12 | Productiedoel-ID's TE VERIFIËREN; niet vrijgegeven |
| SD-08 | Kostenafstemming, voucher en mail | Branch11 #461 `finalize_sandbox`, #464 `render_confirmation`; `finalize_sandbox.xs`, `render_confirmation.xs`, `confirmation-preview.html` op stap-4-GitHub-branch | Sandbox bewezen, nieuwe mail door eigenaar goedgekeurd. Algemene productieroute en ontvanger-/verzendbeleid voorbereiden; niet de eenmalige testmailfunctie kopiëren. Afhankelijk van SD-07/10 | Productiedoel TE VERIFIËREN; sandboxversie niet naar v1 overgezet |
| SD-09 | Callback na Stripe-betaling | Branch11 Stripe #1622 `POST webhooks/nuitee-sandbox`; export `webhooks_nuitee_sandbox.xs` | Sandboxcallback/testwebhook werkt. Productiewebhookbeveiliging, eventvalidatie, idempotentie en route afzonderlijk voorbereiden; geen sandbox-URL als livewebhook gebruiken | Productieroute/configuratie TE VERIFIËREN; niet vrijgegeven |
| SD-10 | Stripe live, Nuitée-productietoegang en mailconfiguratie | Stripe test en Nuitée sandbox bewezen; productieconfiguratie niet opnieuw volledig geverifieerd | Toegang, keys op juiste plek, webhook, valuta/kosten, afzender en autorisatie vastleggen zonder geheimen in Git. Echte transacties alleen binnen specifieke autorisatie | Configuratie plus gecontroleerde liveverificatie nog open |
| SD-11 | Productie-import van aanbod | Xano `nuitee-deal-import-2026-10-07`, import #782 volgens status ongepubliceerd concept | Actuele draft herlezen; server-side offerverificatie en atomaire deal/supplier-opslag afronden; productiebron/duplicaatcontrole bewijzen | Doel TE VERIFIËREN; testdeals #16/#17 niet automatisch omzetten |
| SD-12 | Fout-, annulerings- en herstelafhandeling | Basisannulering sandbox bewezen; volledige betaalroute/productieherstel nog verder uitwerken | Onder meer betaalde checkout-intents zonder supplier_booking zichtbaar maken, time-outs/retries, onzekere leverancierstatus, refund/voucherconsistentie en schaalgedrag controleren. Geen herboeking zonder statuscontrole | Beoogde vervolgfase stap 7; exacte artefacten TE VERIFIËREN |
| SD-13 | Webflow-klantreis en stap-6-bevestiging | Main/Pages PR #19, commit `1fbbcb4e4cf96e94eb276165ab2347dd5f499697`; Xano branch14 Public152 POST1985 + functie591; Webflow draftpagina `6acbead36631ab0d5cf3b9fd`, `/boeking-bevestiging` | Reader + aangesloten browser met bestaande order100 bevestigd, logo/QR zichtbaar; lokale negatieve controles geslaagd; Pages `38170709509` geslaagd. Success/cancel in591 gepubliceerd. Geen nieuwe Stripe-doorverwijzing afgerekend/getest | Webflow blijft concept, geen merge naar v1. Productieklantreis en vrijgave nog open; geen openbare verkoop geactiveerd |
| SD-14 | Overige platformlivegang | Bestaande statussecties voor Stripe, hotelonboarding, SiteMinder, content/juridisch en domeinen | Per release bepalen welke punten vereisten zijn; echte SiteMinder-verbinding niet verwarren met demo. Dit werk is niet automatisch onderdeel van de Nuitée-merge | Exacte scope en bewijs vóór betreffende release vastleggen |

## C. Achterlaten / eerst beoordelen

| ID | Test- of historisch onderdeel | Behandeling |
|---|---|---|
| TEST-01 | Branch11 #457 `lookup_sandbox_reference`, #458 `reconcile_test_intent4`, #459 `create_step4_test03`, #460 `register_sandbox_webhook`, #462 `test_confirmed_replays`, #463 `send_approved_order100_mail`, #465 `test_confirmation_v2` | Test-/diagnostische hulpfuncties; niet als groep naar productie kopiëren. Eventueel herbruikbare logica alleen na afzonderlijke beoordeling. #465 is volgens status na verzending een alleen-lezen aflevercontrole. |
| TEST-02 | Vier huidige ongepubliceerde drafts op branch11: #454 prepare, #457 lookup, #458 reconcile, #463 approved mail | Op 11 oktober in Xano zichtbaar bevestigd. Bewaren als concept; niet automatisch publiceren of als geteste gepubliceerde versie aanwijzen. Exacte inhoud/diff vóór hergebruik controleren. |
| TEST-03 | Branch12 bevat kopieën van stap-4-functies #502–515 en callback #1722 | Bij stap 5 alle 15 toevoegingen uitgesloten. Branch12 is geen tweede productiebron voor stap 4. Alleen adminreader #1666 is overgezet. |
| TEST-04 | Tien overige afwijkende endpoints en middleware in de stap-5-branchvergelijking | Uitgesloten: vijf demo-integratieroutes #1739–1743 en vijf v1 partnerintegratieroutes #1706/#1708/#1709/#1710/#1711. Niet zonder inhoudelijke vergelijking overschrijven; doel-ID's vóór eventueel vervolg verifiëren. |
| TEST-05 | Historische checkpoints, `finalize_with_mail_PENDING_APPROVAL.xs`, eenmalige testorders en testdeals | Audit/historie, geen actuele releasebron. Orders98/99 niet opnieuw resetten/herboeken; intent4 staat volgens status op manual_attention. Geen automatisch verwijderen of promoten van testgegevens. |
| TEST-06 | Oude ontwikkel- en back-upbranches | Een achtergebleven branch is geen bewijs van nog open werk. Eerst met bestemming vergelijken; pas daarna afzonderlijk beslissen over opruimen. |

## D. Eerstvolgende releasevolgorde

1. Bronversies en exacte doelen van SD-07–13 vastleggen; drafts en historische exports vergelijken.
2. Productietoegang/configuratie en importvoorwaarden afronden.
3. Productiegeschikte backend voorbereiden en relevante fout-/annuleringsscenario's verifiëren.
4. Publieke frontend/succespagina aansluiten terwijl de productiepoort gesloten blijft.
5. Concrete release-selectie, terugval en specifieke autorisatie/go-no-go registreren.
6. Gecontroleerd plaatsen en verifiëren; publieke vrijgave pas als de voorwaarden aantoonbaar voldaan zijn.
7. Beide GitHub-bestanden bijwerken met werkelijke bestemming en uitkomst.

Dit is afhankelijkheidsvolgorde, geen toestemming om nu echte transacties uit te voeren.

## E. Releaseboek

| Release-ID | Datum | Selectie / uitsluitingen | Bestemming en bewijs | Terugval / restpunt |
|---|---|---|---|---|
| REL-20261011-ADMIN5 | 11 oktober 2026 | Alleen Xano GET supplier-bookings + tien GitHub-bestanden uit PR #18; 15 Xano-toevoegingen, 10 andere endpoints en middleware uitgesloten | v1 #550 + main/Pages; merge `69a3c855ad7ec2e65832ffe7ebf2cb76c428c459`, Pages `38168178348`; portal ingelogd geverifieerd | Xano-doelback-upoptie was aangevinkt; exacte gegenereerde back-upnaam vóór herstel TE VERIFIËREN. GitHub-terugval: gerichte revert van merge, met behoud van latere wijzigingen. |
| REL-20261011-CONFIRM6 | 11 oktober 2026 | PR #19 bevestigingsassets + reader1985; branch14 functie591 alleen twee return-URLs. Kopieën overige logica en oude drafts uitgesloten | Main/Pages `1fbbcb4e4cf96e94eb276165ab2347dd5f499697`, run `38170709509` success; branch14 reader en591 gepubliceerd; bestaande order100 in browser bevestigd | Webflow pagina blijft draft; productie gesloten. Voor/na-bron591 in backend/xano; geen nieuwe transacties. Nieuwe Stripe-doorverwijzing niet end-to-end herhaald |
| DOC-20261011-PROTOCOL | 11 oktober 2026 | Centrale lijst, protocol, AGENTS en verwijzing vanuit status | Documentatie op main; geen software/configuratie uitgerold | Bij iedere volgende wijziging actualiseren |

Voor iedere volgende release: voeg een rij toe en leg daarnaast concrete bron/doel-ID's, geselecteerde versies, afhankelijkheden, autorisatie, testbewijs, uitrolresultaat en terugval vast. Verwijder oude bewijsregels niet; markeer ze als vervangen.

## F. Wat nog niet exact vastgesteld is

- Actuele commitpin en volledige gepubliceerde bronselectie voor de toekomstige productieversie van stap 4.
- Productie-endpoint/functie-ID's en productiecredentials/configuratiestatus.
- Exacte verschillen in alle oudere branches; de vier drafts zijn geteld, niet nu inhoudelijk herbeoordeeld.
- Productiego/no-go en gecontroleerde echte transactie.

Deze open verificaties staan hier bewust, zodat een volgende sessie ze niet als afgerond kan aannemen.

## G. Stap 6 — geplaatste sandboxselectie 11 oktober 2026

- Bron main `69693ca911915e0d29b70eba45aec09759e48410`; GitHub werkbranch `feat/nuitee-step6-confirmation-2026-10-11`.
- Xano branch14 is kopie van gepubliceerde branch11, niet van drafts. Selectie: nieuwe Public API152 endpoint1985 en twee return-URL-regels in functie591. Beide gepubliceerd, nul drafts na publicatie. Overige gekopieerde onderdelen niet naar v1 overzetten.
- Nieuwe Webflow-conceptpagina `6acbead36631ab0d5cf3b9fd`; geen bestaande pagina gewijzigd, geen volledige site gepubliceerd. Terugval: nieuwe pagina in draft houden; uitsluitend nieuwe bevestigingsassets/routering terugnemen bij latere release.
- Bevestigingslookup is alleen-lezen. Geen dataherstel nodig zolang geen records worden gewijzigd; branchkopie is geen databack-up.
- PR #19 → main `1fbbcb4e4cf96e94eb276165ab2347dd5f499697`; Pages `38170709509` success. Aangesloten browsercheck met bestaande sandboxorder100 geslaagd, logo en lokale QR zichtbaar. Alleen ontvangst/statusweergave bewezen; geen verse Stripe-checkout/redirect uitgevoerd.
- Functie591 gebruikt voor nieuwe branch14-testsessies success `https://jurgenhassankhan.github.io/seasondeals-partner-portal/public-preview/boeking-bevestiging.html#session_id={CHECKOUT_SESSION_ID}` en cancel dezelfde pagina met `#cancelled=1`. Branch11 #455 en geregistreerde sandboxwebhook blijven ongewijzigd; bestaande Stripe-sessies behouden hun oude URLs.
- Reader vereist bijpassende sandboxtestsessie en verloopt na24uur; daarna bevestigingsmail gebruiken. Geen order-ID als toegang, geen gastmail/interne kosten in antwoord; no-store/private en no-referrer gepubliceerd.
- Terugval functie591: exact `backend/xano/create-sandbox-session-before-step6.xs` vergelijken/herstellen op branch14; actuele versie `backend/xano/create-sandbox-session-step6.xs`. Frontend gericht PR19 terugnemen; Webflow-concept ongepubliceerd houden. Geen databaseherstel nodig.
- Open: productiegeschikte klantreis en Webflow-publicatie, productieconfiguratie en go/no-go. Dit sandboxresultaat maakt stap4/5 niet opnieuw open en is geen vrijgave voor echte boekingen.
