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
| SD-12 | Fout-, annulerings- en herstelafhandeling | Incidentreader branch15 Admin157 #2106 gepubliceerd → v1 Admin3 #2227; nieuw adminscherm in deze release | Privé-admin gepubliceerd; ingelogd sandbox4/3incidenten en productie0 bewezen; zie releasebewijs | Volledige statusreconciliatie, herstel, refund-/voucherconsistentie nog open; geen automatische herboeking |
| SD-13 | Webflow-klantreis en stap-6-bevestiging | Main/Pages PR19; Xano branch14 reader1985 +591; Webflow gepubliceerd | Root Coming Soon behouden; bevestiging order100 bewezen;591 eigen-domeinreturn opgeslagen en gepubliceerd | Nieuwe sessies via591 naar eigen bevestigingspagina; bestaande sessies behouden oude return. Echte Nuitée-boekingen blijven uit |
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


## H. Webflow gereedzetten — REL-20261011-WEBREADY

- Bron: main `07abcfc608d051710fb9369f0777dc1a37c5b615` + Webflow actuele inhoud. Bestemming: site68cb0d808ea4f2467bb313af, home6a5f73d431f70573692af960, detail6a5f7754024f18d807219648, bevestiging6acbead36631ab0d5cf3b9fd.
- Opgeslagen: nieuwe home/detail embeds, home/detail heads, detail footer; bevestiging draft=false + SEO. Geen oude pagina's aangepast, geen root-homewissel, geen Xano-/betaalwijzigingen. Bronexports in public-preview/webflow; terugval in checkpoints/pre-webflow-ready-20261011.json.
- Publicatie NIET geslaagd: single-page API HTTP400; volledige sitepublicatie naar beide custom domains plus Webflow-subdomein afgewezen door automatische veiligheidscontrole (mogelijke andere pending wijzigingen, bredere publicatie dan voorbereidingsopdracht). Geen alternatieve publicatieroute gebruikt.
- Nieuwe inhoud is dus opgeslagen/ongepubliceerd, geen claim van browsergeteste uitrol. Bestaande stap6 Pages-browserbewijs blijft geldig voor Pages, niet voor Webflow.
- Vervolg: concrete goedkeuring van volledige sitepublicatie, daarna gepubliceerde home/detail/bevestiging verifiëren en pas daarna sandbox591 success/cancel naar Webflow omzetten. Nieuwe betaaltest niet automatisch nodig voor puur vormgeving. Productieboekingen en volledige productieklantreis blijven afzonderlijk.

### WEBREADY — definitieve publicatie-uitkomst (vervangt blokkade hierboven)

- Jurgen heeft volledige sitepublicatie expliciet toegestaan na bevestiging dat Coming Soon landingspagina blijft (11 oktober22:23 Amsterdam).
- Publicatie geslaagd, task `02f587d2-fcae-4d7a-9e72-90b2bd310a3e`, beide SeasonDeals-domeinen + Webflow-subdomein. Gepubliceerde root blijft Coming Soon. Nieuwe home/detailinhoud in browser waargenomen; Webflow-bevestiging met bestaande order100 aangesloten gecontroleerd incl logo/QR/mailstatus. Geen nieuwe transactie.
- Codebron voorbereiding main `5aed7824a7ef4f66e55f91101c794f5fe3786c43`, pagina-ID's en terugvalexport in sectieH. Geen rootwissel, geen oude pagina's verwijderd, geen productiepoortwijziging.
- Vervolg restpunt routering: sandbox591 gebruikt nog de bewezen GitHub Pages-succes/cancel-URLs. Webflow-URL is nu bereikbaar/getest; eventuele omstelling is nog niet uitgevoerd. Productieklantreis blijft afzonderlijk van deze afgeronde Webflow-plaatsing.


## REL-20261011-INCIDENT7 — incidentoverzicht en eigen bevestigingsdomein

Geautoriseerd door Jurgen: ‘Oké pak door’. SD-12 diagnostiek is gebouwd en selectief op v1 geplaatst; frontend is gepubliceerd en aangesloten browsercontrole is geslaagd; bewijs hieronder. Volledige herstel-/refundafhandeling is hiermee niet afgerond.

- Xano workspace1 bron branch15 `nuitee-step7-incidents-2026-10-11`, Admin157 GET `supplier-checkout-incidents` #2106 (gepubliceerd) → v1 Admin3 #2227 (Private; in bestemmingslijst bevestigd). Alleen dit nieuwe endpoint geselecteerd; tien afwijkende demo-/partnerendpoints en middleware niet meegenomen. Back-up bestemming stond aan; exacte back-upnaam TE VERIFIËREN.
- Reader gebruikt bestaande admin_users-authenticatie en admin/guard; alleen actieve adminrollen. Uitsluitend bestaande checkout-intents/orders/supplier_bookings/vouchers lezen. Geen nieuwe boekingen, betalingen, refunds, vouchers of mails. Gedeelde databasebron live niet gewijzigd; geen dataherstel nodig.
- Per aanvraag maximaal 50 intentcontroles plus 1 voor cursorvervolg; omgeving sandbox/productie expliciet. Bekende fouten direct tonen, onvoltooide verwerking na 5 min. Succesvol bevestigde huidige boeking onderdrukt historische boekingsfout. Geen persoonsgegevens, betaal- of sessietokens in response/documentatie.
- Bronbestanden: `backend/xano/supplier-checkout-incidents.xs`, `backend/xano/checkout-incident-policy.js`; scherm `admin/checkout-incidents.html` en `admin/js/checkout-incidents.js`, link vanuit `admin/integrations.html`.
- Lokale verificatie: 12 classificatiescenario’s geslaagd; daadwerkelijke Xano-lambda 50+1/cursor en leeg resultaat geslaagd; JavaScript syntax geslaagd. Bronendpoint sandbox 4 intents gescand, orders97/98/99 zichtbaar en gezonde100 uitgesloten; na correctie historische fout productie 0 resultaten succesvol. Definitieve v1/browsercontrole is hieronder vastgelegd.
- SD-13: branch14 functie591 `supplier/checkout/create_sandbox_session` opgeslagen én gepubliceerd met retour- en annuleer-URL `https://www.seasondeals.nl/boeking-bevestiging` (fragment session_id/cancelled). Alleen twee URL’s aangepast; nieuwe sessies via591 gebruiken eigen domein. Bestaande Stripe-sessies en branch11 functie455 blijven ongewijzigd. Source `backend/xano/create-sandbox-session-step6.xs`. Geen nieuwe transactie nodig om deze configuratiewijziging te controleren.
- Coming Soon blijft root; normale hotelpartnerroute ongewijzigd; echte Nuitée-productieboekingen blijven gesloten. Stap4/5 blijven bewezen afgerond. Bestaande klantbevestiging houdt processing/needs_attention/unavailable van confirmed gescheiden; niet opnieuw gebouwd.
- Terugval: frontend terug naar commit00fb8d6e88d41af7962b994f3cc336e827742f20; nieuwe reader is zelfstandig en kan los worden teruggenomen;591 twee URLs terugzetten naar versie vóór deze release. Geen volledige branchrollback nodig.
- Nog open SD-12: gecontroleerde leveranciersstatus-reconciliatie bij onzeker resultaat, herstel/retry zonder dubbele boeking, annuleringskosten/refund/voucherconsistentie en productiescenario’s. Deze release biedt signalering en controle-instructies, geen automatische herstelactie.


### REL-20261011-INCIDENT7 — aangesloten controle 11 oktober 2026

Implementatiecommit `029f4e3188c8424101662f526b42a044b6f92593`; Pages-deployment `38173541064` **success**. Aanvullende schermcorrectie `4de4cef22cd4dabbc87752996a1eac7f3a3a7001` verbergt uitgeputte paginering en verzorgt filters. Privé-admin gebruikt werkelijk v1 Admin3 endpoint2227.

Browser ingelogd: via Integratiebeheer → ‘Nuitée: boekingen met aandacht’ geopend. Sandbox:4 checkouts gecontroleerd/3 aandachtspunten, orders97/98/99;100 terecht afwezig.97 meldt alleen ontbrekende voucher/mail, geen historische boekingsfout meer.98/99 tonen betaald zonder leveranciersboeking, inclusief instructie om eerst betaling en leveranciersstatus vast te stellen. Productiefilter:0 checkouts/0 aandachtspunten. Zoekterm98 toont uitsluitend98; uitklappen controleadvies werkt. Nieuwe browser-tab zonder adminsessie wordt naar admin/login.html gestuurd. Rechtstreekse anonieme API-navigatie werd door browser ERR_BLOCKED_BY_CLIENT tegengehouden en levert dus geen API-auth-testbewijs; Xano endpoint staat Private met bestaande admin_users+guard.

Dit rondt SD-12 **incidentzichtbaarheid** af; automatische reconciliatie, herstel en refundafhandeling blijven afzonderlijk open. Er zijn geen nieuwe transacties of datawijzigingen uitgevoerd. De geconstateerde drie problemen zijn bestaande sandboxtestrecords, geen nieuwe productie-incidenten. Stap4/5 blijven afgerond. Coming Soon blijft landingspagina en productieboekingen blijven gesloten.

Schermcorrectie deployment `38173646652`: success. Browsercontrole: geen vervolgknop bij uitgeputte scan; definitieve opmaak en sandboxresultaten zichtbaar. SD-12 incidentoverzicht **gepubliceerd en ingelogd geverifieerd**.


## REL-20261011-RECOVERY7 — herstelroute, tussenstand 11 oktober 2026

**SD-12: gebouwd en met bestaande sandboxorders getest op Xano-ontwikkelbranch17. Nog NIET naar v1 overgezet; nieuwe adminbediening nog NIET gepubliceerd of aangesloten geverifieerd. Stap 7 blijft daarom open.** Stap4/5 blijven bewezen afgerond.

### Exacte bron en selectieve bestemming
- Xano workspace1 branch17 `nuitee-step7-recovery-2026-10-11`, kopie van gepubliceerde v1. Functies710 `supplier/checkout/recovery_snapshot`,711 `supplier/checkout/recovery_apply` en Admin175 POST2349 `supplier-checkout-recovery` zijn gepubliceerd en gebruikt in onderstaande tests. Alleen Nuitée sandbox en Stripe test; actieve superadmin/platform_admin via bestaande authenticatie/guard.
- Admin175 POST2251 `orders/{order_id}/refund`: uitsluitend Nuitée-uitsluitingsguard toegevoegd. Publicatie aangeklikt vóór verbindingsverlies; definitieve publicatiestatus **TE VERIFIËREN**. Beoogd doel v1 Admin3 POST24. Overige partnerrefundbody byte-voor-byte gelijk aan oorspronkelijke export, lokaal gecontroleerd.
- Admin175 GET2277 `supplier-checkout-incidents`: bijgewerkte classificatie voor lopend herstel/refund en opgeloste annulering; opgeslagen draft, Review & Publish geopend maar laatste publicatie **NIET bevestigd**. Beoogd doel v1 GET2227.
- Nieuwe doel-ID's voor710/711/2349 **TE VERIFIËREN na selectieve merge**. Selecteer uitsluitend deze vijf onderdelen; tien afwijkende demo-/partnerendpoints en middleware uitsluiten. Bestemmingsback-up bij merge vastleggen; bestaande backupbranch16 `v1-W8aAWe` is geen databack-up.
- GitHub-codecheckpoint: beoogde branch `feat/nuitee-step7-recovery-2026-10-11` is NIET aangemaakt: de tool meldde ‘user rejected MCP tool call’. Code is lokaal aanwezig; losse Git-tree `e7ad0a2945faf07ab6115eeaf624f3b4cd250e16` aangemaakt maar GEEN branch/commitcheckpoint bevestigd; bron `backend/xano/recovery/`, aangepaste incidentpolicy/reader, nieuwe `admin/checkout-recovery.html` en JS, links vanuit incidenten/leveranciers, relevante tests. Nieuwe UI nog niet op main/Pages, om geen bediening naar een ontbrekend v1-endpoint te publiceren.

### Uitgevoerde tests en echte sandboxmutaties
- Scopecontrole vóór externe aanvragen: gewone testorder81 geweigerd omdat niet exact één bijbehorende Nuitée-sandboxcheckout bestaat. Een testorder is niet automatisch een Nuitée-order; andere routes niet als leveranciersincident behandelen.
- Order98/intent3: actuele Stripe-testbetaling en Nuitée-absence gecontroleerd in combinatie met eerdere definitieve4002-fout. Statusherstel uitgevoerd; vervolgens echte Stripe-testrefund EUR1,00, identieke herhaalde aanvraag geweigerd op gewijzigde status, daarna restant EUR240,43 terugbetaald. Totaal EUR241,43 terugbetaald, resterend0, geen lopende refund; order/payment/intent op refunded. Geen nieuwe boeking of mail.
- Order100/intent5: bestaande bevestigde Nuitée-sandboxboeking geannuleerd. Actuele leveranciersstatus CANCELLED_WITH_CHARGES, annuleringskosten EUR205,20, leveranciersrefund0. Klantbetaling EUR241,43 NIET terugbetaald. Lokale order/intent geannuleerd; voucher44 status én redemption_status cancelled. Eigen-domeinbevestigingspagina daadwerkelijk herladen: ‘Deze reservering is geannuleerd’, geen QR/voucher. Het eerdere stap4-bevestigingsbewijs blijft historisch geldig; huidige annulering is een opzettelijke stap7-test.
- Algemene refundroute met order100/bedrag1: Nuitée-guard weigerde vóór Stripe-aanvraag. Bestaande partnerrefundbody verder ongewijzigd; geen partnerrefund uitgevoerd.
- Order99/intent4 met onzekere4005/referentiereservering blijft manual_attention. Geen reset of automatische herboeking. Order97 ontbrekende voucher/mail blijft een bestaand aandachtspunt; deze herstelroute maakt geen ontbrekende vouchers of mails aan.
- Lokaal opnieuw geslaagd:17 evidence-scenario's, daadwerkelijke reservatielambda's voor gelijktijdige/verouderde aanvragen, onveranderlijke retry, retrytermijn, refundgrenzen en ongewijzigde partnerbody;12 incidentclassificaties plus daadwerkelijke Xano-paginering/gezonde boeking. Pending-refund en onzekere retry zijn fixturetests, geen nieuwe externe transacties. De dubbele refundcontrole hierboven was een sequentiële echte herhaling, geen claim van gelijktijdige externe refundtest.

### Werking en grenzen
- Eerst actuele Stripe/Nuitée-status en exacte order/session/betalingsbinding verifiëren; onbekende status blokkeert financiële actie. Geen nieuwe boeking vanuit deze route.
- Refund/annulering vereist expliciete adminactie en toelichting; bedrag binnen resterende betaling. Onder recordlock een onveranderlijke operatie bewaren vóór externe aanvraag. Stripe-retry met dezelfde sleutel/hetzelfde bedrag, maximaal23uur, met wachttijd en statuscontrole; geen blinde nieuwe poging.
- Annuleringskosten/leveranciersrefund apart van klantrefund tonen. NRFN leidt niet automatisch tot klantrefund. Annulering/full refund maakt bestaande voucher ongeldig. Geen mailverzending of productiecredentials activeren.
- Branches delen databasebron live: bovenstaande sandboxrecordwijzigingen zijn werkelijk gedeeld. Logicarollback maakt externe refunds/annulering NIET ongedaan. Geen boeking opnieuw maken en geen oude betaal/voucherstatus terugschrijven; herstel uitsluitend vanuit actuele providerstatus en bewaar auditgegevens.

### Blokkade en volgende actie
- Na verbindingsverlies is bestandstoegang hersteld, maar browserbediening ontbreekt in deze sessie. Geen beschikbare Xano-connector gevonden. Daardoor publicatie van2277/2251, selectieve merge naar v1 en aangesloten browsercontrole nog open. Geen volledig afgeronde stap7 claimen.
- Hervatten: actuele branch17-versies/publicatiestatus vergelijken met export, uitsluitend bovengenoemde vijf componenten naar v1 mergen met back-up; doel-ID's vastleggen; daarna frontendcheckpoint publiceren en ingelogd order98/refunded en100/cancelled controleren, andere route81 geweigerd. Geen nieuwe externe transacties nodig voor deze eindcontrole.
- Beoordeel vóór volledig afsluiten SD-12 ook nog de scope van ontbrekende voucher/mail en productiescenario's; fixturetests niet presenteren als productieproef. Coming Soon blijft root; echte productieboekingen/betalingen/refunds blijven gesloten.


### RECOVERY7 — hervatting 12 oktober 2026

De eerdere geweigerde branchaanmaak is op nieuw verzoek van Jurgen alsnog gelukt. Codecheckpoint op `feat/nuitee-step7-recovery-2026-10-11`:18 gewijzigde/nieuwe bronbestanden vanuit de bewaarde Git-tree `e7ad0a2945faf07ab6115eeaf624f3b4cd250e16`, gebaseerd op main `fefdd465ffe33bc45e8b60da310ac8ed3e55cd61`. Geen nieuwe implementatie of nieuwe transacties; eerder testbewijs blijft van toepassing.

Browserbediening is op12okt niet beschikbaar in deze sessie; gerichte connectorzoekactie levert geen Xano-aansluiting. Daarom geen nieuwe Xano-publicatie/merge of aangesloten UI-verificatie uitgevoerd. Nieuwe code uitsluitend werkbranch, niet main/Pages; bestaande admin blijft actief. Open blijft exact de selectieve vijfdelige Xano-merge en daaropvolgende adminpublicatie/eindcontrole uit de voorgaande sectie. Stap7 NIET afgerond. Geen nieuwe toestemming voor boekingen nodig; wel werkende toegang tot Xano en de ingelogde admin voor uitvoering. Coming Soon en gesloten productiepoort ongewijzigd.

Bevestigd codecheckpoint: commit `b48c3310d8cd0f30c0272a7ad7b26327e69b0de2` op bovengenoemde werkbranch. Deze main-update wijzigt uitsluitend documentatie.


### REL-20261012-RECOVERY7-DEPLOY — daadwerkelijke Xano-plaatsing

- Browserbediening en bestaande Xano-login op 12 oktober gecontroleerd; eerdere verbindingsblokkade is opgelost.
- Bron: GitHub `feat/nuitee-step7-recovery-2026-10-11`, commit `b48c3310d8cd0f30c0272a7ad7b26327e69b0de2`; Xano workspace1 branch17. Refundguard2251 was gepubliceerd. De enige draft was incidentreader2277; inhoud gecontroleerd en om08:57 Amsterdam gepubliceerd. Daarna nul drafts.
- Om09:30 Amsterdam uitsluitend vijf gepubliceerde onderdelen naar v1 overgezet, met bestemmingsback-up `v1-fmiKpY` (12okt09:30). Bron710 recovery_snapshot → v1 functie748; bron711 recovery_apply → v1 functie749; Admin175 POST2349 supplier-checkout-recovery → v1 Admin3 POST2471; POST2251 orders/{order_id}/refund → v1 POST24; GET2277 supplier-checkout-incidents → v1 GET2227. Nieuwe functies en beide supplier-checkout-routes op bestemming zichtbaar; routes Private.
- Uitgesloten: demo-endpoints2344–2348, partnerendpoints2312/2314/2315/2316/2317, alle branchmiddleware. Merge toonde exact5 geselecteerd,3 toevoegingen en2 updates; geen ontbrekende afhankelijkheden.
- Bronvergelijking: guard2251 gelijk aan export na witruimte-normalisatie; functies710/711 gelijk na Xano-formattering (witruimte, optionele komma’s en booleanvergelijkingen). Endpoint2349 en reader2277 inhoudelijk gelezen, exact Nuitée/sandbox- en betalingsbinding behouden. Geen nieuwe codefunctionaliteit aan backend toegevoegd.
- Lokale controles op de gepinde GitHub-code opnieuw geslaagd:17 evidence-scenario’s; echte reservation-lambda’s voor concurrency/stale requests, onveranderlijke retry, retrytermijn en refundgrenzen; oorspronkelijke partnerrefundbody ongewijzigd; admin-JavaScript syntax geldig. Dit zijn lokale controles, geen nieuwe externe refund/annulering.
- Frontend in deze tussenstand nog werkbranch; publicatie en aangesloten controle volgen. Nieuw geopende adminbrowser vraagt SeasonDeals-adminlogin. Xano-login werkt wel.
- Order97 voucher/mail nog beoordelen;99 blijft manual_attention. Geen ordermutaties, nieuwe boekingen, betalingen, refunds of mails in deze uitrol. Back-up betreft uitsluitend logica; historische98-refund en100-annulering niet terugdraaien. Coming Soon en gesloten productiepoort behouden.
- Terugval: gericht vijf onderdelen vergelijken met `v1-fmiKpY`; geen volledige database-/branchrollback. Frontend terugval main vóór deze release `8786e904b9828c93bc20d7ac5f7d1483c7a0ab2b`. Stap7 blijft open tot adminpublicatie/aangesloten eindcontrole en beoordeling97 daadwerkelijk zijn voltooid; stap4/5 blijven afgerond.
