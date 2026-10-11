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
| SD-12 | Fout-, annulerings- en herstelafhandeling | Incidentreader branch15 Admin157 #2106 gepubliceerd → v1 Admin3 #2227; nieuw adminscherm in deze release | Read-only signalering en lokale tests gereed; aangesloten browsercontrole volgt hieronder | Volledige statusreconciliatie, herstel, refund-/voucherconsistentie nog open; geen automatische herboeking |
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

Geautoriseerd door Jurgen: ‘Oké pak door’. SD-12 diagnostiek is gebouwd en selectief op v1 geplaatst; frontendpublicatie en aangesloten browsercontrole volgen in deze release. Volledige herstel-/refundafhandeling is hiermee niet afgerond.

- Xano workspace1 bron branch15 `nuitee-step7-incidents-2026-10-11`, Admin157 GET `supplier-checkout-incidents` #2106 (gepubliceerd) → v1 Admin3 #2227 (Private; in bestemmingslijst bevestigd). Alleen dit nieuwe endpoint geselecteerd; tien afwijkende demo-/partnerendpoints en middleware niet meegenomen. Back-up bestemming stond aan; exacte back-upnaam TE VERIFIËREN.
- Reader gebruikt bestaande admin_users-authenticatie en admin/guard; alleen actieve adminrollen. Uitsluitend bestaande checkout-intents/orders/supplier_bookings/vouchers lezen. Geen nieuwe boekingen, betalingen, refunds, vouchers of mails. Gedeelde databasebron live niet gewijzigd; geen dataherstel nodig.
- Per aanvraag maximaal 50 intentcontroles plus 1 voor cursorvervolg; omgeving sandbox/productie expliciet. Bekende fouten direct tonen, onvoltooide verwerking na 5 min. Succesvol bevestigde huidige boeking onderdrukt historische boekingsfout. Geen persoonsgegevens, betaal- of sessietokens in response/documentatie.
- Bronbestanden: `backend/xano/supplier-checkout-incidents.xs`, `backend/xano/checkout-incident-policy.js`; scherm `admin/checkout-incidents.html` en `admin/js/checkout-incidents.js`, link vanuit `admin/integrations.html`.
- Lokale verificatie: 12 classificatiescenario’s geslaagd; daadwerkelijke Xano-lambda 50+1/cursor en leeg resultaat geslaagd; JavaScript syntax geslaagd. Bronendpoint sandbox 4 intents gescand, orders97/98/99 zichtbaar en gezonde100 uitgesloten; na correctie historische fout productie 0 resultaten succesvol. Definitieve v1/browsercontrole volgt hieronder.
- SD-13: branch14 functie591 `supplier/checkout/create_sandbox_session` opgeslagen én gepubliceerd met retour- en annuleer-URL `https://www.seasondeals.nl/boeking-bevestiging` (fragment session_id/cancelled). Alleen twee URL’s aangepast; nieuwe sessies via591 gebruiken eigen domein. Bestaande Stripe-sessies en branch11 functie455 blijven ongewijzigd. Source `backend/xano/create-sandbox-session-step6.xs`. Geen nieuwe transactie nodig om deze configuratiewijziging te controleren.
- Coming Soon blijft root; normale hotelpartnerroute ongewijzigd; echte Nuitée-productieboekingen blijven gesloten. Stap4/5 blijven bewezen afgerond. Bestaande klantbevestiging houdt processing/needs_attention/unavailable van confirmed gescheiden; niet opnieuw gebouwd.
- Terugval: frontend terug naar commit00fb8d6e88d41af7962b994f3cc336e827742f20; nieuwe reader is zelfstandig en kan los worden teruggenomen;591 twee URLs terugzetten naar versie vóór deze release. Geen volledige branchrollback nodig.
- Nog open SD-12: gecontroleerde leveranciersstatus-reconciliatie bij onzeker resultaat, herstel/retry zonder dubbele boeking, annuleringskosten/refund/voucherconsistentie en productiescenario’s. Deze release biedt signalering en controle-instructies, geen automatische herstelactie.
