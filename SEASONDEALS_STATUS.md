# SeasonDeals — actuele projectstatus

> **Afspraak gecorrigeerd 15 oktober:** concept → ter beoordeling → goedgekeurd → automatisch zichtbaar op de website. Geen afzonderlijke publicatiestap per deal. Eerdere teksten over een extra websitevrijgave zijn vervangen door deze afspraak; algemene livegang/verkoop blijft afzonderlijk.

> **OPEN LIVEGANGVEREISTE — SD-15:** automatisch breed Nuitée-hotelaanbod voor heel Nederland; eerst één Amsterdamse voorbeelddeal samen. Import, varianten, automatische plaatsing en verversing nog afmaken en bewijzen. Zie DOC-20261015-NL-AANBOD-AUTOMATISERING.

> **Actueel 15 oktober — SD-09/13:** bestaande dealpagina technisch aangesloten op de gesloten Nuitée-checkout; gepubliceerd en laden/formuliervalidatie live gecontroleerd. Volledige proef met echte Nuitée-deal nog open. Zie REL-20261015-DIRECT-DEAL-ROUTE.

> **Actueel 15 oktober — SD-09/13:** goedgekeurde Stripe-naamvelden en opslagkoppeling geplaatst op Xano v1; gesloten poorten getest. De aansluiting vanaf de bestaande dealpagina en echte ketenproef blijven open. Zie REL-20261015-STRIPE-GUEST-BINDING.

> **Actueel 15 oktober — SD-13:** extra /hotel-boeken-pagina offline gezet op verzoek eigenaar. Klantreis blijft dealcard → bestaande dealpagina → Stripe → bevestiging, zonder account. Zie REL-20261015-REMOVE-EXTRA-STEP. Productieverkoop blijft gesloten.


> **Actueel15okt — SD-09/13:** synthetische HTTP-handtekeningcontrole op2594 geslaagd (vier gevallen). Productiebevestigingsreader2595 geplaatst en gesloten getest; gecombineerde Webflow-bevestiging opgeslagen, publicatiecontrole volgt. Zie REL-20261015-TRANSPORT-CONFIRMATION.

> **Actueel15okt — SD-09/10:** aparte Stripe-webhooksleutel in Xano opgeslagen, na herladen bevestigd en aan endpoint2594 gebonden. Raw-inputcodering gericht aangepast; gesloten poort getest. Synthetisch raw-body/signaturetransport inmiddels bewezen (zie REL-20261015-TRANSPORT-CONFIRMATION); echte Stripelevering en volledige productieaansluiting nog open. Zie REL-20261015-WEBHOOK-BINDING.

> **Actueel13okt — SD-07/08/09:** aparte productieketen791–798 op v1 geplaatst en op callback2594 aangesloten; entry gates getest en gesloten. Stripe-registratie en secretbinding zijn inmiddels geplaatst (zie REL-20261015-WEBHOOK-BINDING); transport en productievrijgave blijven open. Zie REL-20261013-PRODUCTION-CHAIN.

> **Actueel13okt — SD-09/10:** livecredentials via alleen-lezen API-verzoeken gecontroleerd; signaturehelper getest; nieuwe callback2594 geplaatst met bewezen gesloten toegang. Volledige productieboekingsketen nog open. Zie REL-20261013-PRODUCTION-CONNECTIONS onderaan.

> **Actueel13okt — SD-10:** ACC door eigenaar bevestigd; aparte Nuitée-productiekey en gesloten configuratie geplaatst. Controlefunctie788 op v1 getest; geen productieboekingen of publieke vrijgave. Zie REL-20261013-ACC-PREP onderaan.

> **Actueel12okt — SD-12:** stap7-sandboxherstelroute afgerond, op v1/main/Pages geplaatst en ingelogd gecontroleerd. Historische order97 blijft op aanwijzing van Jurgen een ongewijzigd testrecord en is geen afsluitblokkade; order99 blijft manual_attention. Geen publieke productievrijgave. Zie DOC-20261012-ORDER97-LEGACY onderaan.

> **Vaste bron van waarheid voor de technische voortgang van SeasonDeals**
>
> Laatst inhoudelijk geverifieerd: **15 oktober 2026**
>
> Repository: `jurgenhassankhan/seasondeals-partner-portal`  
> Productiearchitectuur: **Webflow (publieke frontend) + Xano (backend en bron van waarheid) + Stripe (betalingen) + Resend (e-mail)**

## Vast onderhoud van status en livegang

- [Livegang- en overzetlijst](SEASONDEALS_LIVEGANG.md): wat staat waar, wat moet nog over en welke testcode blijft achter.
- [Vast werkprotocol](SEASONDEALS_WERKPROTOCOL.md): bij iedere relevante wijziging deze status én de liveganglijst bijwerken met bron, bestemming en bewijs.
- [Agentinstructies](AGENTS.md): deze documenten bij iedere volgende werksessie lezen en naleven.
- Op 11 oktober 2026 op verzoek van Jurgen vastgelegd. Documentatiewijziging; geen nieuwe software-, configuratie- of productievrijgave. Nog onbekende bronversies/doel-ID's staan in de lijst expliciet als TE VERIFIËREN.

## Stap 4 — sandboxresultaat 11 oktober 2026

**Status: STAP 4 AFGEROND EN GETEST IN DE SANDBOX. Stripe-testbetaling, automatische Nuitée-boeking, werkelijke kosten, één voucher, QR-code en afgeleverde bevestigingsmail zijn bewezen. Gelijktijdige dubbele meldingen veroorzaakten geen extra boeking, betaling, voucher of e-mail. De nieuwe mailopmaak is door de gebruiker ontvangen en visueel goedgekeurd. Geen productierelease; niet naar v1 gemerged.**

### Afbakening en broncode
- Werkbranch GitHub `feat/nuitee-step4-2026-10-11`, terugvalbranch `backup/pre-step4-2026-10-11`; Xano workspace1, branch11 `nuitee-step4-2026-10-11`.
- Xano-branches delen databasegegevens (data source `live`). Externe transacties uitsluitend Stripe test en Nuitée sandbox, fictieve klant4, orders98/99/100, intents3/4/5. Geen echte betaling of productieboeking.
- Normale hotelpartnerroute, bestaande webhooks, v1, Webflow en portalinterface niet aangepast.
- Broncode op featurebranch: `xano/nuitee-step4-2026-10-11/source-checkpoint.json` (452–456), `source-followup-checkpoint.json` (457–462,1622 en diagnostiek454), plus leesbare `finalize_sandbox.xs` en `webhooks_nuitee_sandbox.xs`.
- Actuele461 staat in `finalize_sandbox.xs`: verzendt uitsluitend wanneer de opgeslagen ontvanger expliciet is goedgekeurd (`authorized=true`), met idempotency key en opgeslagen sent-status.463 staat in `send_approved_order100_mail.xs`. Het oudere `finalize_with_mail_PENDING_APPROVAL.xs` en source-followup-checkpoint zijn historische tussenstanden.

### Fouten in mijn aansluiting en herstel
- De basisconnector was al getest. Mijn nieuwe aansluiting gaf aanvankelijk geen gast-e-mails door (order98, Nuitée4002) en daarna twee hoofdgasten voor één kamer (order99,4002 invalid occupancy).
- Verplichte e-mailvalidatie in455 en één hoofdcontact per kamer in456 gecorrigeerd. Overige reizigers blijven intern opgeslagen.
- Op verzoek eerst alleen-lezen reconciliatie uitgevoerd via nieuwe457: lookup op clientReference checkout02 gaf HTTP200/data[]. Op eerdere fout4002 en ontbreken lokale supplierboeking begrensde herstelrun458 uitgevoerd. Hertest gaf4005: Nuitée had de eerdere referentie al gereserveerd. Intent4 blijft manual_attention; niet opnieuw resetten/herboeken.
- Tweede controle via bookinglijst sandbox=1/dagfilter en clientReference gaf HTTP200, geen eerdere boeking. Daarna zelfstandige nieuwe testorder met nieuwe stabiele sleutel checkout03 gebruikt. Oude orders98/99 blijven voor audit behouden.
- Een verse preparecontrole blokkeerde aanvankelijk CONDITIONS_CHANGED vóór nieuwe order/betaling. Controles niet versoepeld; latere verse quote voldeed.454 heeft alleen extra diagnostiek voor afwijkende voorwaarden in draft.
- Eerdere overige fouten (ongeldige provider_sync_status processing en Stripe false als0) zijn in de vorige sessie hersteld; geen nieuwe basisconnectorresultaten claimen.

### Aantoonbaar nieuwe end-to-end resultaten
-459 creëerde order100/intent5: deal17, nhow Amsterdam RAI,10–12november2026,2volwassenen/1kamer, EUR241,43. Referentie `SD-SBX-4-step4-20261011-checkout03`.
- Aparte sandboxcallback1622 `POST webhooks/nuitee-sandbox` gepubliceerd op branch11. Ontvangt alleen event-ID als input, haalt event serverzijdig op bij Stripe met testkey, controleert testmode/type/paid/eigen supplier-metadata/order/session, verifieert vervolgens Session/PaymentIntent/charge/exact bedrag via452. Geen vertrouwde client-betaalvelden. Geen productieacties.
-460 registreerde Stripe-testwebhook `we_1UPKy1Pz36j75L08shwZ26VT` op de exacte branch11-URL. Ongeldig event werd eerst met403 geweigerd. Signing secret niet in code/export vastgelegd. Dit sandboxendpoint gebruikt autoritatieve eventlookup, geen eigen signatureverificatie; productiebeveiliging is geen onderdeel van deze testrelease.
- iDEAL-testsimulator geautoriseerd, geen echte afschrijving. Stripe-event `evt_1UPL4EPz36j75L08XapWxLVN` kwam automatisch binnen.
- Automatische456 bevestigde boeking `l0kp_BVEf` (Nuitée lijst-ID5317293), CONFIRMED, sandbox1, één booking_attempt. Onafhankelijke clientReference-lookup en boekinglijst bevestigden één overeenkomst. Geen handmatige fulfillmentrun voor order100.
-461 `supplier/checkout/finalize_sandbox`: leest actuele Stripe balance_transaction en leveranciersboeking, verifieert overeenkomst, werkt financiële velden bij, maakt onder intent-recordlock maximaal één payment en één voucher, bewaart ontsnapte mail-HTML als concept. Geen mailverzending. Voucher.hotel_id=null voorkomt toewijzing aan placeholderhotel1; hotelinformatie komt uit bevestigde leveranciersboeking.
- Werkelijke sandboxbedragen: verkoop241,43; leverancier205,20; processing2,30 (reserve was1,30); Stripe0,29; marge33,64EUR. Transactie `txn_3UPL3PPz36j75L0810wE29Aj`. Geen geschatte kosten als definitief gepresenteerd.
- Eerste461-run succesvol in1,79s: voucher44, mail_status=draft_not_sent. Daarna461 aangesloten op1622 en veilige versie gepubliceerd.
-462 stuurde twee gelijktijdige HTTP-aanvragen naar de gepubliceerde nieuwe callback met dezelfde Stripe-melding. Starttijden1791719183981/3983, beide200, booked/idempotent_replay=true, finalization=reconciled. Testpassed=true in3,57s; na afloop booking_attempts1, supplier_bookings1, payments1, vouchers1, webhook deliveries3. Hiermee is gecontroleerd dat gelijktijdige dubbele meldingen geen duplicaten veroorzaken.
- Voorgaande negatieve controles blijven gelden: onbetaalde sessie geweigerd; ontbrekende gastmail vóór orderbetaling geweigerd; gewijzigde inhoud op dezelfde requestkey geweigerd; gelijke aanvraag hergebruikt order/session.

### Afgeronde mailtest na expliciete toestemming
- Gebruiker gaf op11okt2026 om13:52Amsterdam expliciet toestemming om de fictieve boekingsbevestiging naar zijn opgegeven persoonlijke Gmail-adres te sturen. Het adres is alleen als runtime-input/private ordercontext gebruikt, niet hardgecodeerd in broncode of dit statusbestand.
-463 begrenst de test tot order100/intent5/voucher44, bewaart de goedgekeurde ontvanger onder recordlock en maakt deze na toestemming onveranderlijk.461 is op branch11 gepubliceerd met verzenden uitsluitend bij authorized=true en status!=sent. Bestaande automatische callback1622 gebruikt deze functie; andere concepten zonder toestemming worden niet verstuurd.
- Eerste poging stopte vóór verzending op Xano-datumaritmetiek (“Not numeric”). Tijdcontrole gecorrigeerd naar Date.now() in lambda; geen mail in die mislukte poging.
- Geautoriseerde mail daarna succesvol door Resend geaccepteerd in2,59s, ID `01a12ad2-0698-7357-a0db-c7f04bfd3dd2`, sent_at1791719769892. Onderwerp **SANDBOX — SeasonDeals boekingsbevestiging**; fictieve boeking l0kp_BVEf, nhow Amsterdam Rai,10–12nov2026,2gasten,voucher44,EUR241,43,NRFN en expliciet “geen geldig verblijf”.
- GET /emails/{id} gaf HTTP200 en **last_event=delivered**. Dit bevestigt aflevering volgens Resend, geen onafhankelijke verificatie van de Gmail-inbox.
- Herhaling van463 behield hetzelfde resend_id. Vervolgens462 opnieuw uitgevoerd met twee gelijktijdige gepubliceerde webhookaanvragen: passed=true in3,71s; dezelfde mail-ID én sent_at behouden, één supplierbooking/payment/voucher, geen extra booking_attempt. Geen tweede mailaanvraag bij sent-status.
- Stabiele sleutel `nuitee-sandbox-voucher-5-owner-20261011`. Bij onzekere verzenduitkomst uitsluitend dezelfde sleutel binnen23uur; buiten die termijn eerst reconciliëren. Geen hotel-/interne notificaties of echt verblijf aangemaakt.
-463 bevat een aanvullende read-only deliverycheck als geteste draft; de eerder gepubliceerde463 verstuurt dezelfde mail via461 maar retourneert alleen finalization.461 en callback1622 zijn gepubliceerd op ontwikkelbranch11.

### Bevestigingsopmaak en goedgekeurd logo — 11 oktober 2026
- Gebruiker bevestigde het bestaande nieuwe websitelogo. Nieuwe functie464 `supplier/checkout/render_confirmation` gebruikt exact dat CDN-bestand, witte achtergrond en expliciete inline afmetingen220×220. De oude mailheader had donkere tekst op donkergroen en vertrouwde op head-CSS voor afbeeldingsafmetingen.
- Leveranciersbevestiging in partnerhuisstijl: boekingsgegevens, betaald bedrag, annuleringslabel, prominente leverancier-/hotelreferentie, voucher en QR. De QR is expliciet voor SeasonDeals-administratie; geen belofte dat het leveranciershotel deze scant. Aankomsttekst bevestigt dat de data al gereserveerd zijn.
-464 getest met fictieve bevestigde boeking: HTML succesvol gegenereerd in60ms.461 aangesloten en getest op bestaande intent5 in1,82s: reconciled, voucher44, mail_status=sent en dezelfde bestaande Resend-ID. Geen nieuwe boeking of mail verstuurd.
-464 en aangepaste461 gepubliceerd uitsluitend op branch11. Versie `supplier-confirmation-v2` wordt als complete HTML verstuurd; bestaande mailinhoud/idempotencysleutels blijven behouden. Normale partnerfunctie423 en partnerroute ongewijzigd.
- Bron en exact door Xano gegenereerd voorbeeld opgeslagen op featurebranch: `render_confirmation.xs`, `finalize_sandbox.xs`, `confirmation-preview.html` (commit19cb2c775808aff538f7a5f6e42a72a2fcb9d9d3).
- Nieuwe opmaak op expliciet verzoek als aparte testmail naar de eerder goedgekeurde eigenaar verstuurd.465 gebruikte bestaande order100/voucher44 en actuele sandboxbooking; geen nieuwe boeking, originele confirmation_mail ongewijzigd. Resend HTTP200, ID `01a12ae5-adb0-706a-83a6-ab8ecd4b55a5`; alleen-lezen vervolgcontrole gaf delivered. Gebruiker bevestigde ontvangst en goede weergave: “Yes heb het binnen ziet er goed uit”.
-465 is na de geslaagde verzending vervangen door alleen-lezen aflevercontrole; bron `test_confirmation_v2.xs`. Geen hotelmail of productiewijziging.

### Conclusie stap 4
- Stap 4 is afgerond en hoeft niet opnieuw als openstaand sandboxwerk te worden getest.
- De complete betaal- en boekingsroute is over de uitgevoerde sandboxtests bewezen: Stripe-betaling → automatische Nuitée-boeking → kostenreconciliatie → voucher/QR → bevestigingsmail.
- Dubbele gelijktijdige meldingen zijn gecontroleerd; de opgeslagen boeking, betaling, voucher en mail bleven ieder uniek.
- De gecorrigeerde bevestigingsmail met het goedgekeurde logo en de QR-code is afgeleverd en door de gebruiker visueel goedgekeurd.
- De ontwikkelbranch is nog niet naar v1/productie gemerged. Productievoorbereiding en livegang vormen een afzonderlijke volgende fase.

## Stap 3 vervolg — 9 oktober 2026

### Afgerond en getest
- GitHub-back-up `backup/pre-step3-final-2026-10-09`; Xano-bron `nuitee-step3-final-2026-10-09` vanuit v1. Alleen reader, refreshfunctie en sandboxtaak samengevoegd, met doelbranchback-up; tien bestaande afwijkende endpoints en middleware uitgesloten.
- Reader #1310 gecompileerd en met bestaande adminauth getest: echte sandboxdeal17, vaste €241,43, leverancier €203,78, marge na reserves €28,85, betalen false; 790ms. Latest pending mag alleen maximaal 20 seconden een nog geldig, exact gelijk goedgekeurd completed resultaat behouden. Nieuwe negatieve resultaten winnen altijd.
- Refreshfunctie #379 geeft snapshots maximaal 90 seconden geldigheid; dit overbrugt minuutplanning, geen realtime voorraadgarantie. Datumselectie blijft een afzonderlijke verse leverancierscontrole.
- Taak #36 handmatig uitgevoerd in 3,32s; oudste controles eerst, maximaal20 kandidaten, sequentiële aanvragen en 45s startbudget. v1-taak #32 opnieuw actief gepubliceerd na selectieve merge. Productiequotum en opschaalcapaciteit moeten afzonderlijk bevestigd worden.
- Regressies voor verval, gewijzigde prijzen/configuratie, negatieve resultaten, pendingtimeout en eerlijke rotatie over41 proefdeals slagen. Bestaande20-rijentabel/search/filtertests en nieuwe bezoekerspreviewtest slagen.

### Gepubliceerd en ingelogd gecontroleerd
- PR17 samengevoegd als `7044524ff8a7747db4accdaab64d377ab8b45de9`; Pages-uitrol #37936400362 geslaagd. v1-taaklijst na publicatie toont taak32 Live: Active, Draft: Active, every1min.
- Beveiligde `admin/availability-website-preview.html` gebruikt bestaande adminauth en private v1-snapshots. In bezoekersstijl verschijnen alleen beschikbare goedgekeurde sandboxdeals, met foto, vaste prijs en link naar bestaande verse datumselectie. Geen onbevestigd kameraantal. Zoekveld en twintig kaarten per pagina.
- Admincatalogus linkt naar bezoekerspreview; tabel en goedkeuringsproces behouden. Client accepteert maximaal90s snapshots conform server. Geen anonieme sandboxpublicatie of betaalroute geopend.

- Nieuwe beveiligde adminaanmelding geslaagd op9okt circa15:30 Amsterdam als Jurgen Hassankhan/Superadmin. Nieuwe catalogusversie via cacheversie geladen: beide sandboxdeals in tabel, nhow beschikbaar voor€241,43, eerdere fictieve deal niet bevestigd. Bezoekerspreview toont uitsluitend nhow met foto en vaste prijs; detail-link daadwerkelijk geopend. Verse datumcheck10–12nov voor twee gasten bevestigt beschikbaarheid om15:32:48; betalen false. Geen deal-, order- of boekingsrecords gewijzigd.
- Visuele controle heeft één te brede kaart en onjuiste algemene bezoekersstatustekst gevonden; compacte gridkolommen en bezoekersspecifieke tekst gecorrigeerd. Vijf relevante regressies opnieuw geslaagd. Pages-uitrol37937813671 geslaagd; compacte versie20261009-final-2 met foto, groene datumknop en eigen bezoekersstatustekst daadwerkelijk gecontroleerd circa15:37 Amsterdam. Zoekveld en lege selectie in browser gecontroleerd. Publieke productiepoort en afzonderlijke productievoorwaarden hieronder blijven open.

### Nog te doen vóór productie
- Publieke productiecatalogus/detailfilter en Webflow achter productiepoort aansluiten na productiegegevens en gehele betaal-/boekingsflow. De beschermde bezoekerspreview is een test, geen publieke Webflow-livegang.
- Providerquota/capaciteit en begrensde snapshotbewaring: huidige tabel is append-only; geen bestaande records verwijderd. Minuutplanning met sequentiële requests is begrensd, geen onbeperkte realtime capaciteit.
- Bestaande publieke provider_sync-poorten blijven dicht; geen nieuwe order, boeking of betaling aangemaakt.

## Nuitée-adminoverzicht — 8 oktober 2026

- PR16 gemerged als 324bcde6b30e0b70a8082b9818ea0c378e7271a2: compacte tabel met foto, vaste verkoopprijs, beschikbaarheidsstatus, laatste controle, zoeken, statusfilter en 20 rijen per pagina.
- Alle goedgekeurde Nuitée-sandboxdeals blijven zichtbaar in het adminoverzicht, ook bij verlopen, onbekende of negatieve beschikbaarheid. Geen records of goedkeuringen gewijzigd.
- Client behoudt een nog geldig resultaat tijdens ophalen; verlopen of negatief antwoord maakt beschikbaarheid niet langer zichtbaar. Backendcontrole op prijs, marge, signature en 60-secondenverval ongewijzigd.
- Syntax en cataloguspolicytest slagen; aanvullende test met 41 regels verifieert 20-rijenpaginering, zoeken, statusfilter en lege zoekresultaten. Test voor behoud van een nog geldige snapshot tijdens ophalen slaagt. Pages-uitrol geslaagd; ingelogde echte tabel rond 16:22 Amsterdam gecontroleerd: nhow €241,43 Beschikbaar met foto en eerdere testdeal €136 Niet bevestigd. Zoeken op nhow en filter Niet bevestigd daadwerkelijk gebruikt. Beide deals blijven in het ongefilterde overzicht.
- Dit corrigeert de onpraktische verdwijnende kaartweergave. Het servergat bij nieuwste pending snapshot blijft een afzonderlijk backendverbeterpunt; geen verouderde voorraad als beschikbaar toestaan.

## Nuitée actuele beschikbaarheid en prijsbewaking — 8 oktober 2026

**Status: zelfstandige sandboxserververversing en ingelogde v1-catalogus geverifieerd. Publieke productiekoppeling blijft open.**

### Afgerond en getest
- Back-ups: GitHub `backup/pre-realtime-availability-2026-10-08` bevat oorspronkelijke main en Webflow-custom-code-export. Xano `backup-pre-availability-2026-10-08` bewaart logica; branches delen tabelrecords en zijn geen afzonderlijke databack-up.
- Private alleen-lezen route #1140 `GET supplier-deals/{deal_id}/availability` gepubliceerd op `nuitee-availability-2026-10-08`, met bestaande adminauth/guard en superadmin/platform_admin. Geen wijziging in v1 of bestaande deal-/orderrecords.
- Nieuwe search controleert goedgekeurde bezetting, hotel/kamer/tarief/voorwaarden, reisperiode, EUR, lokale kosten en minimummarge bij de vaste goedgekeurde verkoopprijs. Ontbrekende/gewijzigde kosten of onvoldoende marge blokkeren beschikbaarheid.
- Tariefselectiefout hersteld: eerst passende tarieven met ongewijzigde lokale kosten selecteren, daarna goedkoopste tarief en marge vergelijken. Regressies slagen voor een goedkoper gewijzigd tarief met geldig alternatief, omgekeerde volgorde, onvoldoende marge en alleen gewijzigde kosten.
- Echte sandboxrun voor #17: nhow Amsterdam RAI, 10–12 november 2026, twee volwassenen; 4,07s; beschikbaar met €201,19 leverancier, €241,43 verkoop, €31,44 marge na reserves en geen uitgesloten lokale kosten. De eerdere conditions_changed-uitkomst kwam door de inmiddels gecorrigeerde tariefselectie.
- Adminlogin als Jurgen Hassankhan/Superadmin geslaagd; eerdere mislukte aanmelding betrof een ander account. Geen rechten aangepast. Ingelogde private preview toont hotelnaam, foto, vaste prijs en actuele beschikbaarheid. Ongeldige data blokkeren meteen; na herstel verschijnt verse beschikbaarheid. Automatische verversing na 45 seconden waargenomen.
- PR #13 merged `f09e293c6fd0b0552c7c673afc26514c065a5dc0`; PR #14 merged `c4e3f8057bd232b9171330f5997f8ad6bcd481ba`; GitHub Pages-uitrol geslaagd.
- Beveiligde `admin/availability-catalog.html` daadwerkelijk ingelogd getest: 1 van 2 goedgekeurde sandboxdeals zichtbaar, nhow €241,43 met foto; onbevestigd ander testaanbod verborgen. Alleen verse, goedgekeurde, bij dezelfde prijs passende resultaten zichtbaar; providerfout/verlopen resultaat verwijdert kaart uit testweergave, zonder dealrecord te wijzigen. Maximaal twee gelijktijdige requests, 45-seconderefresh, 60-secondenverval en oude antwoorden genegeerd.
- Tests voor policy/controller/catalog slagen. Snapshot-policytest slaagt voor verval, toekomstige/te lange tijdstempels, gewijzigde goedkeuring/prijs/reisperiode/mapping/kostenconfiguratie, pending, verkeerde deal/omgeving en betaling aan.
- Nuitée levert hier geen exact kameraantal; quantity blijft null, tariefaantal is geen voorraad. Dit is periodiek bevestigde beschikbaarheid, geen kamerreservering of garantie.

- Xano-toegang hersteld. Check #306 uitgevoerd: deal17 beschikbaar, vaste verkoop €241,43, leverancier €204,22, marge na reserves €28,41; can_pay=false.
- Refresh #307 gebouwd en uitgevoerd (3,67s), alleen aparte snapshots in tabel105. Iedere run bezit zijn eigen record; reader selecteert nieuwste started_at/id, zodat oudere langzame runs nieuwere beschikbaarheid niet overschrijven.
- Privé-snapshotroute #1141 gecompileerd en getest met adminauth/guard: verlopen resultaat unknown/available=false in 370ms. Goedkeuring, prijs, mapping en configuratie opnieuw vergelijken; maximaal 60 seconden geldig.
- Sandboxtaak #28 handmatig uitgevoerd (3,02s). Nieuwe records: echte testdeal17 available, fictieve eerdere deal16 unknown.
- Alleen vijf nieuwe onderdelen naar v1 gemerged (twee private routes, twee functies, één inactieve taak); tien afwijkende bestaande endpoints en middleware uitgesloten. Doelbranchback-up aangevinkt.
- v1-taak #32 geactiveerd en gepubliceerd met minuutinterval. Zelfstandige runs om 15:44 en 15:45 Amsterdam aangetoond: tabel105 van drie naar zeven records; deal17 telkens available, deal16 unknown. Geen open aanbodpagina of handmatige Run nodig.
- PR15 merged a21583844ea2234e17a2a3e420b9a63c5910818b; Pages-uitrol geslaagd. Private catalogus leest nu v1 availability-snapshot, zodat het openen van de catalogus geen Nuitée-search start. Datumpreview blijft verse directe sandboxcontroles gebruiken. Syntax en gewijzigde catalogus/snapshotpolicytests slagen.

- Laatste ingelogde controle 8 oktober circa 16:02 Amsterdam geslaagd als Jurgen Hassankhan/Superadmin. Gepubliceerde snapshotcatalogus toont nhow Amsterdam RAI met foto, vaste €241,43 en 1 van 2 sandboxdeals beschikbaar; onbevestigd deal16 blijft verborgen. Dit verifieert ook de verse private v1-snapshotroute via de echte portalrequests.
- Tijdens de vervolgcontrole verliep de snapshot en werd 0/2 met ‘Geen vers bevestigd aanbod’ getoond. De conservatieve zichtbaarheidsovergang is dus ook werkelijk waargenomen; geen dealrecord verwijderd of afgekeurd. Minuutinterval/60-secondengeldigheid blijft een productieverbeterpunt.

### Nog te doen voor publieke stap 3 en livegang
- Sandboxplanning: maximaal tien mappings, per minuut. Productie vereist eerlijke paginering, providerlimieten en begrensde snapshotbewaring. Afzonderlijke records voorkomen overschrijven door overlappende workers; dit is geen onbeperkt productiearchief.
- Checking/fout/verval verbergt beschikbaarheid; minuutinterval met 60 seconden geldigheid kan kort conservatief verborgen aanbod veroorzaken.
- Publieke productiecatalogus/detailfilter aansluiten achter productiepoort; onbeschikbaarheid voor één datum mag het hele hotel niet archiveren. Webflow niet gewijzigd.
- Prebook/definitieve kosten vóór betaling en order-/betaal-/leveranciersboeking afronden in volgende stappen. Sandboxvloer €1,30 processing en Stripe-reserve zijn geen bewezen productiekosten.
- Publieke provider_sync-poorten in v1 blijven dicht. Geen productiecredentials, echte boeking, betaling of publieke Nuitée-deal geactiveerd.

## Gebruik van dit bestand

Dit bestand moet na iedere technische wijziging worden bijgewerkt.

Een onderdeel mag alleen naar **Afgerond en getest** wanneer de relevante flow aantoonbaar is uitgevoerd. Alleen aanwezige code hoort bij **Gebouwd maar nog te verifiëren**. Externe toegang, productiecredentials of een echte partner die nog ontbreken horen bij **Nog te doen**.

Bij iedere nieuwe werksessie:

1. Lees eerst dit bestand.
2. Controleer de datum en de laatste relevante GitHub-wijzigingen.
3. Werk na de wijziging ook deze status bij.
4. Verplaats een punt pas naar “Afgerond en getest” wanneer de test daadwerkelijk is geslaagd.
5. Noteer bij twijfel de onzekerheid; vul niets in op basis van een oude chat of aanname.

---

## Opruiming Integratiebeheer — 8 oktober 2026

- Het losse verwijzingsblok ‘Leveranciersaanbod en boekingen’ onder de integratietabel verwijderd. Nuitée blijft in de bestaande lijst; leverancierspagina en connectorcode zijn ongewijzigd.
- Gecontroleerd: uitsluitend één HTML-sectie verwijderd; integratietabel, modals en scriptversies behouden. Jurgen heeft bevestigd dat Nuitée zichtbaar is in de lijst.

## Nuitée zichtbaar in Integratiebeheer — 8 oktober 2026

- Nuitée verschijnt als alleen-lezen leverancierskoppeling in dezelfde integratietabel, zonder apart blok; huidige fase is sandbox, productie nog niet vrijgegeven. De weergave claimt geen actuele verbindingstest.
- Bestaande hotelrijen, acties, backendkoppelingen en overige portalpagina’s zijn ongewijzigd. De rij verschijnt op de eerste pagina wanneer de leveranciersfunctie is ingeschakeld en er op die pagina geen Nuitée-integratie uit de bestaande API staat.
- Gecontroleerd: JavaScript-syntax, tabelweergave bij lege en bestaande hotelintegraties, behoud van hotelacties, dubbele Nuitée-rij voorkomen bij bestaand providerrecord, zeven kolommen en geen mutatieactie op de leveranciersrij. Ingelogde visuele controle blijft open.

## Adminindeling — 8 oktober 2026

- **Partners** beheert de bestaande eigen hotelpartneraccounts; routes, formulieren en statusacties blijven behouden.
- **Leveranciers** is een aparte pagina voor Nuitée: reeds geïmporteerde leveranciersdeals, omgevingen, prijsvoorbeelden en het bestaande boekings-/margeoverzicht. Dit is geen volledige Nuitée-catalogus of nieuwe importfunctie.
- **Deals** blijft centraal voor beide aanbodbronnen, met een bronfilter. Goedkeuring, prijswijzigingen en indienen gebruiken de bestaande detailpagina en backend.
- **Integratiebeheer** blijft voor providers, sleutels en technische koppelingen; leveranciersboekingen zijn naar Leveranciers verplaatst.
- Dashboard toont actieve partneraccounts, publiek vrijgegeven deals, beoordeling, huidige omzetadministratie en leveranciersaanbod/boekingen. Testaccounts en mogelijk aanwezige testomzet zijn expliciet aangeduid. De teller publiek vrijgegeven sluit testintegraties en alle momenteel geblokkeerde `provider_sync`-deals uit.
- **Gecontroleerd:** JavaScript-syntax; dashboardrendering; foutmelding bij onbereikbare beoordelingsbron; partner-/leveranciersfilter; volledige paginering en geweigerde onvolledige lijst; onderscheid test/productie in de teller; nieuwe leverancierscode gebruikt uitsluitend leesaanroepen; cacheversies van pagina's met de adminshell.
- **Nog te verifiëren:** visuele controle met een ingelogde beheerderssessie en de actuele API-data. De beschikbare browsersessie staat op het loginformulier; deze wijziging is niet als volledig end-to-end getest aangemerkt.
- **Veiligheid / terugval:** aparte branch `admin-suppliers-dashboard-2026-10-08`, gebaseerd op main-commit `e3d838f0c296763cd66b5749804beee3312fba3a`. Alleen portalbestanden en dit statusbestand gewijzigd. Geen Xano-, Webflow-, order-, dealrecord-, sleutel- of betaalwijzigingen.

---

## 1. Afgerond en getest

### Kernarchitectuur en backend

- Webflow is de publieke frontend.
- Xano is de centrale backend en bron van waarheid voor deals, orders, vouchers, voorraad en businesslogica.
- Stripe Checkout is gekoppeld aan de betaalflow.
- De Xano-origin is gemigreerd van de oude `x8ki-...` omgeving naar de nieuwe `xgrq-...` omgeving en de gebruikte frontendconfiguratie is daarop aangepast.

### Volledige verkoopflow in testmodus

De volgende keten is end-to-end uitgevoerd en geslaagd:

1. Deal openen vanaf de publieke website.
2. Check-in, check-out en aantal gasten vastleggen.
3. Stripe Checkout openen en een testbetaling afronden.
4. Orderstatus op `paid` zetten via de webhook.
5. Voucher en QR-code aanmaken.
6. Klant-, hotel- en interne e-mails versturen.
7. Boeking en voucher zichtbaar maken in het partnerportaal.
8. Verkoop en omzet verwerken in de dashboards.
9. Voorraad **exact één keer per betaalde order** verlagen.

Belangrijk: de automatische voorraadverlaging werkt. Een eerdere vermelding dat de MVP geen definitieve decrement had, is verouderd en onjuist.

### Betalingen en veiligheid

- Stripe Checkout Session-flow werkt in testmodus.
- Billing address en telefoonverzameling zijn ingericht.
- Metadata koppelt Stripe aan `order_id` en `deal_id`.
- De webhook verwerkt `checkout.session.completed`.
- Webhook-idempotency voorkomt dubbele verwerking.
- Refundlogica en voucher-invalidatie zijn gebouwd.
- Mislukte betalingen maken geen geldige voucher aan.

### Publieke website

- Publieke homepage-preview is gebouwd en gepubliceerd.
- Dynamische actieve deals worden vanuit Xano geladen.
- Dealkaarten en deal-detailpagina zijn gekoppeld.
- Categorieën, filters en responsive weergave zijn gebouwd.
- FAQ is toegevoegd.
- Basis-SEO-structuur, metadata en SeasonDeals-huisstijl zijn aangebracht.
- De publieke testomgeving blijft tijdens de testfase op `noindex`.

### Partnerportaal

- Login en authenticatie via Xano `hotel_users` werken.
- Dashboard werkt.
- Deals bekijken, aanmaken als concept, bewerken en indienen ter goedkeuring werken.
- Boekingen en vouchers worden getoond met klantnaam, e-mail, telefoon, dealtitel, vouchercode en status.
- Eerdere permission- en mappingproblemen bij boekingen/vouchers zijn opgelost.
- Verkoop- en omzetinformatie wordt weergegeven.

### Adminportaal

- Adminlogin en rollenstructuur zijn gebouwd.
- Dealbeoordeling met goedkeuren en afwijzen werkt.
- Deal #9 is via de beoordelingsflow goedgekeurd en actief gezet.
- Prijsvelden `price`, `deal_price` en `original_price` zijn correct gemapt.
- Dashboard, orders, hotels en dealbeheer zijn aanwezig.
- Het Integraties-overzicht met hotel-detailvenster voor mapping-, sync-, webhook- en foutstatus is gebouwd en gepubliceerd op `main`.

### Hotelonboarding en API-sleutelbeheer

De volgende interne testflow is end-to-end uitgevoerd en geslaagd:

1. Vanuit het adminportaal een nieuw testhotel en de eerste gekoppelde hotelbeheerder aanmaken.
2. Het nieuwe hotel terugzien in het hoteloverzicht.
3. Met het aangemaakte beheerderaccount inloggen in het partnerportaal.
4. Vanuit Integratiebeheer een testintegratie aan het juiste hotel koppelen.
5. De integratie in het partnerportaal van het testhotel terugzien.
6. Een API-testsleutel aanmaken.
7. De verbinding met die sleutel succesvol testen.
8. De sleutel intrekken en bevestigen dat deze daarna niet meer actief is.
9. In het adminportaal terugzien dat er **0 actieve sleutels** zijn en dat de eerdere sleutel als **Ingetrokken** bewaard blijft, inclusief aanmaak- en laatst-gebruiktijd.

Daarmee zijn de interne aanmaakflow voor hotels, de koppeling met `hotel_users`, het beheer van hotelintegraties en de levenscyclus van API-sleutels technisch bewezen. Dit bewijst nog niet de uitnodigings-/activatieflow voor echte beheerders of een echte verbinding met SiteMinder.

### Connector Framework

- Het generieke Connector Framework is gebouwd.
- Integration API, API-sleutels en connectorstructuur zijn aanwezig.
- De architectuur ondersteunt availability, reservering aanmaken/annuleren, beschikbaarheids- en prijssynchronisatie en foutlogging.
- Het adminportaal toont connector- en hotelintegratiestatus.

### Veiligheidsback-ups vóór Nuitee-werk

- GitHub-terugvalbranch `backup/pre-nuitee-live-2026-10-05` is vanaf de toenmalige `main` vastgelegd.
- Webflow-back-up **Pre-Nuitee & Livegang – 5 oktober 2026** is aangemaakt en gecontroleerd (27 pagina's, 146 stijlen, 396 elementen).
- Xano-ontwikkelbranch `nuitee-integration-2026-10-05` is aangemaakt; wijzigingen worden daar voorbereid en niet rechtstreeks gepubliceerd.
- Xano-logicaclone **SeasonDeals Backup Pre Nuitee - 20261005** is aangemaakt met de tabellen, API-groepen, API-query's, functies, addons en taken van de hoofdworkspace.
- Tijdens deze back-upstap zijn geen deals, sleutels of productieconfiguraties gepubliceerd of geactiveerd.

### Nuitée-sandboxauthenticatie en hoteldata

- Het bestaande Nuitée-account is gecontroleerd: de sandboxkey is actief en productie blijft vergrendeld.
- De correcte volledige sandboxkey is als afgeschermde Xano-workspacevariabele `NUITEE_SANDBOX_API_KEY` opgeslagen; de sleutel komt niet in frontendcode, logs of responses.
- Op Xano-branch `nuitee-integration-2026-10-05` is de alleen-lezen adapterfunctie `connector/adapters/nuitee/list_hotels` gebouwd.
- De functie gebruikt uitsluitend de officiële gratis Hotel Data API, valideert invoer, laat lege optionele parameters weg en geeft gestandaardiseerde succes- en foutresponses terug.
- Een echte sandboxaanroep voor `NL / Amsterdam` is op 5 oktober 2026 geslaagd: **5 hotels** ontvangen in circa **310 ms**, inclusief provider-ID, naam, adres, coördinaten, sterren, reviews, foto-URL's, faciliteiten en valuta.
- De alleen-lezen adapterfunctie `connector/adapters/nuitee/search_rates` is gebouwd en getest met hotel `lp225fcf`, twee volwassenen en één nacht: **1 hotel met boekbare rate** ontvangen in circa **2,13 s**, inclusief kamer- en rate-ID, `offerId`, kostprijs, aanbevolen verkoopprijs, belastingen/toeslagen, betaaltype en annuleringsstatus.
- Voor de geteste rate gaf Nuitée onder meer €116,12 retail, €116,35 aanbevolen verkoopprijs, €12,60 niet-inbegrepen toeslagen en status `NRFN`; deze bedragen zijn uitsluitend testdata en mogen nog niet op de publieke website worden gepubliceerd.
- De sandboxfunctie `connector/adapters/nuitee/prebook` is gebouwd en op 5 oktober 2026 succesvol uitgevoerd met hetzelfde aanbod. Nuitée bevestigde de kamer, €116,12 prijs, €116,35 aanbevolen verkoopprijs, €12,60 niet-inbegrepen toeslag, `NRFN` en betaalmogelijkheden in circa 850 ms.
- De prebook gebruikt verplicht `usePaymentSdk=false`; er is geen Stripe PaymentIntent of productiefunctionaliteit geactiveerd.
- De sandboxfuncties `connector/adapters/nuitee/create_booking`, `get_booking` en `cancel_booking` zijn gebouwd en end-to-end getest met fictieve gastgegevens en betaalmethode `ACC_CREDIT_CARD` (uitsluitend sandboxsimulatie, zonder echte afschrijving).
- De testboeking werd als `CONFIRMED` en `sandbox` teruggegeven, kon opnieuw worden opgehaald en is daarna geannuleerd. Omdat het aanbod `NRFN` was, retourneerde Nuitée correct `CANCELLED_WITH_CHARGES`, €116,12 annuleringskosten en €0 terugbetaling.
- De boekingsresponse bevatte daarnaast een processing fee van €1,30. Deze moet vóór productie als afzonderlijke financiële component in de SeasonDeals-marge- en reconciliatielogica worden verwerkt.
- Voor leveranciersboekingen is op de Xano-ontwikkelbranch de aparte tabel `supplier_bookings` toegevoegd. Deze bewaart uitsluitend genormaliseerde technische en financiële gegevens; volledige gastgegevens, kaartgegevens en ruwe providerpayloads worden niet opgeslagen.
- De functie `connector/pricing/calculate_supplier_price` is gebouwd en getest met de echte Nuitée-sandboxbedragen. Bij €116,12 inkoop, €1,30 processing fee, 3% + €0,25 gereserveerde Stripe-kosten, 15% doelmarge en €5 minimum marge berekende de functie een veilige verkoopprijs van €143,50, €4,56 geschatte Stripe-kosten en €21,52 marge. De €12,60 lokale heffingen blijft expliciet buiten de checkout en wordt als te betalen bij de accommodatie gemarkeerd.
- De functie `connector/nuitee/upsert_supplier_booking` is gebouwd en getest. De eerste sandboxrun maakte één record aan; dezelfde externe boeking opnieuw verwerken werkte als update op hetzelfde record en maakte geen duplicaat. Nulwaarden voor commissie en refund worden geaccepteerd, negatieve financiële waarden blijven geblokkeerd.
- Er zijn geen echte klantgegevens, betalingen of productieboekingen verwerkt. Er staat uitsluitend één herkenbaar gemarkeerd sandboxrecord in de nieuwe tabel.
- De negen nieuwe Nuitée-functies en het private admin-endpoint zijn gecontroleerd naar Xano-branch `v1` samengevoegd. Tien afwijkende bestaande endpoints en de middleware-instelling zijn bewust uitgesloten van de merge.
- `GET /supplier-bookings` is op `v1` live getest: 1 sandboxrecord, 0 productierecords, €143,50 verkoopwaarde, €116,12 leverancier, €21,52 marge en €116,12 annuleringskosten.
- Het adminportaal toont op `main` onder Integratiebeheer de Nuitée-boeking en margecontrole. De gepubliceerde pagina is op 6 oktober 2026 ingelogd en visueel getest; gast-, kaart- en ruwe providergegevens worden niet getoond.

---

## 2. Gebouwd maar nog te verifiëren

### Nuitée-conceptdeal en prijsregels — bijgewerkt 8 oktober 2026

- De drie private portalroutes GET, prijsbeheer en workflow zijn op 7 oktober naar `v1` gemerged; de importroute #782 blijft uitsluitend een ongepubliceerd concept op `nuitee-deal-import-2026-10-07`.
- PR #9 is naar main gemerged. Prijsregels, inhoud opslaan, indienen en sandboxgoedkeuring zijn op de gepubliceerde portal met fictieve deal #16 uitgevoerd. Laatste prijs €136; goedgekeurd in sandbox met `is_active=false`. De bestaande hotelgoedkeuring is niet gewijzigd.
- De foutieve vermelding dat deze portalroutes en featureflag nog niet gepubliceerd waren is hiermee gecorrigeerd.
- Op 8 oktober is via de officiële Nuitée-search_rates-adapter nieuw aanbod opgehaald: hotel `lp225fcf`, nhow Amsterdam RAI, 10–12 november 2026, één kamer, twee volwassenen. Eén hotel met drie tarieven ontvangen in circa 3,29 seconden.
- Het geselecteerde tweede aanbod is Nhow Room / Room Only, €201,19 totaal voor twee nachten, niet-restitueerbaar (`NRFN`). Het leverancierstarief bevat City tax €25,15 en VAT €42,25 volgens de sandboxresponse; geen uitgesloten toeslagen in deze specifieke rate.
- Dit werkelijke API-antwoord is als deal #17 en supplier_deal #2 opgeslagen: `draft`, `is_active=false`, voorraad 0. Verkoopregel: 20% opslag → €241,43; €1,30 processingreserve, 3% + €0,25 Stripe-reserve en €20 minimummarge. Het betreft sandboxaanbod, geen productievoorraad of echte boeking.
- Kamer/rate/offer-ID, bronresponse, voorwaarden, reisdata, hotelmetadata en foto-URL zijn bij het concept opgeslagen. Het testrecord verwijst intern nog naar hotel #1; dit is geen rechtstreeks contract met nhow.
- Importconcept #782 heeft nu admin/guard, expliciete adminrol, sandbox/provider/hotel-ID/positieve-prijscontrole en een blokkade op herhaalde import-ID. Volledige server-side offerverificatie en atomaire deal/supplier-opslag blijven vóór een productie-import nodig. De import is niet gepubliceerd of naar v1 gemerged.
- Jurgen heeft deal #17 ingediend en goedgekeurd. De daaropvolgende publieke zichtbaarheid onthulde op 8 oktober een filterfout: actieve supplierdeals zonder hotel_integration_id vielen door de handmatige route. Eerdere claim dat is_active=false dit voldoende afschermde was onjuist.
- Hersteld en gepubliceerd op v1: Public API GET /deals (#63), GET /deals/{deal_id} (#64), GET /deal/{deal_id} (#71) blokkeren provider_sync-aanbod zolang de productieflow niet klaar is. Checkout #68 en orderroute #65 blokkeren die bron eveneens; bestaande handmatige/partnerfilter blijft behouden.
- Backendverificatie: publieke lijst retourneert alleen IDs 4, 7, 9, 1, 8, 10, 2; sandbox #16 en #17 ontbreken. Directe GET /deal/17 geeft ERROR_CODE_NOT_FOUND. Geen betaling of nieuwe order uitgevoerd. Publieke HTTP-verificatie vanuit browser werd door client geblokkeerd; deze controles zijn in de Xano-debugger uitgevoerd.
- Fotoherstel: adminoverzicht gebruikt external_image_urls als fallback naast images; detailpagina gebruikt supplier_content.hotel.images. Main cacheversies bijgewerkt. Deployment en zichtbare foto zijn nog door Jurgen te bevestigen.
- Portalcode op main toont voor supplierconcepten de hotelnaam en foto uit supplier_content, met cacheversie `20261008-1`. De browsercontrole van deze nieuwe conceptdeal wordt op verzoek door Jurgen gedaan; niet als door de agent geverifieerd markeren.
- De eerder afgeronde prijs-, betaling- en bookingtests zijn op 8 oktober niet herhaald. Geen productiecredentials, betaling, reservering of publieke deal geactiveerd.

### Nuitee-connector en voorraadroute

- De bestaande SeasonDeals-basis en het generieke Connector Framework blijven het uitgangspunt; er wordt geen nieuw los boekingssysteem naast gebouwd.
- De eerste echte Nuitée-provideradapter is gebouwd en voor alleen-lezen hotelmetadata in sandbox getest.
- Hotelmetadata en prijs/beschikbaarheid zijn als afzonderlijke alleen-lezen functies gebouwd en in sandbox getest.
- Quote/prebook, booking, retrieval en cancellation zijn als afzonderlijke sandboxfuncties gebouwd en end-to-end getest. Genormaliseerde prijsberekening en idempotente leveranciersboekingopslag zijn eveneens getest. De volgende stap is de gecontroleerde orchestratie met de bestaande SeasonDeals-orders en betalingen, plus adminweergave en connectorlogs, voordat publicatie mogelijk is.
- De basisweergave voor Nuitée-boekingen en margecontrole is gepubliceerd en visueel getest. Providerstatus, accommodatiemappings, connectorlogs, volledige reconciliatie en koppeling aan echte SeasonDeals-orders moeten nog verder worden uitgewerkt.
- SEO-landingspagina's en dealweergave mogen pas op echte Nuitee-data worden aangesloten nadat prijs, beschikbaarheid, voorwaarden en boekingsflow aantoonbaar zijn getest.
- Er wordt nog geen echte Nuitée-voorraad, productieboeking of betaling geactiveerd voordat de volledige order-, betaal- en annuleringsflow is geverifieerd.

### Xano-recordexport

- De hoofdworkspace bevatte bij start **34 tabellen en 714 records**.
- Omdat een Xano-workspaceclone bewust geen tabelrecords kopieert, is op 5 oktober 2026 aanvullend een volledige data-export zonder media gestart.
- De exportjob is aangemaakt; voltooiing en download moeten nog worden bevestigd voordat dit punt als volledig afgerond geldt.

### Stripe-productieconfiguratie

- De testomgeving en testbetaling zijn bewezen werkend.
- De aanwezigheid en juiste plaatsing van de **Stripe live secret key**, **live publishable key** en het **live webhook signing secret** in Xano/productie zijn nog niet opnieuw gecontroleerd.
- Er is nog geen echte livebetaling met een klein bedrag uitgevoerd.

### SiteMinder-demo-adapter

- De SiteMinder-adapter en bijbehorende flow zijn als werkende connectorcode gebouwd.
- De huidige servercommunicatie gebruikt Xano-demodata voor hotel-, kamer-, prijs- en beschikbaarheidsinformatie.
- Dit bewijst het connectorpatroon, maar nog niet een echte verbinding met SiteMinder.

### Webflow-contentpagina’s en routes

De inhoud en SEO-opzet bestaan voor:

- Over ons
- Partner worden
- Inspiratie
- Veelgestelde vragen
- Privacy
- Algemene voorwaarden
- Cookies

Nog te controleren in de uiteindelijke Webflow-publicatie:

- Alle zeven routes openen zonder 404.
- Footerlinks verwijzen naar de juiste Webflow-routes.
- Logo en navigatielinks gaan naar de juiste publieke pagina.
- Mobiel menu en cookievoorkeuren werken op iedere route.
- “Werken bij” staat nergens meer.
- Typografie en lettergroottes zijn overal gelijk.
- Canonicals en metadata staan correct.
- `noindex` staat alleen tijdens de testfase aan.

### Praktijktest partnerportaal

- De technische partnerflow is gebouwd en intern getest.
- De volledige flow is nog niet door een echte hotelpartner met een echte commerciële deal doorlopen.

---

## 3. Nog te doen

### Productierijpe hotelonboarding

- Na het aanmaken van een hotel de eerste beheerder als `pending` registreren.
- Een eenmalige, aflopende activatielink genereren.
- Via Resend automatisch een SeasonDeals-uitnodigingsmail naar de beheerder versturen.
- De beheerder via de activatielink zelf een wachtwoord laten instellen.
- Het account pas na geldige activatie op `active` zetten.
- Opnieuw uitnodigen en verlopen/gebruikte activatielinks veilig afhandelen.
- Het vrije veld voor extern hotel-ID uit de normale aanmaakflow halen.
- Voor de demo automatisch een herkenbaar demo-ID op basis van het SeasonDeals-hotel opslaan.
- Bij een echte SiteMinder-verbinding het externe hotel-ID automatisch bij SiteMinder ophalen; bij meerdere gevonden hotels een gecontroleerde keuze tonen en het gekozen ID daarna alleen-lezen opslaan.

### Voor de eerste echte partner

- Eerste echte hotelpartner onboarden.
- Hotelaccount aanmaken en toegang laten testen.
- Eerste echte deal samen invoeren en laten indienen.
- Deal inhoudelijk en commercieel beoordelen.
- Deal goedkeuren en publiceren.
- Beschikbaarheid en voorraad met het hotel bevestigen.
- Echte klantreis met die deal uitvoeren.

### Stripe van test naar live

- Stripe-account volledig livegeschikt en geverifieerd maken.
- Live keys en live webhook signing secret in de juiste productieconfiguratie plaatsen.
- Controleren dat test- en livegegevens strikt gescheiden zijn.
- Live webhook-endpoint controleren en een live event laten afleveren.
- Eén echte betaling met klein bedrag uitvoeren.
- Order, voorraadverlaging, voucher, QR-code en alle e-mails controleren.
- Indien van toepassing de testbetaling terugbetalen en voucher-invalidatie controleren.

### Nuitee-productie-integratie

- Nuitee-bedrijfsaccount en het passende commerciële model definitief vastleggen zonder vaste aansluitkosten, indien Nuitee dit accepteert.
- Test- en productiecredentials veilig in Xano-omgevingsvariabelen plaatsen.
- De bewezen sandboxfuncties voor authenticatie, hoteldata, prijs/beschikbaarheid, prebook, booking, retrieval en cancellation in de bestaande SeasonDeals-orderflow orchestreren en veilig opslaan.
- Supplier reference, netto/bruto bedragen, marge, valuta, belastingen, annuleringstermijnen en betaalstatus volledig opslaan.
- Idempotency, retries, time-outs, rate limits en foutlogging testen.
- Nuitee zichtbaar maken in het adminportaal en minimaal één end-to-end testboeking plus annulering uitvoeren.
- Pas daarna echte Nuitee-voorraad en SEO-landingspagina's publiceren.

### Eerste echte hotel-systeemkoppeling

- Officiële SiteMinder-toegang en documentatie verkrijgen.
- Productie- of sandboxcredentials ontvangen.
- Hotel-, kamer-, tarief- en beschikbaarheidsmapping vastleggen.
- Demo-aanroepen vervangen door echte SiteMinder API-aanroepen.
- Reservering aanmaken en annuleren end-to-end testen.
- Voorraad- en prijssynchronisatie testen.
- Webhooks, retries en foutafhandeling met echte responses testen.
- Daarna pas de SiteMinder-koppeling als “afgerond en getest” markeren.

### Juridisch en content

- Definitieve bedrijfsgegevens invullen in Privacy en Algemene voorwaarden.
- Privacyverklaring, cookiebeleid en Algemene voorwaarden juridisch laten controleren.
- Definitieve partnervoorwaarden en afspraken vastleggen.
- Controleren of de cookie-instellingen aansluiten op werkelijk gebruikte cookies en scripts.

### Definitieve livegangcontrole

- Publieke domeinroutes en redirects controleren.
- `noindex,nofollow` verwijderen van pagina’s die geïndexeerd moeten worden.
- Sitemap en robots-instellingen controleren.
- Canonical URLs controleren.
- Mobiel, tablet en desktop testen.
- Formulieren, links, filters en checkout testen.
- Xano-productieconfiguratie en secrets controleren.
- Stripe livebetaling end-to-end testen.
- E-mailaflevering en afzenderdomein controleren.
- Logging, foutmeldingen en herstelprocedures controleren.
- Back-up/export van kritieke configuratie vastleggen.
- Go/no-go-moment uitvoeren en pas daarna de oude landingspagina vervangen.

---

## Eerstvolgende aanbevolen mijlpaal

**Nuitee als eerste schaalbare voorraadbron veilig aansluiten:**

1. Nuitee-account, commercieel model en API-toegang definitief bevestigen.
2. Provideradapter in de bestaande Xano-connectorarchitectuur bouwen op de ontwikkelbranch.
3. Nuitee-status, mappings, boekingen, financiële gegevens, annuleringen en logs in het adminportaal tonen.
4. Zoek-, prijs-, beschikbaarheids-, boekings- en annuleringsflow end-to-end testen.
5. Stripe-liveconfiguratie en SEO/livegangchecklist afronden.
6. Pas na een go/no-go de gecontroleerde Nuitee-voorraad publiceren.

---

## Wijzigingslog

| Datum | Wijziging |
|---|---|
| 2026-10-08 | Zelfstandige serververversing: check306, refresh307, private reader1141 en taak28 gebouwd; alleen vijf toevoegingen naar v1. Taak32 per minuut actief, runs15:44/15:45 bewezen. PR15/Pages gepubliceerd; ingelogde portalcontrole vervolgens geslaagd: nhow met foto/€241,43; verse en verlopen snapshotweergave waargenomen. Publieke productiepoort behouden. |
| 2026-10-08 | PR14 gepubliceerd en ingelogd getest: nhow beschikbaar voor €241,43 met foto; 1/2 sandboxdeals in verse catalogus, 45s verversing. Tariefselectiefout opgelost. Snapshotopslag #105 en checkfunctie #306 aangemaakt; overige serververversing voorbereid in draft PR15 maar geblokkeerd door Xano-browserbediening. Publieke stap3 blijft open. |
| 2026-10-08 | Publieke sandboxlekkage na goedkeuring hersteld: provider_sync geblokkeerd in publieke lijst, beide detailroutes en normale checkout/orderroutes. Lijst zonder #16/#17 en Not Found voor /deal/17 in Xano bevestigd. Adminafbeeldingfallback toegevoegd; zichtbare foto nog te bevestigen. |
| 2026-10-08 | Werkelijk Nuitée-sandboxtarief voor nhow Amsterdam RAI opgehaald en opgeslagen als conceptdeal #17 / supplier_deal #2 (€201,19 leverancier, €241,43 verkoop; twee nachten). Brondata en inhoud opgenomen; supplierhotelnaam/foto in portalcode aangesloten. Jurgen doet de portalcontrole. Import blijft ongepubliceerd; geen publieke deal of echte transactie. |
| 2026-10-07 | Drie Nuitée-portalroutes naar v1 gemerged en PR #9 op main gepubliceerd. Opslaan van prijs (€136) en inhoud, indienen en sandboxgoedkeuring uitgevoerd op fictieve deal #16; active met is_active=false. Volledige API-aanbodimport blijft open. |
| 2026-10-06 | Gecontroleerde Nuitée-release afgerond: uitsluitend 9 nieuwe Xano-onderdelen naar `v1` gemerged; 10 afwijkende bestaande endpoints en middleware uitgesloten. Privé endpoint live getest met 1 sandboxboeking en 0 productieboekingen. Adminweergave via PR #7 gepubliceerd; filterfout hersteld via PR #8 en aanvullende lege-parametercorrectie. Gepubliceerde Integratiebeheerpagina visueel getest met €143,50 verkoop, €116,12 inkoop, €21,52 marge en €116,12 annuleringskosten. Geen echte boeking, betaling, refund of productievoorraad geactiveerd. |
| 2026-10-05 | Nieuwe tabel `supplier_bookings` toegevoegd op de Xano-ontwikkelbranch, zonder bestaande orders of deals te wijzigen. Veilige prijsfunctie getest met Nuitée-bedragen (€143,50 verkoopprijs en €21,52 geschatte marge) en privacyveilige upsertfunctie getest op create + update zonder duplicaat. Eén duidelijk gemarkeerd sandboxrecord opgeslagen; geen gast- of kaartgegevens en geen productiepublicatie. |
| 2026-10-05 | Volledige Nuitée-sandboxketen uitgevoerd: prebook, testboeking via `ACC_CREDIT_CARD`, booking retrieval en cancellation. Boeking bevestigd en opgehaald; niet-restitueerbare annulering gaf correct €116,12 kosten en €0 refund. Ook €1,30 processing fee vastgesteld. Geen echte betaling, klantgegevens, databasewrite of productieactivatie uitgevoerd. |
| 2026-10-05 | Nuitée-functie `connector/adapters/nuitee/prebook` gebouwd en succesvol getest met `usePaymentSdk=false`: prijs, toeslagen, annuleringsstatus en betaalmogelijkheden bevestigd in circa 850 ms. Geen definitieve boeking, betaling, Stripe PaymentIntent, databasewijziging of productieactivatie uitgevoerd. |
| 2026-10-05 | Nuitée-functie `connector/adapters/nuitee/search_rates` gebouwd en succesvol getest: één Amsterdamse hotelrate met offer-ID, prijzen, toeslagen, betaaltype en annuleringsstatus ontvangen in circa 2,13 s. Geen prebook, boeking, betaling of productieactivatie uitgevoerd. |
| 2026-10-05 | Nuitée-sandboxauthenticatie hersteld en geverifieerd. Veilige Xano-variabele bijgewerkt; alleen-lezen functie `connector/adapters/nuitee/list_hotels` gebouwd en succesvol getest met 5 Amsterdamse hotels in circa 310 ms. Geen boeking, kosten, databasewijziging of productieactivatie uitgevoerd. |
| 2026-10-05 | Voor Nuitee-werk veiligheidsback-ups vastgelegd: GitHub-terugvalbranch, Webflow-back-up, Xano-ontwikkelbranch en Xano-logicaclone. Aparte Xano-recordexport van 714 records gestart. Nuitee-scope en productieblokkade in status vastgelegd. |
| 2026-08-10 | Interne hotelonboarding end-to-end getest: hotel en beheerder aangemaakt, partnerlogin geslaagd, integratie gekoppeld, API-sleutel aangemaakt en getest, sleutel ingetrokken en ingetrokken status in admin bevestigd. Uitnodigingsmail/activatielink, automatisch extern hotel-ID, echte hotelpartner en echte SiteMinder-verbinding blijven openstaan. |
| 2026-08-05 | Adminflow **Nieuw hotel** gebouwd op het bestaande Xano-endpoint `/partners/create`; dashboardactie, formulier, gekoppelde hotelbeheerder, validatie en veilige wachtwoordgenerator toegevoegd. Nog te testen met de eerste echte partner. |
| 2026-08-05 | Eerste centrale statusbestand aangemaakt. Voorraadverlaging en Connector Framework als gebouwd/werkend gecorrigeerd; Stripe-liveconfiguratie, echte partner/deal en echte SiteMinder-koppeling als open punten vastgelegd. |


## Nuitée stap 5 — adminportaal (11 oktober 2026)

Status: **stap 5 adminoverzicht gepubliceerd en ingelogd gecontroleerd op 11 oktober 2026.**

- Step 4 blijft afgerond en getest in sandbox.
- Alleen GET /supplier-bookings is vanuit ontwikkelbranch12 naar v1 samengevoegd, met de terugvalkopieoptie aan. De 15 andere toevoegingen, 10 andere endpointwijzigingen en middleware zijn uitgesloten.
- Backendbron: backend/xano/nuitee-step5-supplier-bookings.xs.
- Leest bestaande order-, deal-, voucher- en checkoutgegevens; verrijkt hotel/verblijf/financiën/mailstatus.
- Hoofdletterongevoelig zoeken en statusfilter werken vóór paginering en samenvatting.
- Xano-controles: CONFIRMED + NHOW levert order100 met 10–12 november, €241,43 verkoop, €205,20 leverancier, €33,64 marge; ACTION_REQUIRED levert bestaande booking_failed_after_payment; productie levert 0 records.
- Front-endreview hersteld: geschatte versus werkelijke marge, nul als geldige werkelijke Stripe-kosten, onbekende omgeving, cacheversies en ongewenste escape op orderpagina.
- Node-controles geslaagd voor kostenprovenance, nul/ontbrekende kosten, onbekende omgeving, HTML-escaping en details openen/sluiten.
- Geen nieuwe boeking of betaling. Publieke Nuitée-productiepoort en partnerroute blijven ongewijzigd.
- PR #18 samengevoegd als `69a3c855ad7ec2e65832ffe7ebf2cb76c428c459`; Pages-uitrol #277 / `38168178348` geslaagd.
- V1-reader #550 met bestaande order100 gecontroleerd (223 statements, 1.23s). In de gepubliceerde portal gecontroleerd: vijf sandboxrecords, zoeken NHOW + Bevestigd, details openen/sluiten, kosten/voucher/QR/mail, Actie vereist met bestaande foutmelding, leeg productieresultaat, orderwaarschuwing en bijgewerkte integratiestatus.
- Historische onvolledige records blijven herkenbaar; deze worden niet door verzonnen hotel- of verblijfgegevens aangevuld.
- Het overzicht betreft supplier_bookings. Bewaking van checkout-intents zonder leveranciersrecord en schaaloptimalisatie van verrijking horen bij de verdere foutafhandeling/productievoorbereiding.

Zie [backend/xano/NUITEE_STEP5_ADMIN.md](backend/xano/NUITEE_STEP5_ADMIN.md).


## Nuitée stap 6 — bevestigingspagina (11 oktober 2026)

Status: **bevestigingspagina en statuskoppeling gepubliceerd en in de browser getest in sandbox. Terugkeerlinks geplaatst op testbranch14. Webflow-productiepagina blijft concept; geen productie-vrijgave.**

- SD-13: Webflow-site `68cb0d808ea4f2467bb313af` heeft 24 bestaande pagina's, zonder aparte bevestigingspagina. `/boeken` (pagina `695bd851c2b988eef5d14f96`) bevat de oude SimplyBook-widget. `/dea` gebruikt de bestaande GitHub `public-preview/js/deal.js` en Public API create-checkout-session. Geen wijzigingen aan deze routes.
- Gepubliceerde stap-4-bron #455 stuurt success/cancel naar de homepage. Stap 4 blijft sandbox bewezen; deze nieuwe terugkeerpagina hoort bij stap 6.
- Nieuwe Xano-branch14 `nuitee-step6-confirmation-2026-10-11` is aangemaakt vanuit uitsluitend gepubliceerde branch11-logica; de vier oude drafts zijn niet meegenomen. Gedeelde database blijft live; deze stap schrijft geen boekingsrecords.
- Alleen-lezen POST `supplier/confirmation-status`, Public API152 endpoint1985, gepubliceerd op branch14 met Cache-Control no-store/private en Referrer-Policy no-referrer. Geen Stripe/Nuitée/Resend-acties. Een volledige Stripe-testsessie is vereist, gekoppeld aan intent/order/customer, maximaal 24 uur na aanmaak. Geen lookup met alleen een ordernummer. Alleen minimale reserveringsinformatie; geen gastnaam, e-mail, betaalreferenties of interne kosten.
- Xano-run bestaande order100: confirmed, paid, sent; nhow Amsterdam Rai, 10–12 november, 2 gasten, EUR241.43, boekingsnummer en actieve voucher. 11 statements / 0.52s. Input `100` wordt geweigerd met Not Found / Confirmation unavailable (10ms).
- Frontend toont afzonderlijk wachten op betaling, verwerking, bevestigd, aandacht nodig, geannuleerd, ontbrekende/verlopen link en netwerkfout. Betaling alleen geeft nooit een bevestigde boeking. Begrensde polling, printoptie, goedgekeurd logo en lokaal gegenereerde QR zonder externe QR-service.
- Lokale Node-controles slagen voor statusvoorwaarden, ingetrokken voucher, annulering/fout, aflopende toegang, dataminimalisatie, HTML-escaping en lokale QR.
- Webflow-conceptpagina `6acbead36631ab0d5cf3b9fd`, slug `boeking-bevestiging`, embed `b883ba38-59f9-74c3-6cdf-556cc786337a`. Draft=true; niet gepubliceerd. Assets via PR #19 samengevoegd naar main, commit `1fbbcb4e4cf96e94eb276165ab2347dd5f499697`; GitHub Pages-run `38170709509` geslaagd.
- Jurgen wil alleen verder met de nieuwe look. Oude Webflow-pagina's nu nadrukkelijk niet opruimen.
- Aangesloten browsercontrole: gepubliceerde GitHub Pages-pagina gebruikt de gepubliceerde Xano-reader en toont bestaande order100 als bevestigd/betaald, inclusief nhow, verblijfsdata, bedrag, referentie, goedgekeurd logo, lokale QR en verzonden mailstatus. Ontbrekende link toont de veilige foutstatus. Geen nieuwe boeking, betaling of mail.
- Branch14 functie591 (kopie van branch11 #455) gepubliceerd met uitsluitend twee URL-wijzigingen: success naar GitHub Pages `public-preview/boeking-bevestiging.html#session_id={CHECKOUT_SESSION_ID}`, cancel naar dezelfde pagina met `#cancelled=1`. Xano toont na publicatie nul drafts. Bron vóór/na: `backend/xano/create-sandbox-session-before-step6.xs` en `backend/xano/create-sandbox-session-step6.xs`.
- De testsessie wordt na ontvangst uit de URL verwijderd en alleen in de huidige tab bewaard. QR is voor SeasonDeals-administratie; geen Nuitée-hotelscanbelofte.
- Testgrens: geen nieuwe Stripe-checkout aangemaakt of afgerekend voor deze wijziging. De nieuwe return-template is in bron gecontroleerd; ontvangst van de bestaande sessie en ophalen/renderen van haar status zijn in de browser bewezen. Een verse Stripe-doorverwijzing is dus niet opnieuw end-to-end uitgevoerd. Bestaande sessies houden hun eerdere Stripe-return-URL.
- Branch11 #455, de geregistreerde branch11-sandboxwebhook, v1, partnerroute en bestaande Webflow-pagina's blijven ongewijzigd. Alleen nieuwe sessies via branch14 #591 krijgen de nieuwe links. Productieroute, Webflow-publicatie en productie-go/no-go blijven afzonderlijk open.


## Nieuwe Webflow-website klaarzetten — 11 oktober 2026

Status: **nieuwe Webflow-pagina's gepubliceerd na expliciete toestemming van Jurgen op 11 oktober 2026 om 22:23 Amsterdam. Coming Soon blijft de root-landingspagina. Nieuwe homepage/detail en bevestiging in de browser gecontroleerd; geen vrijgave echte Nuitée-boekingen.**

- SD-13 / REL-20261011-WEBREADY. Opdracht: nieuwe pagina's en verbindingen klaarzetten, echte Nuitée-betalingen/boekingen niet vrijgeven; oude pagina's niet opruimen. Bron Git main `07abcfc608d051710fb9369f0777dc1a37c5b615` en actuele Webflow-embeds/head/footer.
- Webflow-site `68cb0d808ea4f2467bb313af`: nieuwe homepage `6a5f73d431f70573692af960` (/new-website), detail `6a5f7754024f18d807219648` (/dea), bevestiging `6acbead36631ab0d5cf3b9fd` (/boeking-bevestiging). Oude Home/boeken/partnerpagina's ongemoeid; root-homepage niet vervangen.
- Homepage: previewknoppen Favorieten/Mijn account vervangen door hulplink; readonly datumplaceholder verduidelijkt naar datumkeuze bij deal; ongefundeerde algemene 4,8/5 verwijderd; nieuwsbrief toont expliciet binnenkort met contactlink, geen schijninschrijving. Voucher-/aankomsttekst aangepast zodat leveranciersbevestiging niet automatisch hotelscanbaarheid belooft.
- Detail-embed bijgewerkt naar bestaande juiste service-, privacy-, voorwaarden-, cookies- en bedrijfslinks. Cookievoorkeurenscript en CSS toegevoegd. Verwijzingen naar niet-bestaande mobile.css uit beide page-heads verwijderd; bestaande responsive site/deal-stijlen behouden. Geen checkoutcode, Xano-route of partnerlogica gewijzigd.
- Bevestigingspagina draft=false en SEO opgeslagen; nog niet gepubliceerd. Sandboxbanner en reader1985 blijven behouden. De eerdere step6-regel draft=true is hiermee vervangen; plaatsing is nog steeds ongepubliceerd.
- API bevestigde alle element/scriptwrites. Browser vóór wijzigingen: /new-website rendert bestaande partner-testdeals; Nuitée-sandboxdeals niet zichtbaar. Dat bewijst niet dat de nieuwe wijzigingen al live zijn.
- Losse paginapublicatie gaf HTTP400 Invalid parameter: pageId. Aansluitend volledige sitepublicatie naar www.seasondeals.nl, seasondeals.nl en Webflow-subdomein door automatische veiligheidscontrole geweigerd wegens mogelijk meepubliceren van andere wijzigingen en onvoldoende specifieke toestemming voor die brede actie. Niet omzeild, geen publicatie geslaagd.
- Terugval: actuele vooraf gelezen embeds + head/footer in `public-preview/webflow/checkpoints/pre-webflow-ready-20261011.json`; bevestigingspagina terug naar draft=true indien gewenst. Geen databasewrites/transacties.
- Open: toestemming voor volledige Webflow-sitepublicatie, daarna browsercontrole van de daadwerkelijk geplaatste nieuwe pagina's en nieuwe bevestigings-URL. Branch14 #591 wijst voorlopig correct naar de bewezen GitHub Pages-versie; niet naar een ongepubliceerde Webflow-URL omgezet. Account/favorieten/nieuwsbrief zijn niet alsnog gebouwd; volledige productieklantreis is geen afgeronde claim.

### Publicatie WEBREADY afgerond — 11 oktober 2026

- Na uitleg dat Coming Soon de landingspagina blijft gaf Jurgen expliciet toestemming: “Ja dan mag het”. De eerder genoemde automatische blokkade is hiermee opgelost; onderstaande publicatie vervangt de ongepubliceerde tussenstand hierboven.
- Volledige Webflow-sitepublicatie geaccepteerd voor www.seasondeals.nl, seasondeals.nl en Webflow-subdomein. Publish task `02f587d2-fcae-4d7a-9e72-90b2bd310a3e` (scope site).
- Werkelijk gepubliceerde browsercontrole: https://www.seasondeals.nl/ toont titel Coming Soon, logo, “Hot offers, cool prices.” en bestaande aankondiging. Homepage niet vervangen.
- /new-website toont de nieuwe hulplink en “De SeasonDeals Club komt binnenkort.”; /dea?id=4&view=inventory-v2 toont de bijgewerkte service/bedrijfs/privacy/cookielinks en cookiekeuze.
- /boeking-bevestiging bereikbaar op eigen domein. Zonder sessie correct Bevestiging niet beschikbaar. Met uitsluitend de bestaande order100-testsessie: bevestigd, betaald EUR241,43, nhow10–12nov,2gasten, voucher/QR en mailstatus sent. Geen nieuwe boeking, betaling, mail of databasewrite. Volledige sessiewaarde niet in Git opgenomen.
- Webflow-publicatie en aangesloten bevestigingscontrole zijn dus afgerond. Branch14 #591 wijst nog naar de eveneens werkende GitHub Pages-bevestiging; omzetting daarvan naar het eigen domein is een afzonderlijke kleine routeringswijziging. Geen productieboekingen vrijgegeven, geen oude pagina verwijderd.


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

**Historische tussenstand11okt (achterhaald door REL-20261012-RECOVERY7-DEPLOY hieronder): SD-12 was gebouwd en getest op branch17. Inmiddels op v1/main/Pages geplaatst en ingelogd gecontroleerd; resterend datapunt97 apart geregistreerd.** Stap4/5 blijven bewezen afgerond.

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


### REL-20261012-RECOVERY7-DEPLOY — publicatie en aangesloten eindcontrole

**Historische tussenstand vóór DOC-20261012-ORDER97-LEGACY:** de vijf geselecteerde backendonderdelen staan op v1; de bijbehorende privé-admin staat op main/GitHub Pages en is ingelogd met de echte v1-aansluiting gecontroleerd. De overzetactie is klaar. SD-12/stap7 wordt nog niet als volledig afgehandeld gemarkeerd: order97 heeft geen betrouwbaar bewezen betaalsessiebinding en mist voucher/mail; order99 blijft bewust manual_attention. Stap4/5 blijven afgerond.

| Onderdeel | Gepubliceerde bron workspace1/branch17 | Werkelijke bestemming workspace1/v1 |
|---|---|---|
| recovery_snapshot | functie710 | functie748 |
| recovery_apply | functie711 | functie749 |
| supplier-checkout-recovery POST | Admin175 endpoint2349 | Admin3 endpoint2471 |
| orders/{order_id}/refund POST | Admin175 endpoint2251 | Admin3 endpoint24 |
| supplier-checkout-incidents GET | Admin175 endpoint2277 | Admin3 endpoint2227 |

- Eerste selectieve merge:12okt09:30 Amsterdam, back-up `v1-fmiKpY`. Uitsluitend bovenstaande vijf; demo2344–2348, partner2312/2314/2315/2316/2317 en middleware uitgesloten.
- In de aangesloten controle bleek een concrete fout: ongeldige evidence bevat geen order_id, waardoor inspect van97 een Xano ERROR_FATAL gaf. Endpoint2349 om09:51 gepubliceerd met één gerichte null-coalescing-correctie in de ordervergelijking; alleen dit endpoint opnieuw naar2471 gemerged om09:55, back-up `v1--oi6V-`. Geen autorisatie-, provider-, sandbox-, evidence- of financiële begrenzing versoepeld. Invalid evidence blijft zonder toegestane acties. Bronbestand `backend/xano/recovery/supplier-checkout-recovery.xs` in dezelfde GitHub-correctie.
- Frontendcheckpoint b48c3310d8cd0f30c0272a7ad7b26327e69b0de2 via PR20 gepubliceerd: main `b63196fe806e13a30bfb3577441e9690176be133`, GitHub Pages-run `38219630962` completed/success (12okt07:47 UTC). Config gebruikt `https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-admin` zonder testbranchoverride.
- Werkelijk ingelogd gecontroleerd op `https://jurgenhassankhan.github.io/seasondeals-partner-portal/admin/checkout-recovery.html`, bereikbaar vanuit Leveranciers → bestaande boeking100 → Status controleren, annuleren of herstellen. Uitsluitend inspect; geen herstel-, annulerings- of refundknop uitgevoerd.
- Order100: Sandbox, CANCELLED_WITH_CHARGES, referentie l0kp_BVEf, betaald EUR241,43, klantrefund EUR0,00, resterend EUR241,43; leverancierskosten EUR205,20 en leveranciersrefund EUR0,00. Bestaande voucher in leveranciersdetail cancelled. Geen nieuwe annulering of klantrefund.
- Order98: Sandbox, NOT_BOOKED, betaald EUR241,43, terugbetaald EUR241,43, pending EUR0,00, resterend EUR0,00. Geen refundknop meer; alleen statusbijwerking beschikbaar. Geen nieuwe terugbetaling.
- Order99: nette blokkade “Geen zekere leveranciersuitkomst. Lege zoekresultaten of time-out zijn geen bewijs dat er nooit geboekt is.” Geen actieknoppen, reset of herboeking.
- Order97: na correctie nette blokkade “Betaalsessie niet betrouwbaar gekoppeld.” Geen financiële actieknoppen. De route controleert exact provider_slug=nuitee, environment=sandbox, de gekoppelde order, Stripe-testmodus, session-ID, EUR-bedrag en order/intent-metadata. De historische lokale status betaald/bevestigd alleen is onvoldoende bewijs om een voucher/mail uit te geven. Xano-database103 alleen-lezen gecontroleerd: intent2 hoort bij order97, provider_slug=nuitee, environment=sandbox, status=booked, holder={}, guests=[], checkout_context=null; record laatst bijgewerkt7okt09:17 Amsterdam. Dit historische record mist dus ook de context/gastgegevens van de nieuwere checkoutketen. De precieze afwijkende Stripe-sessievoorwaarde blijft TE VERIFIËREN; niet blind metadata of betaalstatus aanpassen.
- Andere orderroute81: aangesloten scherm weigert “Exactly one Nuitee sandbox checkout required; other order routes are excluded”. Geen externe transactie.
- Incidentreader2227 via gepubliceerde `admin/checkout-incidents.html`:4 sandboxcheckouts gescand, exact2 aandachtspunten (97 ontbrekende voucher/mail;99 manual_attention/leveranciersfout). Afgehandelde98 en geannuleerde100 niet meer als open incident. Beide herstelkoppelingen aanwezig.
- Lokale tests opnieuw groen:17 evidence-scenario's (de historische console-teller print15 vóór de laatste2), echte reservatielambda's voor concurrency/stale requests, onveranderlijke retry, retrytermijn en refundgrenzen; bestaande partnerrefundbody gelijk; admin-JavaScript syntax geldig. Nieuwe inspectcorrectie bovendien werkelijk op v1 via orders97/99 bewezen. Historische branchtransactietests blijven het bewijs voor daadwerkelijke refund/annulering; geen nieuwe externe transacties voor schermcontrole.
- Resterende concrete opvolging97: oorspronkelijke Stripe-testsessie/order97/intent2 en bestaande Nuitée-reservering onafhankelijk read-only vergelijken; bij bewijs van volledige consistente binding bepalen of de bestaande idempotente finalisatie kan worden gebruikt voor één ontbrekende voucher en afzonderlijk geautoriseerde mail, of het oude testrecord expliciet als historische fixture moet blijven staan. De herstelroute creëert zelf geen vouchers/mails. Geen nieuwe boeking en geen testmail uitsluitend voor schermcontrole.
- Geen datarecords gewijzigd in deze uitrol. Back-ups herstellen uitsluitend logica, geen gedeelde databasegegevens of externe98-refund/100-annulering. Coming Soon, gewone hotelpartnerroute en gesloten productiepoort behouden. Productieboekingen, betalingen en refunds zijn niet vrijgegeven.

**Definitief GitHub-bewijs (12okt):** correctie + beide documenten via PR21 samengevoegd naar main `914ea8e1b38b858760c6a8f6585bd172975b0400`; Pages-run `38221311841` completed/success. Geen frontendcode veranderd na de aangesloten controle. Deze aanvullende registratie wijzigt alleen documentatie.

**Historische browserbeperking (vervangen door DOC-20261012-ORDER97-LEGACY):** browser en Xano-login bleven beschikbaar, maar bij verdere Xano-debugnavigatie/invoer retourneerde de browser `credential_observation_restricted`/`retained_data_restricted`, ook na de gedocumenteerde nieuwe-tab/navigatieherstelroute. Daarom geen onderliggende Stripe-response/metadata opgehaald en geen gegevens gerepareerd op basis van aannames. Dit is geen bewezen fout in de Xano-login. Hervat de read-only sessievergelijking zodra die browserbeperking weg is; publicatie/merge en aangesloten admincontrole zijn hierboven al voltooid en hoeven niet opnieuw.


## DOC-20261012-ORDER97-LEGACY — onderzoek en afbakening SD-12

**Besluit 12 oktober 2026:** Jurgen verduidelijkte dat order97 vóór de nieuwe checkoutconstructie is gemaakt en dat herstel van deze oude testorder niet nodig is. Onderzoek gestopt; order97 blijft een historische sandboxfixture. Ontbrekende voucher/mail bij dit record blokkeren de afsluiting van de huidige stap7-sandboxscope niet. Dit vervangt de eerdere opdracht om97 te herstellen vóór afsluiting. Order99 blijft bewust manual_attention; niet resetten of herboeken.

### Nieuw alleen-lezen bewijs
- Browserbediening daadwerkelijk gecontroleerd via instance, workspace1/v1, tabel103/intent2 en functie748 `supplier/checkout/recovery_snapshot`. In deze sessie geen `credential_observation_restricted` of `retained_data_restricted` bij de uitgevoerde controles. Geen nieuwe login nodig.
- Functie748 met intent2 uitgevoerd: 31 statements/1,74s; geldig afgehandelde blokkade “Betaalsessie niet betrouwbaar gekoppeld.” Debugger uitsluitend gebruikt om dezelfde leesketen te onderzoeken; geen recovery_apply, finalisatie, annulering, refund of webhookreplay uitgevoerd.
- Precieze historische schema-afwijking gevonden: Stripe-sessionmetadata bevat `order_id=97`, `supplier_checkout_intent_id=2`, `supplier_fulfillment=nuitee`; `supplier_order_id` ontbreekt. De huidige evidencecontrole vereist juist die laatste naam. De bestaande Stripe-sessie komt overeen met de orderreferentie; EUR579,49 komt overeen met order en intent.
- Stripe GET bevestigt testmodus, session complete/paid, PaymentIntent succeeded/amount_received57949, gekoppelde charge paid/captured, bedrag57949, currency eur, livemode false, disputed false en amount_refunded0. De volledige refundlijst is vóór het stoppen niet afzonderlijk inhoudelijk uitgelezen; geen claim van complete refundreconciliatie of valid=true.
- Nuitée get_booking bevestigt bestaande sandboxboeking `8yAyZt0BQ`, clientReference `SD-NUITEE-97`, CONFIRMED, The Manhattan at Times Square Hotel,10–12nov2026, EUR474,06 leverancier en EUR5,32 processing. Geen nieuwe reservering gemaakt.
- Historische lokale context is onvolledig: intent2 holder={},guests=[],checkout_context=null; order97 deal_id=0,checkin=0,checkout=0. De stap4-finalizer gebruikt holder.email, checkout_context.request.guest_count en orderdatums voor voucher/mail. Daarom niet blind op deze fixture uitvoeren of alleen Stripe-metadata aanpassen. De reeds geregistreerde ontbrekende voucher/mail is niet gerepareerd; geen nieuwe mail-/vouchertest uitgevoerd.

### Plaatsing, scope en vervolg
- Uitsluitend beide statusdocumenten bijgewerkt op GitHub main. Geen software/configuratie uitgerold, geen datarecord gewijzigd en geen nieuwe transacties/testmails. Geen dataherstel nodig; terugval uitsluitend deze documentatiediff.
- Bronnen: workspace1/v1 functie748 en tabel103/intent2; Git main `backend/xano/recovery/recovery-snapshot.xs`; historische stap4-bron `feat/nuitee-step4-2026-10-11:xano/nuitee-step4-2026-10-11/finalize_sandbox.xs` (blob `8a25ee24136ab843e6f3a12ca852a4f8f19c0bd0`). Bestaand releasebewijs REL-20261012-RECOVERY7-DEPLOY blijft geldig.
- SD-12 huidige sandboxbouw/test en plaatsing zijn afgerond op basis van het al vastgelegde test-/uitrolbewijs. De historische testrecords97/99 blijven voor audit behouden; geen incidentfilter aangepast, dus bestaande waarschuwingen kunnen zichtbaar blijven. Deze administratie is geen datareparatie.
- Geen verder herstel van97 plannen of afgeronde stap4/5/7 opnieuw uitvoeren alleen vanwege deze fixture. Productiescenario’s, productieconfiguratie en publieke go/no-go blijven afzonderlijke open livegangvoorwaarden; Coming Soon en de gesloten productiepoort blijven behouden.


## DOC-20261012-PRODUCTION-ACCESS — SD-10 controle gestart

- Op verzoek van Jurgen productievoorbereiding gestart; stap7 en historische orders97/99 niet heropend.
- Alleen-lezen gecontroleerd: Xano workspace1/v1, Keys & Variables. Zichtbare workspacevariabelen: STRIPE_SECRET_KEY_test, STRIPE_WEBHOOK_SECRET, RESEND_API_KEY, NUITEE_SANDBOX_API_KEY. Geen afzonderlijk benoemde Stripe-live- of Nuitée-productiesleutel in deze lijst. Waarden niet onthuld, gekopieerd of aangepast. De naam STRIPE_WEBHOOK_SECRET bewijst geen live-configuratie; exacte modus/endpointbinding TE VERIFIËREN.
- Nuitée-dashboard verwijst naar connect.nuitee.com en toont aanmelding; Stripe-dashboard toont eveneens aanmelding. Actuele productieautorisatie, Stripe-accountactivatie/uitbetalingen en live-webhooks nog TE VERIFIËREN. Historische Nuitée-productievergrendeling niet als actuele accountcontrole gepresenteerd.
- Beveiligde Nuitée-aanmelding gestart; gebruiker koos Google en verzocht vervolgens zelf in te loggen. Nog geen succesvolle ingelogde accountcontrole vastgelegd. Volgende actie: na gebruikerslogin Nuitée-productiestatus en eventuele ontbrekende vereisten alleen-lezen controleren; daarna Stripe-account en live-configuratie controleren.
- Uitsluitend documentatie op main; geen software/configuratie uitgerold, sleutels gegenereerd, saldo opgewaardeerd, kaarten toegevoegd, orders gewijzigd, transacties of mails uitgevoerd. Coming Soon en publieke productiepoort ongewijzigd. Terugval: alleen deze documentatieaanvulling.


### DOC-20261012-PRODUCTION-ACCESS — Nuitée ingelogd gecontroleerd

- Gewone e-mail/wachtwoordaanmelding via beveiligd inlogvenster geslaagd; zichtbaar ingelogd Nuitée-dashboard en API Keys-pagina gecontroleerd. Geen geheimen in Git of chat vastgelegd.
- Actuele accountblokkade bewezen: Production Key en Production Public Key zijn vergrendeld met “Add a payment method to access your production API key”. Earnings → Settings toont “Business verification required”: eerst bedrijfsgegevens verifiëren, dan een kaart toevoegen en productie ontsluiten. Sandboxkey actief.
- Het geopende verificatieformulier vraagt naam, e-mail, handelsnaam, rol, land, werkende website, exacte juridisch geregistreerde bedrijfsnaam, btw-/registratienummer indien aanwezig en geregistreerd adres. Daarna volgen Closed User Group rates, Commercial model, Verification and payouts, Go live. Het formulier vereist akkoord op Terms of Service. Geen velden ingevuld, voorwaarden geaccepteerd of verificatie ingediend; geen kaart/bank toegevoegd en geen productie geactiveerd.
- De instructie in het formulier waarschuwt dat onjuiste bedrijfsnaam of niet-ladende/geparkeerde website billing en productiesleutel blokkeren. De website is niet in deze sessie op acceptatie door Nuitée beoordeeld; bestaande Coming Soon niet gewijzigd.
- Stripe blijft TE VERIFIËREN: dashboard vroeg login; beveiligde login bood Google/e-mail/Passkey/SSO, gebruiker koos Google. Geen positief ingelogd Stripe-dashboard waargenomen. Browser gaf daarna credential_observation_restricted; expliciete navigatie naar dashboard.stripe.com gaf opnieuw login. Vervolginspectie blokkeerde met retained_data_restricted. Niet als fout wachtwoord of afgekeurd Stripe-account presenteren; geen restrictieomweg toegepast.
- Vervolg SD-10: juridische bedrijfsgegevens en passend commercieel betaalmodel met eigenaar vaststellen; Nuitée-verificatie en Terms alleen met daarvoor vereiste expliciete toestemming, kaart-/bankgegevens via veilige gebruikersinvoer. Stripe-accountactivatie, uitbetalingen, livecredentials en webhookbinding via werkende login nog controleren. De gedeelde Stripe-publishable keys in Nuitée zijn niet automatisch SeasonDeals' eigen Stripe-configuratie.
- Geen sleutelwaarden onthuld/opgeslagen, geen transacties, mails of orderwijzigingen; uitsluitend beide documenten op main bijgewerkt. Geen software/configuratie uitgerold. Stap7-sandbox blijft afgerond, productiepoort gesloten.


## DOC-20261013-PRODUCTION-HANDOFF — SD-10 actuele vervolgstap

- Deze aanvulling vervangt de eerdere onboardingblokkade als actuele werkhypothese. In de vervolggesprekken van12okt deelde Jurgen de Nuitée-mail “Your account is now live”: account ingeschakeld voor productie, productiesleutels beschikbaar. De eerdere dashboardwaarneming met vergrendelde Production Key blijft historisch bewijs van vóór deze melding, niet de actuele conclusie.
- Overgedragen gesprekscontext vermeldt afgeronde onboarding/kaarttoevoeging en overgeslagen bankkoppeling. Dit is een overdracht uit het gesprek, GEEN nieuwe dashboardcontrole op13okt. Het daadwerkelijk gekozen commerciële model en de actuele sleutel/configuratiestatus moeten vóór implementatie worden gecontroleerd; geen aanname over merchant/payment model.
- Jurgen autoriseerde de productieaansluiting grotendeels zelfstandig voor te bereiden. Alleen indien nodig gebruiker betrekken bij beveiligde login, veilig invoeren van geheimen en voorwaarden. Geen echte betaling, boeking of publieke verkoop zonder afzonderlijk expliciet akkoord. Coming Soon blijft de landingspagina; geen wijziging van de normale hotelpartnerroute.
- Stap4/5/7 blijven afgerond binnen hun bewezen sandboxscope. Order97 blijft historische fixture;99 blijft manual_attention. Geen nieuwe herstelactie, reset, boeking of mail voor deze records.
- Eerstvolgende uitvoering SD-10: in ingelogd Nuitée-dashboard productieactivatie en gekozen commercieel model controleren; beschikbare productiesleutel veilig in passende Xano-configuratie opnemen zonder waarden in chat/Git; Stripe-accountactivatie/uitbetalingen, eigen livecredentials en webhookmodus/binding controleren. Daarna afzonderlijke productiegeschikte backendselectie voorbereiden met expliciet gesloten verkoop-/transactiepoort. Niet blind sandboxflags of sleutelnamen vervangen; exacte bron/doel en tests registreren vóór plaatsing.
- Blokkade13okt in DEZE chat: beschikbare hulpmiddelen opnieuw gecontroleerd, geen browserbediening; gerichte connectorzoekactie levert geen Xano-aansluiting. Geen accountdashboard of Xano-configuratie vandaag gecontroleerd of gewijzigd. Een login alleen verhelpt het ontbreken van browserbediening niet. Werkende browsertoegang vereist voor het resterende account-/configuratiewerk; dit is geen uitspraak dat de browser in andere chats ontbreekt.
- Bronnen: actuele main-status en liveganglijst, plus gerichte overdracht uit gesprek “Onderzoek order97 betaalbinding”12okt (productievrijgavemail en vervolgafspraken). Wijziging13okt betreft uitsluitend beide documenten op main; geen software/configuratie uitgerold, geen geheimen verwerkt, geen data-/transactie-/mailmutaties. Terugval uitsluitend deze documentatieaanvulling.


## DOC-20261013-ACCESS-CHECK — actuele dashboardcontrole SD-10

- Browserbediening op13okt in deze sessie beschikbaar; Xano via beveiligde aanmelding en instance → workspace1/v1 daadwerkelijk geopend. Eerdere melding van ontbrekende browserbediening is voor deze sessie achterhaald. Stap4/5/7 en historische97/99 niet heropend.
- Nuitée Connect ingelogd gecontroleerd: API Keys toont een beschikbare Production – Private API Key en actieve Production – Stripe Publishable Key; geen eerdere vergrendeling om eerst een betaalmethode toe te voegen. Hiermee is de door Jurgen gemelde productievrijgave nu ook in het dashboard bevestigd. De gedeelde Stripe-publishable sleutel van Nuitée is niet SeasonDeals' eigen Stripe-secret/configuratie.
- Earnings → Settings toont een aanwezige standaardbetaalkaart en voor uitbetalingen nog “Connect bank account”. Geen kaart- of bankgegevens gewijzigd; geen saldo/opwaardering. Het gekozen commerciële/merchantmodel is in de bekeken schermen niet expliciet vastgesteld en blijft TE VERIFIËREN. Kaartaanwezigheid alleen bewijst dat model niet.
- Xano workspace1/v1 Keys & Variables opnieuw alleen-lezen gecontroleerd: STRIPE_SECRET_KEY_test, STRIPE_WEBHOOK_SECRET, RESEND_API_KEY en NUITEE_SANDBOX_API_KEY aanwezig. Geen afzonderlijk benoemde Stripe-live- of Nuitée-productiesleutel zichtbaar. Geen variabelen gewijzigd; geen productiekey naar Xano overgezet.
- Stripe beveiligde e-mail/wachtwoordaanmelding ingediend, daarna hCaptcha-afbeeldingencontrole op dashboard.stripe.com/login. Nog GEEN positief ingelogd Stripe-accountbewijs; activatie, uitbetalingen, eigen livekeys en webhookbinding blijven TE VERIFIËREN. Menselijke controle via browserovername nodig; geen CAPTCHA omzeild of automatisch opgelost.
- Vervolg: gebruiker voltooit Stripe-controle, daarna accountstatus/livewebhooks alleen-lezen vaststellen. Commercieel model verifiëren vóór productie-implementatie; productiesleutels uitsluitend veilig naar juiste Xano-configuratie en nooit Git/chat. Daarna gesloten productiebackend voorbereiden volgens SD-07–10, zonder echte transacties of publieke vrijgave.
- Uitsluitend documentatie op main bijgewerkt. Geen software/configuratie uitgerold, geen boeking/betaling/refund/mail of datarecordmutatie. Coming Soon en normale hotelpartnerroute ongewijzigd. Terugval uitsluitend deze documentatieaanvulling.


## DOC-20261013-STRIPE-LIVE-READONLY — SD-09/10 account en bestaande webhook gecontroleerd

- Op13okt2026 na gebruikersaanmelding het echte Stripe-dashboard van Seasondeals.nl gecontroleerd. Stripe dashboardcontext bevestigt account `acct_1TkMuaPz36j75L08` en `livemode=true`. Bewijsbron: ingelogd dashboard plus read-only get_dashboard_context.
- Accountstatus `/acct_1TkMuaPz36j75L08/account/status`: geen actieve taken om te voltooien; Betalingen, Payouts en iDEAL-betalingen staan Actief. Cartes Bancaires-betalingen staat Tijdelijk stopgezet. Dit bewijst de getoonde accountcapaciteiten, geen nieuwe betaling of uitbetaling en geen volledige beoordeling van iedere betaalmethode.
- Bestaande actieve livebestemming `we_1TkOkQPz36j75L08Cb1oHit5`, naam SeasonDeals Xano webhook, ingelogd geopend via Workbench. Exacte bestemming: `https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-public/Stripe_Webhook`. Stripe API-versie `2023-10-16`; ontvangt `checkout.session.async_payment_succeeded` en `checkout.session.completed`.
- Webhookoverzicht “Deze week”: totaal0 leveringen, mislukt0. Dat bewijst geen geslaagde actuele end-to-end levering. Signing secret bleef gemaskeerd; niet onthuld, overgenomen of gewijzigd. Geen testevent of replay verzonden.
- SD-10 accountstatus en aanwezigheid/configuratie van deze bestaande livewebhook zijn nu read-only bevestigd. Binding van het signing secret aan Xano `STRIPE_WEBHOOK_SECRET`, actuele signaturevalidatie, eigen Stripe-livecredential en aansluiting op een productiegeschikte Nuitée-orchestratie blijven TE VERIFIËREN. De bestaande partnerwebhook is NIET automatisch de toekomstige Nuitée-productiecallback van SD-09; niet vervangen of aanpassen zonder broncontrole.
- Vervolg: gekozen Nuitée-commercieel/betaalmodel controleren; productiekey veilig in afzonderlijke passende Xano-configuratie voorbereiden; daarna SD-07–10 productiegeschikte routes met gesloten transactie-/verkooppoort selecteren. Xano-doel workspace1/v1; exacte nieuwe variabelen en route-ID's TE VERIFIËREN vóór wijziging.
- Bestemming van deze registratie: uitsluitend `SEASONDEALS_STATUS.md` en `SEASONDEALS_LIVEGANG.md` op GitHub main. Geen Stripe/Xano/softwareconfiguratie uitgerold, geen sleutels verwerkt, geen datawijziging, echte of testtransactie, boeking, refund of mail uitgevoerd. Coming Soon en hotelpartnerroute behouden; stap4/5/7 blijven afgerond,97 historisch,99 manual_attention. Terugval uitsluitend deze documentatieaanvulling.


## REL-20261013-ACC-PREP — SD-09/10 afzonderlijke productieconfiguratie

### Besluit en broncontrole
- Jurgen heeft op13okt expliciet bevestigd: “wij hanteren gewoon de acc model in nuitee”. ACC / Account Credit Card is daarmee de eigenaarbevestigde projectkeuze; niet opnieuw als onbeslist presenteren. De eerder bekeken dashboardkaart benoemde het model niet expliciet: eigenaarbevestiging is geen dashboardbewijs van het commerciële model.
- GitHub main bij start én vóór deze registratie vergeleken met `213253f655d1326988ff7061656a4e458fb36c62`: identical,0 nieuwe commits. AGENTS, status, liveganglijst en werkprotocol gelezen.
- Broncontrole Xano workspace1/v1: Public API7 POST70 `Stripe_Webhook`, exact de bestemming van Stripe-livewebhook `we_1TkOkQPz36j75L08Cb1oHit5`. De volledige editorbron gelezen, geen uitvoering/replay: verwerkt uitsluitend `checkout.session.completed` met inputstatus paid/no_payment_required; geen signaturecontrole, Stripe-eventlookup of livemodecontrole in deze endpointbody. Het geconfigureerde Stripe-event `checkout.session.async_payment_succeeded` wordt door deze conditie niet verwerkt.
- Middlewareoverzicht v1 toont geen middleware. `STRIPE_WEBHOOK_SECRET` verwijst volgens de UI naar functie7 `security/verify_stripe_signature`; endpoint70 roept die functie niet aan. Inhoud van functie7 en overeenkomst van de secretwaarde met de bestaande livewebhook zijn nog TE VERIFIËREN. Dit is een concrete open productievoorwaarde, geen claim van getest misbruik. Bestaande partnerwebhook, secret en partnerlogica niet gewijzigd.
- Actuele v1-adapter-ID's uit functielijst: list_hotels124, search_rates125, prebook126, create_booking127, get_booking128, cancel_booking129, upsert_supplier_booking131. Volledige bron127 gelezen: `ACC_CREDIT_CARD`, `$env.NUITEE_SANDBOX_API_KEY`, POST `https://book.liteapi.travel/v3.0/rates/book?timeout=30`. Deze bestaande sandboxadapter is niet omgezet of uitgevoerd.

### Werkelijk geplaatst en gecontroleerd
- Nuitée Connect Production/API Keys opnieuw ingelogd gecontroleerd. Bestaande Production Private API Key actief. Na beveiligde e-mailverificatie veilig overgenomen naar NIEUWE Xano-workspacevariabele `NUITEE_PRODUCTION_API_KEY`; savebevestiging en afgeschermde variabelenlijst gecontroleerd. Geen key gegenereerd/geroteerd. Waarde niet in Git of broncode opgeslagen.
- NIEUWE afzonderlijke workspacevariabele `NUITEE_PRODUCTION_CONFIG` opgeslagen met schema_version1,environment=production,payment_method=ACC_CREDIT_CARD en read_enabled/transactions_enabled/sales_enabled/refunds_enabled/email_enabled allemaal false. Exacte niet-geheime configuratie: `backend/xano/production/config.closed.json`.
- Nieuwe alleen-lezen functie `supplier/production/config_status` #788 geplaatst op workspace1/v1. Functielijst bevestigt Created én Published13okt15:29 Amsterdam; nul drafts. Bron: `backend/xano/production/config-status.xs`. Geen API-route, taak of bestaande functie op deze controle aangesloten; functie doet geen externe requests, databasewrites of verzendingen.
- Werkelijke Xano-run #788: success,120ms; config_valid=true,configured_closed=true,release_status=preparation_only,production_released=false; can_read/can_book/can_pay/can_refund/can_send_email/can_sell allemaal false,reason=PRODUCTION_NOT_RELEASED.
- #788 is een configuratiecontrole, GEEN reeds aangesloten productieorchestratie of zelfstandig afdwingende transactiegateway. De bestaande publieke supplierblokkades zijn ongemoeid gelaten. Geen productieaanvraag aan Nuitée uitgevoerd; opslag van de key is bewezen, externe geldigheid en productieboekingsflow nog niet.
- Bestaande variabelen STRIPE_SECRET_KEY_test,STRIPE_WEBHOOK_SECRET,RESEND_API_KEY,NUITEE_SANDBOX_API_KEY behouden. Geen sandboxflags vervangen. Workspacevariabelen gelden over branches; de nieuwe productiesleutel wordt nog door geen boekingsroute gebruikt.

### Stripe-vervolg en resterende overzetlijst
- Bestaande Stripe-livekeys bekeken op account `acct_1TkMuaPz36j75L08`: standaardkey “Xano” van7jul aanwezig maar gemaskeerd, geen optie om de waarde opnieuw te tonen. Niet omgewisseld, ingetrokken of gewijzigd.
- Een alleen-lezen livekey was uitsluitend als formulier voorbereid; `Sleutel maken` NIET uitgevoerd. Deze voorbereiding is niet de gekozen productiecredential: Jurgen vraagt om een sleutel voor de volledige benodigde productieaansluiting. Geen nieuwe Stripe-key aangemaakt.
- Eerst de benodigde Stripe-API-acties uit de actuele betaalroutes vaststellen en daarop passende liverechten bepalen. Een alleen-lezen key volstaat niet voor het aanmaken van betalingen. Nieuwe toegang pas na expliciet akkoord; productieactivering blijft afzonderlijk gesloten. Er is nog geen nieuwe Stripe-livecredential in Xano opgeslagen.
- SD-07/08/09: volledige actuele gepubliceerde stap4-bronselectie en productiegeschikte betaal/boek/mail/callbackroutes blijven TE VERIFIËREN/TE BOUWEN; geen nieuwe endpoint-ID's verzonnen en geen sandboxfuncties blind overgezet. Dedicated Nuitée-livecallback met geverifieerde event-/order-/betaalbinding en expliciete transactiepoort nog vereist. Partnerendpoint70 niet automatisch hergebruiken.
- SD-10: Nuitée-productiecredential afzonderlijk geplaatst; productieauthenticatie zonder transactie nog te controleren. Stripe-livecredential, webhooksecretbinding en afzender/productiekosten nog open. SD-11 productie-import en SD-13 publieke verkoopvrijgave blijven afzonderlijk open.
- Coming Soon blijft landingspagina; gewone hotelpartnerroute behouden. Geen echte of testboeking, betaling, refund, klant-/testmail, ordermutatie of publieke vrijgave. Stap4/5/7 blijven afgerond binnen hun bewezen sandboxscope;97 historisch,99 manual_attention.
- Terugval: uitsluitend nieuwe ongebruikte configuratie/controlefunctie gericht buiten gebruik houden of na afhankelijkheidscontrole verwijderen; bestaande variabelen en routes niet terugzetten. Geen gegevensherstel nodig; geen recordmutaties of externe transacties uitgevoerd. Git-terugval is alleen de nieuwe bron/documentatiediff, geen volledige branchrollback.


## DOC-20261013-STRIPE-LIVE-KEY — SD-10 productiecredential geplaatst

- Jurgen heeft expliciet toestemming gegeven om een standaard Stripe-live-secret key met volledige API-toegang aan te maken en veilig in Xano op te slaan. De eerder voorgestelde alleen-lezen-tussenoplossing is vervallen; daarvan is geen sleutel aangemaakt.
- Bron: Stripe-account `acct_1TkMuaPz36j75L08`, Seasondeals.nl, Standaardsleutels. Nieuwe sleutel met naam `SeasonDeals Xano productie 2026-10-13` aangemaakt na accountverificatie. Stripe toonde de nieuwe API-sleutel met liveprefix; na opslag is de sleutel afgeschermd en staat de genoemde naam in de standaardkeylijst met aanmaakdatum 13 oktober.
- Bestemming: Xano instance `xgrq-dkge-tace.n7e.xano.io`, workspace1, gecontroleerd op branch v1. NIEUWE workspacevariabele `STRIPE_SECRET_KEY_live` opgeslagen. Xano bevestigde `The environment variable has been saved`; de variabele daarna als afgeschermde waarde in Environment Variables aanwezig. De keywaarde staat niet in Git of broncode.
- Bestaande `STRIPE_SECRET_KEY_test`, bestaande Stripe-keys, `STRIPE_WEBHOOK_SECRET` en partnerwebhook behouden. Geen bestaande sleutel geroteerd of ingetrokken. Workspacevariabelen gelden over branches.
- Dit bewijst aanmaak en opslag, niet een werkende productie-betaalketen. Geen Stripe-API-request met de nieuwe sleutel uitgevoerd en geen bestaande betaal-/refundroute omgezet. Geen betaling, refund, boeking, mail of ordermutatie uitgevoerd. Coming Soon en gesloten verkoop blijven behouden.
- Resterend SD-10: veilige productie-authenticatiecontrole, webhooksecretbinding/signaturevalidatie en afzonderlijke productie-betaal-/boekingsroutes aansluiten en controleren. De eerdere constatering dat nog geen nieuwe Stripe-livecredential was opgeslagen is hiermee achterhaald; de open webhook- en vrijgavevoorwaarden blijven gelden.


## REL-20261013-PRODUCTION-CONNECTIONS — SD-07/09/10 controle en gesloten callback

- Bron vóór wijziging: GitHub main `7076409bf9af3be674783fbb7211a8b60e7a8a05`. Nieuwe eigen code, geen volledige sandboxmerge. Bestemming Xano instance `xgrq-dkge-tace.n7e.xano.io`, workspace1, branch v1.
- Nieuwe interne functie789 `supplier/production/verify_connections`: alleen GET naar Stripe account `acct_1TkMuaPz36j75L08`, Stripe balance en Nuitée `https://api.liteapi.travel/v3.0/data/currencies`. Credentials uitsluitend uit afzonderlijke productievariabelen. Xano-run success1,06s: beide Stripe-requests HTTP200, account_matches/livemode/charges_enabled/payouts_enabled=true; Nuitée HTTP200 met data-array. Dit bewijst authenticatie. Het currencies-endpoint bewijst geen productieboekingsmodus; daarvoor blijft de oorsprong van de key in het Production-dashboard het bewijs. Geen saldo of persoonsgegevens geëxporteerd.
- Nieuwe interne functie790 `supplier/production/verify_stripe_signature` op v1 gepubliceerd. HMAC-SHA256 op exacte raw body, tijdvenster300s, begrensde/strikte headerparser en vergelijking over alle64 hextekens. Secret alleen als serverinput voor interne aanroep. Onafhankelijk Python-HMAC-fixture met fictieve secret geaccepteerd: verified=true,60ms. Hetzelfde fixture met gewijzigde body geweigerd: ERROR_CODE_ACCESS_DENIED,20ms. Dit bewijst de helper; nog geen bewijs van een echt Stripe-webhookbericht op de nieuwe route.
- Bestaande v1-functie7 `security/verify_stripe_signature` alleen-lezen geïnspecteerd: placeholder, controleert aanwezigheid secret maar retourneert verified=true zonder cryptografische validatie. Geen callers getoond. Partnerendpoint70 roept deze helper niet aan; bestaande partnerroute/webhook/secret ongewijzigd. Dit productiebeveiligingspunt blijft open, zonder de bewezen sandboxscope te heropenen.
- Nieuwe afzonderlijke Public API7 POST2594 `webhooks/nuitee-production` op v1 geplaatst en gesloten gepubliceerd. Bron `backend/xano/production/webhooks-nuitee-production.xs`. Eerste actie controleert config_status788 en weigert zolang can_book/can_pay/can_sell niet alle true zijn; deze rechten zijn hardcoded false. Geen writes, betaling, boeking of mail in deze endpointbron. Een tweede onvoorwaardelijke stop voorkomt fulfillment ook na toekomstige poortaanpassing.
- Callback-headerbinding gecorrigeerd naar Xano-systeemvariabele `$env.$http_headers`; raw-input-instellingen afzonderlijk gezet. De eerdere runnerfout Missing var entry:http_headers is geen succesvolle webhooktest. Productiecallback is voorbereiding, geen complete order-/betaalbinding of fulfillment. Dedicated `NUITEE_STRIPE_WEBHOOK_SECRET` is nog niet geplaatst; geen nieuwe Stripe-livebestemming geregistreerd en geen bestaande bestemming vervangen.
- Bronbestanden voor789/790/2594 opgenomen onder `backend/xano/production/`. Functie789 aangemaakt/gebruikt op v1; afzonderlijke publicatiedatum nog TE VERIFIËREN. Functie790 publicatiebevestiging gezien;2594 na gerichte publicatie nul drafts in de UI. Geen sandboxfuncties, historische testhulpen, taken, middleware of bestaande partnercode meegeselecteerd.
- Open SD-07/08/09: productiegeschikte checkout/verse beschikbaarheid, exacte order- en betaalbinding, idempotente ACC-fulfillment, werkelijke kosten, voucher en mailpoort; callbacksecret/Stripe-registratie en echte transportcontrole. Huidige code opent geen verkoop. SD-11 import en SD-13 publieke vrijgave blijven afzonderlijk open. De volledige betaal-naar-boekingketen is NIET productiebewezen.
- Geen boeking, betaling, refund, mail, databasewrite of publieke vrijgave uitgevoerd. Coming Soon behouden; stappen4/5/7 niet heropend;97 historisch en99 manual_attention onaangeraakt. Terugval: uitsluitend nieuwe ongebruikte789/790/2594 na afhankelijkheidscontrole buiten gebruik houden; bestaande routes/keys behouden. Xano-branches delen database live; geen dataherstel nodig voor deze controle.

- Werkelijke runnercontrole van gepubliceerde callback2594:100ms,6 statements inclusief configuratiehelper; ERROR_CODE_ACCESS_DENIED / PRODUCTION_NOT_RELEASED bij de eerste poort, vóór raw body, secretgebruik, externe requests en mutaties. Dit is bewijs van de gesloten poort, geen geslaagde webhooklevering.


## REL-20261013-PRODUCTION-CHAIN — SD-07/08/09 code geplaatst, vrijgave gesloten

### Selectie, bron en bestemming
- Op expliciet verzoek de productievariant van de betaal-, boekings-, voucher- en mailketen uitgewerkt en aangesloten. Bronbasis: GitHub stap4 `ab6fedc513ba2ddbd89ef0e5acbe8b1e76a8f50a` (verify/claim/prepare/fulfill, actuele finalize en goedgekeurde renderer), plus main `c92df16058bf940cc4155f162ff023cb6d213bda` (availability-policy en stap6-checkout met eigen return-URL). v1-adapter125/128 en opslagfunctie131 alleen-lezen geïnspecteerd voor bestemmingen/velden. Geen bestaande sandboxfunctie omgezet.
- Bestemming: workspace1/v1, afzonderlijke namespace `supplier/production`. Werkelijke functielijst bevestigt Created én Published op13okt2026: verify_payment791 (16:58), claim_payment792/availability793/prepare794 (17:00), fulfill_payment795/render_confirmation796/finalize797 (17:01), create_session798 (17:02), tijden Amsterdam. Nul drafts bij controle. Eerdere verify_connections789 is hiermee ook als Published16:15 bevestigd.
- Alle acht actuele editorbronnen rechtstreeks teruggeëxporteerd onder `backend/xano/production/`: verify-payment.xs, claim-payment.xs, availability.xs, prepare.xs, fulfill-payment.xs, render-confirmation.xs, finalize.xs, create-session.xs. Callback2594 eveneens geëxporteerd naar webhooks-nuitee-production.xs.
- Public API7 POST2594 gericht gepubliceerd: exacte met Xano Copy Endpoint verkregen bestemming `https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-public/webhooks/nuitee-production`. Roept795 aan en bij voucher_allowed797;797 roept796 aan. Bestaande partnerendpoint70, partnerwebhook en variabelen ongemoeid. Geen frontend-, Webflow-, admin-, taak- of middlewarewijziging.

### Wat de nieuwe code doet
-791 verifieert serverzijdig Stripe-live Session, PaymentIntent en charge, exact EUR-bedrag, betaald/completed/succeeded, niet terugbetaald/betwist, order/customer/deal/contextbinding en eigen metadata `nuitee_production_v1`.792 claimt pending_payment één keer onder intent-recordlock; booking_attempts gaat alleen van0 naar1.
-793/794 controleren uitsluitend goedgekeurde production supplier_deals: data, bezetting, ongewijzigde kamer/annulering/lokale kosten, vaste verkoopprijs en minimummarge. Aparte productiesleutel voor rates/prebook. ACC_CREDIT_CARD moet in prebook.paymentTypes staan. Geen sandboxkostenminimum1,30 overgenomen: pricing_config moet production_costs_verified=true,payment_method=ACC_CREDIT_CARD,cost_evidence en geldige reserves bevatten. Deze productie-deal/kostenconfiguratie is nog niet geïmporteerd of bevestigd.
-795 claimt de geverifieerde betaling, doet verse prijs/voorwaardencontrole en precies één ACC-book-aanvraag met stabiele clientReference. Onzekere HTTP-uitkomst of ontbrekende bevestiging wordt manual_attention; geen automatisch opnieuw boeken. Bevestiging moet onder andere sandbox=0, eigen clientReference en EUR tonen. Genormaliseerde supplier_bookings plus order/intent onder transactie opgeslagen. Geen terugval naar sandboxcredentials.
-797 haalt de echte bevestigde leveranciersboeking opnieuw op en controleert boekingsreferentie, verblijfsdata, sandbox=0 en werkelijke leverancier-/Stripekosten. Payment en voucher worden onder intent-lock hergebruikt/aangemaakt met bindingscontrole. Bestaande template/logo behouden in796; uitsluitend bevestigde production booking toegestaan. Bevestigingsmail gebruikt opgeslagen houderadres, onveranderlijke inhoud en productie-idempotencysleutel; sent-status blokkeert opnieuw verzenden; onzekere herhaling na23uur vereist reconciliatie. Verzenden blijft afhankelijk van can_send_email=false.
-798 is een INTERNE functie, geen publiek checkoutendpoint: unieke request/customer-snapshot, lock, vaste productiesleutel/metadata en Stripe-idempotencysleutel; nieuwe sessieherhaling na23uur geblokkeerd. Eigen bestaande bevestigingspagina als returnbestemming; de publieke bevestigingsreader/frontendaansluiting is hiermee NIET als productiebewezen aangemerkt.
-2594 bewaart de gesloten entry gate, daarna raw-body signaturehelper790 en autoritatieve Stripe-eventlookup; alleen eigen live paid checkout-events met positieve intent/order-ID's. DB-binding controleert production/provider/order/session voordat795 wordt aangeroepen. De vorige onvoorwaardelijke eindstop is vervangen door deze echte functieverbinding; config_status788 blijft alle rechten hardcoded false teruggeven.

### Werkelijk getest en grenzen van het bewijs
- Gepubliceerde2594 opnieuw in Xano-runner:6 statements20ms, ERROR_CODE_ACCESS_DENIED / PRODUCTION_NOT_RELEASED. Rechtstreekse795:20ms;797:20ms;798 met fictieve input en ID0:70ms; alle stoppen op dezelfde entry gate vóór DB-/provideracties. Geen bestaand klant-, deal- of orderrecord nodig voor deze tests.
- `policy.test.cjs` draait12 assertions op de uit Xano geëxporteerde JS-policy/renderer: geldig fictief productietarief, weigering sandboxdeal/onbevestigde kosten/verkeerde bezetting, gewijzigde lokale kosten, onvoldoende marge, onbeschikbaar ACC, veilige HTML-escaping en geen sandboxbevestiging als production. Alle slagen. Geen netwerk of databasegebruik. Dit is policybewijs, geen volledige Xano-/Stripe-/Nuitée end-to-end productieproef.
- Eerder bewezen sandboxconcurrentie blijft bewijs voor de oude sandboxscope. Productieconcurrentie, echte betaling/boeking/voucher/mail, daadwerkelijke live-webhooklevering en actuele production room/fee-responses zijn NIET uitgevoerd/bewezen. Geen nieuwe testboeking of testmail.

### Nog noodzakelijke aansluiting en vrijgave
- Dedicated Stripe-livebestemming voor2594 nog NIET geregistreerd. Afzonderlijke `NUITEE_STRIPE_WEBHOOK_SECRET` ontbreekt nog; echte raw-header/signaturetransportcontrole staat daardoor open. Deze ontbrekende variabele is een bekende onafgeronde afhankelijkheid, geen afgeronde livewebhookaansluiting.
- SD-07/08/09 backendcode is nu geplaatst en intern verbonden; veilige entry-gate en beperkte fixturetests bewezen. Niet aanduiden als volledige productieaansluiting afgerond. Open: aparte Stripe-bestemming/secret/transport, productie-dealimport en kostenbewijs, klantautorisatie voor publiek checkoutendpoint, bevestigingsreader/frontend en productieherstelbediening. SD-11 en SD-13 blijven open.
- Vrijgave blijft gesloten: read/transactions/sales/refunds/email=false; Coming Soon blijft. Geen sleutelrotatie, echte of testbetaling, boeking, refund, mail of DB-recordwijziging uitgevoerd.97 en99 niet gelezen/gewijzigd, stappen4/5/7 niet heropend.
- Terugval: herstel alleen callback2594 naar de vorige gesloten versie uit `c92df16058bf940cc4155f162ff023cb6d213bda`; nieuwe791–798 achter gesloten788 houden en alleen na afhankelijkheidscontrole verwijderen. Bestaande routes/credentials behouden. Geen dataherstel vereist voor deze plaatsing; branches delen live data.


## DOC-20261013-WEBHOOK-PREP — aparte Stripe-bestemming klaar voor registratie

- Bron: Stripe-account `acct_1TkMuaPz36j75L08`, Workbench-formulier; gecontroleerde GitHub-main `f209deb2c34cdef44f0baaf66c6f793d577a031d`.
- Voorbereid, NIET opgeslagen: bestemming `SeasonDeals Nuitee productie`, eigen account, snapshotpayload, API-versie `2023-10-16`, uitsluitend `checkout.session.completed` en `checkout.session.async_payment_succeeded`.
- Exacte bestemming: `https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-public/webhooks/nuitee-production` (bestaande nieuwe callback2594 op workspace1/v1). Formulier ingevuld; `Bestemming maken` nog niet uitgevoerd. Er is dus nog geen nieuw webhook-ID of signing secret.
- Volgende stap: registratie en veilige opslag van het bijbehorende secret als afzonderlijke Xano-variabele `NUITEE_STRIPE_WEBHOOK_SECRET`, gevolgd door transportcontrole. Deze stappen zijn nog niet bewezen of vrijgegeven. Bestaande partnerwebhook/secret behouden. Productiepoorten blijven gesloten; geen transactie, boeking, mail of databasewijziging.


## REL-20261013-WEBHOOK-REGISTERED — Stripe-bestemming aangemaakt; binding nog onbevestigd

- Bron: Stripe-account `acct_1TkMuaPz36j75L08`; eigenaar gaf expliciet akkoord voor registratie en veilige opslag van het afzonderlijke signing secret in Xano.
- Aangemaakt: `we_1UQ8G9Pz36j75L08Zvmc0rFW`, naam `SeasonDeals Nuitee productie`, eigen account, API `2023-10-16`, snapshotpayload, uitsluitend `checkout.session.completed` en `checkout.session.async_payment_succeeded`.
- Exacte bestemming: `https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-public/webhooks/nuitee-production`, callback2594, workspace1/v1. Bestaande partnerwebhook `we_1TkOkQPz36j75L08Cb1oHit5` niet aangepast.
- Signing secret veilig uit de nieuwe Stripe-bestemming overgenomen voor opslag als `NUITEE_STRIPE_WEBHOOK_SECRET`. Opslag is NIET bevestigd; niet als geplaatst of werkend registreren. Geen secretwaarde in broncode of Git. Volgende stap is eerst de actuele Xano-variabelenlijst controleren om dubbele aanmaak te voorkomen, daarna zo nodig uitsluitend deze nieuwe variabele opslaan en callbackbinding/transport testen.
- Geen geslaagde webhooklevering, echte signaturetransportcontrole of productie-end-to-end bewijs. Config_status788 en bestaande gepubliceerde callbackcode ongewijzigd; boekingen/betalingen/verkoop/refunds/mail blijven gesloten. Geen echte of testtransactie, mail of ordermutatie. Afgeronde sandboxstappen en orders97/99 ongemoeid.

- Laatste Stripe-controle: nieuwe bestemming Actief, nul leveringen. Kort uitgeschakeld tijdens onafgeronde aansluiting, daarna op expliciet verzoek van Jurgen weer ingeschakeld en Actief geverifieerd. Dit is alleen aflevering van Stripe-meldingen; geen vrijgave van transacties of openbare verkoop.


## REL-20261015-WEBHOOK-BINDING — SD-09/10 secret geplaatst; transport nog open

- Bron vóór wijziging: GitHub main `07bde786e97fc2c3192f68f733e6577ec0d224a3`; actuele vier projectdocumenten gelezen, geen nieuwere main aangetroffen. Stripe-account `acct_1TkMuaPz36j75L08`, bestaande nieuwe webhook `we_1UQ8G9Pz36j75L08Zvmc0rFW` (SeasonDeals Nuitee productie).
- Bestemming: Xano instance `xgrq-dkge-tace.n7e.xano.io`, workspace1/v1, nieuwe afzonderlijke variabele `NUITEE_STRIPE_WEBHOOK_SECRET`. Vooraf afwezig vastgesteld; het bestaande signing secret van uitsluitend deze webhook opgeslagen. Na herladen aanwezig; Xano Referenced By toont precies Public API7 POST2594 `/webhooks/nuitee-production`. Opslag en codeverwijzing nu bevestigd; de eerdere onbevestigde opslagstatus is achterhaald. Geen secretwaarde in Git of broncode.
- Stripe-bestemming opnieuw Actief gezien, URL exact `https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-public/webhooks/nuitee-production`, API2023-10-16, twee events, deze week nul leveringen. Geen webhook gewijzigd, vervangen of uitgeschakeld; partnerwebhook en partnersecret behouden.
- Gerichte codecorrectie in2594: Get All Raw Input encoding van `"text"` naar de door de Xano-configuratie aangeboden `"none"`; exclude_middleware=true behouden. Alleen dit endpoint gericht gepubliceerd, nul drafts bevestigd. Actuele editorbron teruggeëxporteerd naar `backend/xano/production/webhooks-nuitee-production.xs`; vergelijking bevestigt uitsluitend deze encodingwijziging. Alle gates en overige code gelijk aan de vorige versie.
- Controle gepubliceerd endpoint zonder input:6 statements,80ms, ERROR_CODE_ACCESS_DENIED / PRODUCTION_NOT_RELEASED bij eerste precondition. Geen database-/Stripe-/Nuitée-/Resend-actie bereikt. Dit bewijst de gesloten poort, NIET de raw-body/signatureverwerking. De XanoScript-editor bleef een enum-parsermelding bij encoding tonen, ook bij de aangeboden none-waarde; runtimecontrole van deze stap is daarom nog TE VERIFIËREN. Niet als volledig herstelde of werkende transportketen aanmerken.
- Volgende technische controle: geïsoleerd raw-body/headertransport en signaturevalidatie bewijzen zonder transactiepoort te openen; daarna productiecheckoutautorisatie, bevestigingsreader/frontendaansluiting, productieaanbod/kostenbewijs en productieherstelbediening. Een echte end-to-end betaling/boeking/voucher/mail is niet uitgevoerd of bewezen.
- ACC blijft eigenaarbevestiging; dashboardbewijs en key-authenticatie zijn afzonderlijke bewijzen. Productievrijgave blijft gesloten, Coming Soon behouden. Geen betaling, boeking, refund, mail of bedrijfsrecordmutatie. Stappen4/5/7 niet heropend; orders97/99 niet gelezen of gewijzigd.
- Terugval: alleen2594 herstellen uit de genoemde broncommit indien nodig, gesloten config_status788 behouden; de nieuwe variabele niet blind verwijderen en de bestaande partnerconfiguratie niet aanraken. Geen dataherstel vereist; Xano-branches delen live data. Deze registratie betreft configuratieplaatsing plus gerichte codepublicatie, geen publieke productievrijgave.


## REL-20261015-TRANSPORT-CONFIRMATION — SD-09/13 berichtcontrole bewezen en productiereader geplaatst

- Bron: main `72c36d8a81755ad96a098bb2bb8a10b8f5800179`; vier projectdocumenten opnieuw gelezen. Bestemming Xano workspace1/v1, bestaande Public API7 callback2594 en nieuwe bevestigingsreader2595. Geen branchmerge, sandboxroutes of partnerroute gewijzigd.
-2594: raw body encoding="none", unieke Stripe-Signature en helper790 nu vóór de gesloten productiepoort. Ontbrekende/lege/ambigue header expliciet geweigerd. Dezelfde can_book/can_pay/can_sell-poort blijft vóór Stripe-eventlookup, database en fulfillment staan; tweede poort behouden. Alleen2594 gericht gepubliceerd, nul drafts; actuele editorbron in backend/xano/production/webhooks-nuitee-production.xs. De eerdere enum-parsermelding niet meer zichtbaar na opnieuw openen; raw-bodyruntime nu daadwerkelijk bewezen.
- Nieuwe interne diagnostiek799 `supplier/diagnostics/verify_production_webhook_transport`, Request History Disabled gezien. Geen publieke aanroepers of productieflowaansluiting; vaste bestemming2594, alleen synthetische event-ID zonder order/customer, vooraf configured_closed en drie gesloten transactierechten vereist. Bron apart onder backend/xano/diagnostics/; niet meeselecteren als productiebedrijfslogica.
- Werkelijke HTTP-proef via de gepubliceerde URL met de opgeslagen dedicated secret:14 statements,1,16s, passed=true. Geldige ondertekening →403 PRODUCTION_NOT_RELEASED; één extra spatie in body, ontbrekende handtekening en600seconden oude handtekening →alle403 Invalid webhook signature. Eerste proef had de ontbrekende header nog als400 Missing param afgewezen; expliciete precondition toegevoegd en dezelfde vier gevallen daarna geslaagd. Geen Stripe- of Nuitée-transactie, databasewrite of mail. Dit bewijst synthetisch HTTP-transport/raw-body/header/secret/HMAC/tijdvenster; geen echte Stripe-eventlevering of end-to-end boeking.
- Nieuwe Public API7 POST2595 `supplier/production/confirmation-status` direct opv1 geplaatst. Exact via Copy Endpoint: `https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-public/supplier/production/confirmation-status`. Alleen-lezen, gate can_read vóór database, uitsluitend cs_live-capability maximaal24uur, production/Nuitée/order/customer/session/contextbinding; alleen confirmed sandbox=0 toont boeking, alleen actieve overeenkomstige voucher toont code. Geen gastmail/PaymentIntent in response. Bron teruggeëxporteerd naar backend/xano/production/confirmation-status.xs.
-2595 met fictieve cs_live-input uitgevoerd:6 statements20ms,403 PRODUCTION_NOT_RELEASED vóór records. Lokale tests op de daadwerkelijke export: geldige fixture, sandbox/wrong customer/session/order/flow/onbetaald/verwerkt/nulbooking geweigerd; annulering/vervallen voucher, linkverval, privacy en HTML-escaping bewezen. Geen bestaand orderrecord voor deze tests gebruikt.
- Frontend: aparte confirmation-production-view.js plus confirmation-router.js. Bestaande sandboxrenderer/reader behouden. Expliciete vaste endpointkeuze per cs_test/cs_live; responseomgeving moet overeenkomen, aparte sessionStorage, capability uit URL, no-referrer/no-store, sandboxbanner alleen bij tests. tests/confirmation-router.test.cjs en production-confirmation.test.cjs slagen; geen echte sessie gebruikt.
- Webflow site `68cb0d808ea4f2467bb313af`, pagina `6acbead36631ab0d5cf3b9fd` (/boeking-bevestiging), HtmlEmbed `b883ba38-59f9-74c3-6cdf-556cc786337a`: gecombineerde code opgeslagen en teruggelezen exact gelijk. Bron public-preview/webflow/confirmation-combined-embed.html; vorige embed in main72c36d8/public-preview/webflow/confirmation-embed.html. Op registratiemoment alleen staging; publicatie en livecontrole nog TE VERIFIËREN. Coming Soon-root niet gewijzigd.
- Nog open: echte Stripelevering, publieke checkout met klantautorisatie, productieaanbod/import en onderbouwde ACC-kosten, productieherstelbediening en volledige betaling/boeking/voucher/mail-proef. Geen publieke verkoopvrijgave; config_status788 ongewijzigd hardcoded gesloten. ACC blijft eigenaarbevestiging; geen betaalinstelling gewijzigd.97/99 niet gelezen/gewijzigd, stappen4/5/7 niet heropend.
- Terugval:2594 naar72c36d8-export,2595 achter gesloten gate houden; Webflow-embed terug naar vorige versie indien nodig.799 losstaande diagnostiek zonder bedrijfsaanroepers. Geen bedrijfsdata gewijzigd; gedeelde live database behoeft voor deze plaatsing geen dataherstel. Voorbereiding/plaatsing is geen productievrijgave.


## REL-20261015-CUSTOMER-CHECKOUT — SD-09/13 geauthenticeerde ingang geplaatst, publicatiepagina nog open

- Bron: main `5d444a30264fcc48b764cbf93efb2aa78b670b53` plus gelezen bestaande Customer API4 auth/me30: auth="customers", identiteit $auth.id. Bestemming: Xano workspace1/v1 Customer API4 nieuwe POST2596 `supplier/production/checkout`.
- Exacte URL via Copy Endpoint: `https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-customer/supplier/production/checkout`. Bron teruggelezen uit de editor en opgenomen als backend/xano/production/customer-checkout.xs. Nul drafts en Authentication Required zichtbaar na plaatsing.
- Zeven invoervelden voor deal/datums/gezelschap/request_key/holder/guests; geen klantnummer of prijs als invoer. customer_id wordt uitsluitend uit $auth.id aan bestaande functie798 doorgegeven. Eerst config_status788 en can_pay/can_book/can_sell, daarna pas klantlookup en create_session. De bestaande hardcoded gesloten poort blijft ongewijzigd.
- Controlegrens: editorbron en private/auth-instelling gecontroleerd. Run-paneel weigert een lege Auth Token met “This field is required”; daardoor geen runtime-aanroep uitgevoerd. Geen klanttoken gegenereerd en geen klanten/orderecords voor deze controle gelezen. Een succesvolle ingelogde checkout en externe HTTP-authafwijzing zijn hiermee NIET bewezen.
- GitHub Pages-uitrol van5d444a, workflow38695731102: completed/success. De gecombineerde bevestigingscode staat dus op de assetbron. Webflow-embed blijft alleen opgeslagen in staging: volledige sitepublicatie is door automatische goedkeuringscontrole geweigerd wegens mogelijk meepubliceren van andere wijzigingen; de beperktere poging met alleen pageId werd door Webflow afgewezen (400 Invalid parameter: pageId). Geen geslaagde Webflow-publicatie of livecontrole claimen. Voor volledige publicatie is gerichte eigenaarbevestiging nog nodig. Coming Soon blijft staan.
- Nog af te ronden vóór verkoop: checkout aan klantfrontend koppelen en ingelogd controleren; productieaanbod/import met onderbouwde ACC-kosten; productieherstelbediening, inclusief foutafhandeling na claim; echte Stripelevering en volledige geautoriseerde betaling/boeking/voucher/mail-proef; bevestigingspagina publiceren en live controleren. De nieuwe Stripewebhook blijft actief; verkoop/boekingen/betalingen/refunds/mail blijven gesloten.
- Terugval: nieuwe2596 gesloten laten of na controle verwijderen; geen bestaande klantroute aangepast. Voor deze plaatsing geen bedrijfsdata gewijzigd; een branchback-up is geen herstel van gedeelde database of externe transacties. Order97/99 ongemoeid. Voorbereid/geplaatst is niet publiek vrijgegeven.


## REL-20261015-WEBFLOW-PUBLISHED — SD-13 bevestigingspagina gepubliceerd

- Eigenaar gaf op15oktober2026 expliciet toestemming voor volledige Webflow-sitepublicatie na toelichting over meepubliceren van klaarstaande wijzigingen. Bron: main `9be4a8f50a939f3e5e231b5e9666a478aa099ab4`, public-preview/webflow/confirmation-combined-embed.html en bijbehorende confirmation-production-view.js/confirmation-router.js.
- Voorcontrole: alle25 Webflow-pagina's opgevraagd; alleen Boekingsbevestiging6acbead36631ab0d5cf3b9fd heeft een wijzigingstijd na vorige publicatie11oktober20:24UTC. Home6904c04a33f45c0e5cb0484a blijft Coming Soon op /. Opgeslagen HtmlEmbed b883ba38-59f9-74c3-6cdf-556cc786337a teruggelezen met nieuwe router/production-view. Geen site-instructies aangetroffen. Dit is een paginametadata-/embedcontrole, geen volledige CMS-inhoudaudit.
- Bestemming: Webflow-site68cb0d808ea4f2467bb313af, www.seasondeals.nl, seasondeals.nl en Webflow-subdomein. Full-site publishTaskId `80432de5-349a-4f82-bbf3-5c521596df09`. Get Site bevestigt lastPublished/fullSiteCompiledAt `2026-10-15T07:20:53.290Z` (09:20Amsterdam), eveneens op beide eigen domeinen. Eerdere status alleen staging/publicatie geblokkeerd is hiermee achterhaald.
- Live browsercontrole: `https://www.seasondeals.nl/boeking-bevestiging` toont logo, nieuwe vormgeving en correct “Bevestiging niet beschikbaar” zonder persoonlijke sessielink; geen sandboxbanner. DOM bevat confirmation-production-view.js?v=20261015-2 en confirmation-router.js?v=20261015-2, naast de behouden sandboxrenderer. `https://www.seasondeals.nl/` toont nog Coming Soon, logo en inschrijfformulier. Geen formulier verstuurd.
- Bewijsgrens: publicatie en lege-linkweergave bewezen. Geen echte boeking, betaling, voucher of mail gebruikt/aangemaakt; een succesvolle bevestiging met echte productiegegevens is hiermee NIET bewezen. Xano-configuratie en gesloten transactie-/verkooppoorten niet gewijzigd. Nieuwe Stripewebhook blijft ongemoeid actief; partnerroute en orders97/99 ongemoeid.
- Terugval: bevestigingsembed gericht herstellen naar public-preview/webflow/confirmation-embed.html uit72c36d8 en opnieuw publiceren na controle. Geen bedrijfsdatawijziging; gedeelde Xano-database niet geraakt. Resterend: klantfrontend op2596 aansluiten en geautoriseerd controleren, productieaanbod/ACC-kosten, productieherstel en volledige geautoriseerde ketenproef. Deze paginapublicatie is geen vrijgave van publieke verkoop.


## REL-20261015-GUEST-CHECKOUT — SD-09/13 boeken zonder account

- **Eigenaarbesluit15oktober2026:** klanten boeken zonder account; verplichte klantlogin was geen afspraak. De eerder gebouwde private2596 is niet de publieke klantflow en blijft ongebruikt/gesloten. Geen authenticatie van bestaande klant-, beheer- of partnerroutes verwijderd.
- Bron: main023c3d9450b6013bdadd22adf05995c863a53ea4, interne productiecheckout798. Nieuwe bestemming: Xano workspace1/v1 Public API7 POST2598 `supplier/production/guest-checkout`, exact `https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-public/supplier/production/guest-checkout`. Zeven inputs, geen auth/customer_id/bedrag als input. Gepubliceerd met nul drafts, actuele bron teruggelezen.
- Gastflow maakt geen klantaccount en zoekt geen bestaande klant op per e-mail. Intern customer_id=0 op order én vastgelegde request; gastgegevens blijven op intent/orderbinding. Een bestaande klantidentiteit wordt nooit uit een ingevuld e-mailadres afgeleid. Schema-/schrijfruntime van customer_id=0, voucherbinding en volledige downstream-gastverwerking zijn nog **TE VERIFIËREN** vóór vrijgave; er is voor deze plaatsing geen bedrijfsrecord aangemaakt.
- Een256-bit willekeurig request_key wordt serverzijdig gehasht naar een dealgebonden referentie; transactielock op deal plus identieke-requestcontrole vóór orderaanmaak; bestaande Stripe-idempotentie per intent behouden. Hergebruik alleen bij creating_checkout/pending_payment en maximaal23uur; geen order-/intent-ID in gastresponse. De browser bewaart alleen request-key/digest voor herhaling en stuurt nooit een zelfgekozen klantnummer of bedrag.
- Gepubliceerde2598 via runner zonder login uitgevoerd met fictieve input:8 statements20ms, ERROR_CODE_ACCESS_DENIED / PRODUCTION_NOT_RELEASED. Gate vóór database, prebook en Stripe. Dit bewijst uitsluitend de gesloten poort; geen concurrentie- of betaling/boekingsbewijs.
- Nieuwe alleen-lezen Public API7 POST2597 `supplier/production/booking-preview`, opv1 geplaatst en gericht bijgewerkt met no-store/private, no-referrer en minimale klantresponse. Alle vier poorten gesloten →status closed zonder database-/provideractie. Bij toekomstige vrijgave hergebruikt availability793; inkoop/marge/offer-ID worden niet teruggegeven. Actuele bron backend/xano/production/booking-preview.xs. Runtime via aangesloten pagina nog TE VERIFIËREN op dit checkpoint.
- Webflow: oude /boeken (695bd851c2b988eef5d14f96) bevat SimplyBook en blijft intact. Nieuwe /hotel-boeken pagina6ad0816f4ae4a03b339917ca met HtmlEmbed4d3abe98-4094-c9a9-8902-fbb0d7d42b35 opgeslagen. Geen login-, registratie- of wachtwoordvelden. Bron hotel-checkout.js/css en webflow/hotel-checkout-embed.html. Staging geplaatst; publicatie/livecontrole volgt na assetuitrol.
- Vijf lokale Node-tests geslaagd: gesloten/sandbox/verlopen/verkeerde quote blokkeren, alleen live-Stripe-URL, gastverzoek zonder login/customer_id/prijs, dezelfde sleutel na timeout, gewijzigd verzoek geweigerd en dubbelklik één request. Dit zijn fixtures met mocktransport, geen echte boeking of mail.
- Huidige begrenzing: één kamer,1–6 volwassenen, alleen expliciet ondersteunde niet-restitueerbare voorwaarden; andere voorwaarden veilig geblokkeerd. Herstel van een onzekere betaalpoging vereist controle; browser start niet automatisch een nieuw verzoek. Aanbodkoppeling naar deze pagina, overige tariefvoorwaarden, productieaanbod/ACC-kosten, productieherstel en volledige ketenproef blijven open. Prioriteit eigenaar: snel live met voldoende boekbaar aanbod, liefst vóór Black Friday/Cyber Monday; dit is een doel, geen vrijgavegarantie.
- Terugval: nieuwe2597/2598 achter config_status788 gesloten houden en alleen na afhankelijkheidscontrole verwijderen; nieuwe pagina verbergen of embed terugzetten.798/2596, partner- en sandboxroutes ongewijzigd. Geen dataherstel nodig voor plaatsing; branches delen live database.97/99 niet gelezen/gewijzigd; geen betaling, boeking, refund of mail. Coming Soon en alle verkoop-/transactiepoorten blijven gesloten.


## REL-20261015-GUEST-PUBLISH-CHECK — SD-09/13 publicatie nog geblokkeerd

- Bron: main `21e7ad07a7a3bcc721e4d10c5b4982dc266bb1a8`; vier projectdocumenten opnieuw gelezen. Gastboekingspagina blijft opgeslagen in Webflow site68cb0d808ea4f2467bb313af, pagina6ad0816f4ae4a03b339917ca, /hotel-boeken. Geen geslaagde nieuwe Webflow-publicatie.
- Eigenaar bevestigde op15oktober09:54Amsterdam publicatie na uitleg dat Webflow de hele site publiceert. Nieuwe full-site publicatie naar beide eigen domeinen en Webflow-subdomein is desondanks door automatische goedkeuringscontrole geweigerd: toestemming dekt volgens die controle niet aantoonbaar alle eventuele andere klaarstaande wijzigingen. Geen alternatieve publicatieroute geprobeerd. Laatst gecontroleerde publicatietijd blijft2026-10-15T07:20:53.290Z.
- Voorcontrole van26 paginametadatasets: alleen Hotel boeken heeft een lastUpdated na vorige publicatie; Home blijft Coming Soon op /. Dit bewijst niet dat alle sitebrede/CMS-wijzigingen zijn geïnventariseerd. Liveweergave van de nieuwe pagina blijft TE VERIFIËREN.
- Gerichte frontendcorrectie in public-preview/js/hotel-checkout.js: bij een geldige deal-ID zonder verblijfsdata wordt eerst de datumkeuze getoond; geen ongeldige previewaanvraag met lege verplichte datums. Bestemming main/GitHub Pages; uitrol en aangesloten browsercontrole van deze correctie nog TE VERIFIËREN op dit checkpoint. Vijf bestaande mocktransporttests opnieuw geslaagd; geen echte transactie of gastgegevens gebruikt.
- Vaste eigenaarafspraak: huidige dealcardlayout en dealpagina behouden; nieuwe boekingsstap moet dezelfde huisstijl volgen. Geen bestaande dealkaart-/dealpaginabron gewijzigd. Exacte visuele aansluiting van de nieuwe pagina blijft na publicatie te controleren. Boeken zonder account blijft vereist; private2596 is niet de publieke gastflow.
- Bestaande beperkingen blijven: guest customer_id=0 schrijfruntime/voucherbinding, aanbodkoppeling, ondersteunde tarieven, productieaanbod/ACC-kosten, herstel na onzekere verwerking en volledige geautoriseerde productieketenproef TE VERIFIËREN. Geen verkoopvrijgave; Xano-poorten, Coming Soon, partnerroute en orders97/99 ongewijzigd.
- Terugval frontend: hotel-checkout.js uit21e7ad07 herstellen. Geen bedrijfsdata gewijzigd; geen dataherstel nodig. Volgende publicatiestap vereist oplossing van de expliciete full-site goedkeuringsblokkade, daarna livecontrole en actualisatie van beide documenten.


## REL-20261015-GUEST-PUBLISHED — SD-13 gastboekingspagina gepubliceerd

- Eigenaar gaf op15oktober2026 om09:57Amsterdam expliciet toestemming voor volledige Webflow-sitepublicatie inclusief eventuele overige opgeslagen wijzigingen. Publicatie geslaagd: site68cb0d808ea4f2467bb313af, www.seasondeals.nl, seasondeals.nl en Webflow-subdomein; publishTaskId0434336b-75e2-4920-9cef-75e7a9ea9a78. Get Site bevestigt lastPublished/fullSiteCompiledAt2026-10-15T07:57:47.311Z op beide eigen domeinen. De vorige publicatieblokkade is hiermee opgelost.
- Bron: mainc8c97bb20d1a191cb80a8281a91f460ae87e4670; GitHub Pages workflow38702204692 completed/success bevestigd. Frontend hotel-checkout.js/css en hotel-checkout-embed.html; bestemming Webflow /hotel-boeken, pagina6ad0816f4ae4a03b339917ca, embed4d3abe98-4094-c9a9-8902-fbb0d7d42b35.
- Live browsercontrole op https://www.seasondeals.nl/hotel-boeken: SeasonDeals-logo, groene kop, lichte achtergrond, tekst dat geen account nodig is en correcte melding om eerst een hoteldeal te kiezen. Geen loginvelden. Screenshot van deze lege-selectieweergave gecontroleerd. https://www.seasondeals.nl/ toont nog Coming Soon met bestaande inschrijving; niets ingestuurd. Bestaande dealcard-/dealpaginabron niet aangepast.
- Bewijsgrens: publicatie en lege-selectieweergave bewezen. Datumselectie met aangesloten aanbod, gesloten preview-response via frontend, mobiele weergave en volledige visuele vergelijking van de ingevulde boekingsstap blijven TE VERIFIËREN. Geen echte betaal-/boekings-/voucher-/mailproef en geen productieaanbod vrijgegeven.
- Xano-configuratie en transactie-/verkooppoorten ongewijzigd gesloten. Guest customer_id=0 schrijfruntime/voucherbinding, aanbodkoppeling, productieaanbod/ACC-kosten, tarieven en herstel blijven open zoals geregistreerd in REL-20261015-GUEST-CHECKOUT. Geen orders97/99 gelezen of gewijzigd; partnerroute ongewijzigd. Deze frontendpublicatie is geen verkoopvrijgave.
- Terugval: nieuwe pagina gericht verbergen of embed herstellen en site opnieuw publiceren na controle; frontend kan naar21e7ad07 terug. Geen bedrijfsdatawijziging of databaseherstel nodig. Volgende stap: aanbod- en gastboekingkoppeling verder afronden achter gesloten poorten.


## REL-20261015-REMOVE-EXTRA-STEP — SD-13 bestaande klantreis behouden

- Eigenaarbesluit15oktober10:15Amsterdam: extra boekingsstap verwijderen. Vaste klantreis blijft new-website → bestaande dealpagina (/dea?id=…) → Stripe → bevestiging, zonder verplichte klantlogin. Geen aparte /hotel-boeken-stap toevoegen. Bestaande dealcardlayout en dealpaginastyling behouden.
- Broncontrole main12dd36835f292ed63de1082e8de43175f210fe1c: public-preview/js/site.js maakt links naar CONFIG.dealPage; deal.js toont check-in/check-out/aantal gasten en startCheckout POST naar /api:seasondeals-public/create-checkout-session, daarna directe navigatie naar checkout_url. Geen hotel-boeken-verwijzing in deze bestaande route. Webflow /dea pagina6a5f7754024f18d807219648 embed3c695ca3-885f-5839-7c83-7c61e62d4a2c teruggelezen; oorspronkelijke inhoud behouden. Deze broncontrole bewijst geen geslaagde runtimebetaling.
- Wijziging: uitsluitend Webflow Hotel boeken pagina6ad0816f4ae4a03b339917ca teruggezet naar draft=true (reversibel bewaard, niet permanent verwijderd). Volledige site opnieuw gepubliceerd naar beide eigen domeinen en Webflow-subdomein onder bestaande eigenaarautorisatie. publishTaskId68efaeff-886f-40b9-a7a9-57de79b5fd02; Get Site bevestigt2026-10-15T08:17:36.110Z. Live /hotel-boeken toont nu Page Not Found; extra pagina niet meer publiek toegankelijk.
- Livecontrole: op /new-website bestaande kaart Romantic Getaway aangeklikt, uitkomst /dea?id=4&view=inventory-v2. Bestaande foto/informatie/prijs/boekingskaart met datums, aantal gasten en oranje boekingsknop zichtbaar. Geen formulier ingestuurd, geen Stripe-sessie aangemaakt. Dit bestaande testaanbod is geen bewezen productievoorraad; geen records gewijzigd.
- Frontend hotel-checkout.js/css/embed blijft uitsluitend als ongebruikte bron/terugval in Git; niet opnieuw aansluiten of publiceren zonder gewijzigde eigenaarbeslissing. Xano2597/2598 blijven achter de gesloten productieconfiguratie beschikbaar als technische bouwstenen; niet verwijderd of op de partnerroute aangesloten. Geen nieuwe klantgegevensvelden op de dealpagina toegevoegd.
- Nog te doen: vaststellen hoe de bestaande checkout de minimaal benodigde Nuitée-gastgegevens krijgt en de productieaansluiting binnen de afgesproken directe route afronden. Geen aannames dat e-mail per gast noodzakelijk is. Guest customer_id=0 schrijfruntime/voucherbinding, productieaanbod/ACC-kosten en volledige keten blijven TE VERIFIËREN. Afzonderlijke pagina verwijderen lost deze open productiepunten niet op.
- Coming Soon-root, deal.js/site.js/deal.css/site.css, bestaande partnerroute, orders97/99 en alle Xano-poorten ongewijzigd. Geen betaling, boeking, refund of mail. Geen bedrijfsdataherstel nodig. Terugval van deze pagina-afmelding kan technisch door draft=false plus publicatie, maar druist in tegen de huidige eigenaarbeslissing en is geen geplande vervolgstap.


## PREP-20261015-DIRECT-STRIPE-GUEST — SD-09/13 directe klantreis onderzocht

- Bron: mainfdbb72e09b29aeda629de97f5532888924c508bc plus alleen-lezen Xano workspace1/v1 Public API7 create-checkout-session68. Bron daadwerkelijk via XanoScript gelezen; niet uitgevoerd of gewijzigd.68 accepteert alleen deal_id/checkin/checkout/guests, weigert source=provider_sync, maakt order met customer_id=0 en gebruikt STRIPE_SECRET_KEY_test. Stripe billing_address_collection=required en phone_number_collection.enabled=true staan al ingesteld. Geen vooraf ontvangen gastnaam/mail; success/cancel verwijzen naar /success en /cancel. Normale partnerroute behouden, niet blind omgezet naar productie.
- Eigenaar bevestigt dat layout, velden en klantreis exact behouden blijven. Geen extra pagina, login of zelfstandig toegevoegd formulier. Dit is strikter dan alleen behoud van kleuren/styling; eventuele zichtbare wijziging eerst concreet voorleggen.
- Primaire bron https://docs.liteapi.travel/docs/adding-guests-during-the-booking-step (gelezen15okt): exact één hoofdcontact per kamer met firstName,lastName,email; occupancyNumber identificeert kamer. Niet verplicht alle reizigers afzonderlijk uitvragen. Stripe customer_details/billingnaam bewijst niet welke persoon verblijft; geen namen splitsen of betaalnaam automatisch als gastidentiteit overnemen.
- Concreet voorstel, NOG NIET GEACTIVEERD: uitsluitend voor toekomstige Nuitée-checkouts twee verplichte Stripe custom_fields, guestfirstname met label Voornaam hoofdgast en guestlastname met label Achternaam hoofdgast. E-mail uit bestaande Stripe customer_details.email als boekingscontact. Eén kamer; aantal volwassenen blijft afzonderlijke bezetting. De klant blijft direct van de bestaande dealpagina naar Stripe gaan. Stripe ondersteunt custom_fields (https://docs.stripe.com/api/checkout/sessions/create; https://docs.stripe.com/api/checkout/sessions/object). API2023-10-16 en daadwerkelijke weergave/runtime nog TE VERIFIËREN.
- Voorbereide, NIET aangesloten policy backend/xano/production/stripe-guest-policy.cjs: alleen serveropgehaalde Session na bestaande exacte betaalverificatie; controle op live/paid/status/bedrag/session/PaymentIntent/order/intentreferenties. Geeft precies één hoofdcontact voor één kamer; weigert ontbrekende/dubbele naamvelden, ontbrekende email, sandbox, onbetaald/verkeerde binding en meerdere kamers. Geen accountlookup, externe call of write. Vier Node-tests met fictieve fixtures geslaagd. Dit is lokale policyvoorbereiding, geen werkende productiecheckout of Xano-uitrol.
- Bestemming van deze wijziging: alleen Git main (policy + tests + beide documenten). Geen Webflow/Stripe/Xano-configuratie gewijzigd. Eigenaarbeslissing over de twee zichtbare Stripe-velden nog nodig conform zijn expliciete afspraak. Geen nieuwe Stripe-test/live-sessie aangemaakt voor schermafbeelding.
- Vervolg na besluit: aparte directe supplier-checkout zonder voorafgaande holder/guests-input voorbereiden; gegevens pas uit exact geverifieerde betaalde Stripe Session binden voordat fulfill wordt gestart. Ontbrekende/ongeldige gegevens veilig naar manual_attention, geen boeking of verzonnen naam; nieuwe flow niet laten vallen op legacy partnerroute. Quote, idempotentie, customer_id=0/voucherbinding en herstel moeten worden aangesloten en bewezen. Echte productie-deal/import/ACC-kosten blijven afzonderlijk open; alle poorten dicht en /hotel-boeken offline.
- Terugval: deze niet-aangesloten policybestanden kunnen uit main verwijderd worden zonder runtime-effect. Geen bedrijfsdatawijziging; geen databaseherstel. Orders97/99, bewezen sandboxstappen en partnerroute ongemoeid.


## REL-20261015-STRIPE-GUEST-BINDING — SD-09/13 hoofdgast uit Stripe naar Xano

- Eigenaar heeft op15oktober expliciet de twee Stripe-velden Voornaam hoofdgast en Achternaam hoofdgast en opslag in Xano goedgekeurd; opdracht om uit te voeren om11:08Amsterdam. De eerdere vermelding dat dit besluit nog ontbreekt is achterhaald. Geen extra pagina, klantaccount of wijziging van dealcard/dealpagina.
- Bron: main `efb0dd81733c9e2ab5bd35c6e463e43e603d0913`; bestaande Xano-bronnen2598/791/792 vóór wijziging via editor geëxporteerd en bytegelijk aan eerdere bron gecontroleerd. Bestemming: uitsluitend Xano workspace1, branchv1, Public API7 POST2598 supplier/production/guest-checkout en functies791 verify_payment /792 claim_payment. Deze drie geselecteerde drafts zijn samen gepubliceerd; melding “3 drafts published”, daarna nul drafts. Gepubliceerde bron teruggelezen en opgenomen in backend/xano/production/{guest-checkout,verify-payment,claim-payment}.xs.
-2598 vraagt nu alleen deal_id/checkin/checkout/guest_count/request_key. Namen/mail worden niet vooraf gevraagd en niet verzonnen. Stripe-aanvraag bevat verplichte tekstvelden guestfirstname/guestlastname, maximaal100tekens. Contactmail komt uit de betaalde Session customer_details.email. Nieuwe referentie SD-DIRECT en guest_capture=stripe-custom-fields-v1 scheiden deze aanvraag van eerdere gastcheckouts; herhaalsleutel, quotecontrole, prijsbinding en gesloten poorten behouden.
-791 haalt de Session serverzijdig op en blijft Session, PaymentIntent en charge exact controleren. Pas daarna wordt voor deze nieuwe flow één hoofdgast voor één kamer afgeleid; geen splitsing van betaalnaam of aanname dat kaarthouder de hotelgast is. Uitkomst blijft intern; geen nieuwe publieke gastgegevensresponse.
-792 bewaart geldige gegevens onder intent-recordlock in bestaande supplier_checkout_intents.holder (firstName,lastName,email) en guests (één hoofdcontact, occupancyNumber1), gekoppeld via order_id. Dezelfde transactie claimt de verwerking; latere dubbele meldingen overschrijven de gast niet. Bestaande downstream795 leest dit intent voor Nuitée;797 gebruikt holder voor bevestiging. Geen extra databasekolommen toegevoegd, geen klantaccount aangemaakt.
- Bij betaalde maar ontbrekende/ongeldige gastgegevens: intent manual_attention, order betaald met providerfout, claimed=false en geen leveranciersboeking. Geen automatische herboeking of naamfallback. Oudere interne productieflow zonder guest_capture houdt zijn bestaande opgeslagen identiteit.
- Bewijs: acht lokale Node-tests geslaagd, waaronder de daadwerkelijke JS-lambda's uit de teruggelezen Xano-bron: samengestelde namen, één kamercontact, ontbrekende/dubbele/ongeldige velden, verkeerde binding en behoud oudere identiteit. Gepubliceerde792-run met fictieve ID0:6statements20ms, PRODUCTION_NOT_RELEASED vóór database/Stripe. Gepubliceerde2598-run met vijf fictieve inputs zonder holder/guests:8statements30ms, dezelfde gesloten-poortmelding vóór database/provider/Stripe. Geen bedrijfsrecord, betaling, boeking, voucher of mail aangemaakt.
- Bewijsgrens: code geplaatst en gesloten poorten getest; werkelijke Stripe-formulierweergave/API-acceptatie2023-10-16, opslag na echte betaling en volledige keten zijn nog TE VERIFIËREN. customer_id=0 schrijfruntime/voucherbinding niet door deze gesloten controle bewezen. Geen volledige productieafronding claimen.
- Volgende aansluiting: bestaande deal.js-route veilig naar2598 sturen voor expliciete Nuitée-productiedeals, met stabiele request_key en dezelfde zichtbare pagina; legacy68 blijft partnerroute en weigert provider_sync. Die frontenddispatch is nog niet gewijzigd. Productieaanbod/import en onderbouwde ACC-kosten, herstel na claim en geautoriseerde volledige ketenproef blijven open.
- Terugval: herstel uitsluitend de drie genoemde bronbestanden uit efb0dd8 naar dezelfde Xano-ID's en publiceer gericht; gates gesloten houden. Voor deze plaatsing geen bedrijfsdatawijziging; codebackup herstelt geen gedeelde livedatabase of externe transacties. Coming Soon, /hotel-boeken offline, partnerwebhook/route, sandboxstappen en orders97/99 ongewijzigd. Plaatsing opv1 is geen publieke productievrijgave.


## REL-20261015-DIRECT-DEAL-ROUTE — SD-09/13 bestaande boekingsknop aansluiten

- Eigenaaropdracht15oktober11:29Amsterdam: bestaande boekingsknop aansluiten, huidige layout behouden, productie gesloten. Bron main a53f0979dd6348e9901785ead06189f72b9192a4; vier projectinstructies eerder deze sessie gelezen. Bestemming public-preview/js/deal.js op main/GitHub Pages en Webflow /dea pagina6a5f7754024f18d807219648 footer. De actuele Webflow head/footer komen overeen met repositorybron; geen site-instructies gevonden.
- Bestaand formulier/datums/aantal gasten/vormgeving ongewijzigd. Alleen source=provider_sync gaat naar Public API7 POST2598 supplier/production/guest-checkout; backend793/794 controleert autoritatief Nuitée, productie, goedgekeurd aanbod/bezetting/prijs. Andere deals houden originele68-route en exact deal_id/checkin/checkout/guests-contract. Geen supplier-fallback naar68 bij fouten.
- Nieuwe aanvraag bevat uitsluitend deal_id/checkin/checkout/guest_count/request_key; geen login, voorafgaande naamvelden, clientbedrag of klant-ID. De twee goedgekeurde naamvelden blijven in Stripe. Een256-bit browserkey wordt vóór de aanvraag met verblijfsfingerprint in sessionStorage bewaard. Zelfde aanvraag na timeout gebruikt dezelfde key; gewijzigde/verlopen/onleesbare poging wordt geblokkeerd voor controle, geen automatische nieuwe betaling. Dubbelklik wordt tegengehouden. Alleen expliciete403 PRODUCTION_NOT_RELEASED wist de ongebruikte poging, omdat deze gate vóór iedere database-/provider-/Stripeactie staat.
- Supplierresponse moet production/pending_payment/EUR zijn en uitsluitend naar HTTPS checkout.stripe.com/c/pay/cs_live_… verwijzen. Andere betaalbestemming, sandbox of verkeerde status wordt geweigerd. Productiegesloten geeft op bestaande pagina een Nederlandse melding.
- Zes Node-tests op de daadwerkelijke checkoutfuncties met mocktransport geslaagd: suppliercontract, ongewijzigde partnerroute, hergebruik na timeout, gewijzigde aanvraag geblokkeerd, gesloten poort, onveilige/sandboxredirect en dubbelklik/verlopen poging. HTML-renderfuncties en CSS niet gewijzigd. Dit zijn geen echte Stripe-/Nuitée-transacties.
- Plaatsing op dit checkpoint: bron en tests naar main voorbereid; GitHub Pages-uitrol en Webflow-footer-versie/publicatie/livecontrole volgen. Geen productieaanbod geselecteerd, bestaande testdeals niet omgezet. Echte supplier-deal op /dea, API-acceptatie van Stripevelden, guest-opslag/voucherbinding en volledige keten blijven TE VERIFIËREN.
- Terugval: deal.js en deal-before-body.html uit a53f097 terugplaatsen; Webflow-footer oorspronkelijke versietag herstellen en gericht controleren/publiceren. Geen bedrijfsdatawijziging of dataherstel; gates gesloten. Coming Soon, extra boekingspagina offline, normale partnerroute, orders97/99 en bewezen sandboxstappen behouden.

- Eerste plaatsing49d9aa4 op main/Pages (workflow38714011005 success) en Webflow-publicatie3792cb14-b979-4231-8934-5074ec9f9807 om2026-10-15T09:36:12.375Z. Livecontrole vond eigen regressie: supplier-check was onbedoeld ook in loadDeal geplaatst, ReferenceError supplier is not defined en foutmelding bij laden. Geen formulier of transactie uitgevoerd. Gerichte correctie verwijdert dit blok uit loadDeal; gehele laad-/rendercode is weer bytegelijk aan a53f097. Zevende test voert het volledige paginascript inclusief laden/renderen uit en slaagt. Herpublicatie en livehercontrole volgen; eerste publicatie niet als succesvolle aansluiting tellen.

### Definitieve plaatsing en livecontrole — REL-20261015-DIRECT-DEAL-ROUTE

- Correctiecommit `c4656d605398a1f48497b313d575a90b109cb1f7` op main. GitHub Pages workflow38714357355: build/report-build-status/deploy alle completed/success. Webflow-herpublicatie task6901db4c-4e54-4eff-ac96-d8d6e26dc6e4; get_site bevestigt lastPublished/fullSiteCompiledAt2026-10-15T09:38:32.643Z (11:38Amsterdam), beide eigen domeinen plus Webflow-subdomein. Bestaande eigenaarautorisatie voor volledige sitepublicatie toegepast. Voorcontrole26paginametadata: alleen /dea gewijzigd sinds voorafgaande publicatie; dit is geen volledige CMS-audit.
- Live /dea?id=4&view=inventory-v2 na herladen: titel Romantic Getaway, bestaande foto/informatie/prijs/boekingskaart zichtbaar; DOM laadt deal.js?v=20261015-direct-2. Knop met lege datums geeft “Kies eerst een geldige check-in- en check-outdatum.” vóór enige checkoutaanvraag. Screenshot gecontroleerd. De eerste laadregressie is hiermee aantoonbaar hersteld. Home / blijft Coming Soon. Geen nieuwe boekingspagina of login.
- Definitieve bewijsgrens: technische frontenddispatch gepubliceerd; zeven lokale mocktests en live laden/formuliervalidatie bewezen. Er is nog geen echte productie-supplierdeal via deze pagina naar Stripe gestuurd; testdeal4 blijft bestaande testdeal. Geen echte checkoutbetaling, gastopslag, hotelreservering, voucher of mail aangemaakt/getest. Xano-poorten en configuratie niet gewijzigd. Volgende stap: goedgekeurde Nuitée-productiedeal/import/ACC-kosten klaarzetten en volledige keten gericht bewijzen vóór verkoopvrijgave.


## DOC-20261015-NL-AANBOD-AUTOMATISERING — SD-15 verplichte open livegangscope

**Eigenaarbesluit15oktober2026,11:41–11:46Amsterdam:** automatisch hotelaanbod op de website, voor heel Nederland. Amsterdam is uitsluitend het eerste gezamenlijke voorbeeld, geen beperking van het doelgebied. Breed aanbod van hotels, verblijfsduren, kamers/bezettingen en opties met of zonder ontbijt voor zover daadwerkelijk door Nuitée beschikbaar en technisch ondersteund. Eigenaar wil niet iedere deal handmatig invoeren; de vraag betreft aanbodautomatisering, niet individuele klantboekingen.

**Status: OPEN — vereist onderdeel van de gewenste livegang; niet stilzwijgend uitstellen of als klaar markeren omdat de API/checkout bestaat.** Eventuele gefaseerde beperktere start alleen als expliciet eigenaarbesluit met beperkingen vastgelegd. Dit besluit geeft geen toestemming om verkoop, echte transacties of een automatische publicatietaak nu te activeren.

### Open uitvoerings- en acceptatielijst

- [ ] **SD-15.1 Eerste voorbeeld:** samen één echt Amsterdamse hotel uit Nuitée-productie doorlopen: hotelinformatie, foto’s, aangeboden kamers, datums/verblijfsduren, bezettingen, ontbijt, prijs en voorwaarden. Eerst controleerbaar klaarzetten; geen testdeal omzetten of echte reservering maken.
- [ ] **SD-15.2 Aanbodregels:** landelijke selectie en uitsluitingen, prijs-/margeregels met onderbouwde ACC-kosten, datumbereik, kwaliteit/content en duplicaatbeleid concreet vastleggen. Geen willekeurige standaardkeuze van één/twee nachten of ontbijt als eigenaarbesluit presenteren. Exacte grenzen nog TE BEPALEN; “alle mogelijkheden” is geen bewijs dat elke variant ondersteund is.
- [ ] **SD-15.3 Productie-import:** bestaande SD-11-bron inventariseren; serverzijdig aanbod verifiëren en hotels/varianten idempotent opslaan in deals/supplier_deals. Foto’s, inhoud, valuta, inbegrepen onderdelen en voorwaarden correct koppelen. Geen dubbele kaarten bij herhaalde import.
- [ ] **SD-15.4 Varianten en boekbaarheid:** huidige beperking één kamer,1–6 volwassenen en vooraf goedgekeurde bezetting/aanbodvoorwaarden expliciet oplossen of ondersteunen per variant. Gevraagde mogelijkheden zoals andere bezettingen, kinderen/meerdere kamers, verblijfsduren en tarief-/ontbijtopties eerst inventariseren en gericht implementeren/testen. Niet aannemen dat een zichtbare gastselector deze mogelijkheden al ondersteunt.
- [ ] **SD-15.5 Bestaande website:** productieaanbod automatisch vullen in bestaande dealcards en /dea, met dezelfde layout/styling en directe route naar Stripe. Geen aparte boekingspagina of verplichte login. Noodzakelijke zichtbare keuze-uitbreidingen eerst concreet met eigenaar afstemmen.
- [ ] **SD-15.6 Automatische publicatie en onderhoud:** regelsgestuurde selectie/plaatsing plus periodieke prijs-/beschikbaarheidscontrole aansluiten; gewijzigde, verouderde, onbeschikbare of onvoldoende renderende deals veilig blokkeren/verbergen. Verversingsfrequentie, quota/kosten, retrygedrag en foutmeldingen vastleggen. Geen onbewezen voorraad aantallen tonen; actuele controle bij boeken behouden.
- [ ] **SD-15.7 Bewijs en beheer:** één productiedeal correct via bestaande kaart en pagina tonen; herhaalde import zonder duplicaten, variant-/prijsbinding, verouderd/onbeschikbaar aanbod en herstel na API-uitval bewijzen. Aanbodautomatisering afzonderlijk verifiëren naast betaling/boeking/voucher/mail. Beheer moet tonen wat is bijgewerkt, geweigerd of geblokkeerd; routinehandwerk per deal is niet het einddoel.
- [ ] **SD-15.8 Vrijgave:** daadwerkelijke bron/doel-ID’s, plaatsing, controles en resterende beperkingen in beide documenten registreren; expliciet go/no-go vóór activering van automatische publieke productieplaatsing en verkoop. Voor nu Coming Soon en gesloten transactie-/verkooppoorten behouden.

### Bron, bestemming en bewijsgrens

- Bronbesluit: bovenstaande eigenaarberichten; technische baseline main `e414492de55643bcd625786f9f7ca7334b59d245`. Afhankelijk van SD-02/03/07/10/11/13. Bestaande private sandboxaanbod-/verversingsfuncties zijn eerder bewezen; die resultaten blijven staan en bewijzen geen landelijke productieautomatisering.
- Bekende bouwstenen: SD-11 vermeldt historisch importconcept782 op nuitee-deal-import-2026-10-07; actuele bron/publicatiestatus en exacte productiedoelen **TE VERIFIËREN**. SD-03 vermeldt v1 Admin1260/1261 en taak32; productiegeschiktheid/selectie afzonderlijk verifiëren, niet blind activeren.
- Beoogde bestemming: afzonderlijk gecontroleerde Xano workspace1/v1 productie-import/verversing en bestaande Webflow new-website/dea via public-preview/js/site.js en deal.js. Nieuwe/gewijzigde endpoint-/taak-ID’s **TE VERIFIËREN** vóór plaatsing.
- Deze registratie wijzigt alleen SEASONDEALS_STATUS.md en SEASONDEALS_LIVEGANG.md op GitHub main. Geen software, taak, websiteconfiguratie, aanbodrecord, boeking of publieke verkoop uitgerold. Terugval: deze documentwijziging in Git terugdraaien; geen dataherstel nodig. Orders97/99 en afgeronde sandboxstappen blijven ongemoeid.


## DOC-20261015-AANBOD-AUDIT — SD-02/03/11/15 bestaand werk hergebruiken

- Alleen-lezen inventarisatie op15oktober2026; bron main `1a6110f8edc9c3fccedc7dbd70f8088b254a40d3`, beide statusdocumenten, backend/nuitee/README.md, SERVER_AVAILABILITY_HANDOFF.md, backend/xano/nuitee-sandbox-availability-refresh.xs en admin/js/suppliers.js. Eerdere testbewijzen blijven geldig; geen afgeronde stap heropend of opnieuw getest.
- Reeds bewezen volgens GitHub: list_hotels op5okt gaf vijf Amsterdamse hotels met metadata/foto’s; search_rates en prijsberekening getest; werkelijk sandboxaanbod op8okt opgeslagen als deal17/supplier_deal2. Dit is dus geen project zonder hotelzoekfunctie of voorbeelddeal. SD-02 prijs-/inhoudbeheer en goedkeuring zijn opv1/main getest.
- SD-03 reeds bewezen: zelfstandige v1-taak32 per minuut en ingelogde catalogus; laatste verbetering9okt/PR17 `7044524ff8a7747db4accdaab64d377ab8b45de9` gebruikt maximaal20 kandidaten, oudste controle eerst,45s startbudget en90s snapshots. Oudere passages met tien kandidaten/60s zijn historische tussenstanden. Automatisch verversen van bestaande goedgekeurde sandboxdeals is afgerond binnen die scope; dit ontdekt/importeert niet automatisch nieuw landelijk productieaanbod.
- Actuele Xano-inspectie: workspace1, branch4 `nuitee-deal-import-2026-10-07`, Admingroep58, POST782 `supplier-deals/import` toont DRAFT/11 Draft Changes. Volledige XanoScript via editor gelezen, niet uitgevoerd/opgeslagen/gepubliceerd. Bevestigd: admin/guard+rolcontrole, uitsluitend sandbox/Nuitée, hotel-ID/positieve prijscontrole, bestaande external_id afwijzen, vervolgens twee afzonderlijke db.add voor deals en supplier_deals. Geen serverzijdige provider-offeropvraag of database-transactie in deze bron. De actuele draft bevestigt de eerdere open importstatus; dit maakt reeds gemergede reader/pricing/workflow niet opnieuw open.
- Nieuwe concrete aandachtspunten in dit concept: star_rating=4, max_guests=2 en minimum_nights=2 hardcoded; room_type uit rates[0]; invoerprijs/payload worden niet autoritatief opnieuw bij provider geverifieerd. Deze aannames mogen niet naar breed productieaanbod worden overgezet. Duplicaatcheck vóór losse writes is geen bewezen atomair/idempotent productie-importproces. De draft schrijft wel expliciet draft/is_active=false/is_enabled=false; niet blind publiceren of sandbox vervangen door production.
- Hergebruik: bestaande hotel-/tariefadapters, prijsregels, suppliermapping, beheerworkflow, snapshotpolicy en bestaande websitevormgeving. Nog bouwen/bewijzen: afzonderlijke productie-import met serververificatie en atomaire/duplicaatveilige opslag, juiste varianten/metadata, landelijke selectie en periodieke publieke productieplaatsing met quota/bewaring. SD-15 blijft verplicht open; Amsterdam alleen eerste gezamenlijke voorbeeld.
- Eerstvolgende uitvoering: bestaande hotel-/tariefadapter gericht geschikt maken voor een afgeschermde alleen-lezen productievoorbeeldweergave voor Amsterdam; werkelijke hotel-/kamer-/ontbijtopties tonen voordat selectie-/margeregels en import worden aangesloten. Exacte nieuwe productiebron/doel-ID’s TE VERIFIËREN vóór plaatsing. Geen fictieve testdeal omzetten en geen verkooppoort openen.
- Bestemming van deze audit: uitsluitend beide GitHub-documenten op main. Geen software, configuratie, aanbodrecord, boeking, betaling of mail gewijzigd; Coming Soon en gesloten productiepoorten behouden. Terugval uitsluitend documentcommit terugdraaien; geen bedrijfsdataherstel nodig. Orders97/99 en bewezen stappen4/5/7 ongemoeid.


## REL-20261015-AMSTERDAM-METADATA — SD-15.1 eerste productie-informatie

- Bron main `fd0051d76cbc0b244eab94a19911ae12c8c0ede5`; bestaande gepubliceerde v1 hoteladapter124 via XanoScript gelezen, sandboxkey bevestigd en ongewijzigd behouden. Nieuwe afzonderlijke interne functie `supplier/production/preview_amsterdam_hotels` geplaatst op workspace1/v1 als800; functielijst bevestigt Created/Published15okt11:58Amsterdam, nul drafts. Teruggelezen bron in backend/xano/production/preview-amsterdam-hotels.xs. UI toont Request History Disabled (export vermeldt deze instelling niet).
- Uitsluitend vaste GET naar https://api.liteapi.travel/v3.0/data/hotels?countryCode=NL&cityName=Amsterdam&limit=5 met bestaande afgeschermde NUITEE_PRODUCTION_API_KEY. Vooraf config_status788: config_valid en configured_closed verplicht. Geen invoer, openbaar endpoint, cron, databasewrite, prebook, betaling of boeking. Bestaande hardcoded gesloten poorten blijven ongewijzigd; dit is begrensde interne voorbereiding, geen productievrijgave.
- Werkelijke run15okt11:58Amsterdam: HTTP200, success=true, acht statements260ms, checked_at1792058317305. Vijf hotels met metadata/foto-URL: lp225fcf nhow Amsterdam Rai; lp2fd20 Anantara Grand Hotel Krasnapolsky Amsterdam; lpd55fc Hotel Jakarta Amsterdam; lp450d2 Hotel Estheréa; lp1e279 Park Plaza Victoria Amsterdam. Geen geheime header in resultaat; geen persoonlijke gastgegevens.
- Bewijsgrens: metadata opgehaald met productiesleutel; Hotel Data API bewijst geen actuele kamerbeschikbaarheid, liveboeking, tarief of voorraad. availability_checked=false, can_book/pay/sell=false, production_released=false. De vijf zijn een begrensd voorbeeld, geen landelijke selectie of hoteladvies. Niets op Webflow geplaatst en geen dealrecord geïmporteerd.
- Volgende stap SD-15.1: voor het voorbeeldhotel werkelijke kamers/tarieven/ontbijt en voorwaarden bij concrete voorbeelddata ophalen via afzonderlijke begrensde alleen-lezen productieroute; datum/duurkeuze als voorbeeld benoemen, niet als landelijke beperking. SD-15.2–15.8 blijven open. Terugval: ongebruikte interne800 niet aansluiten; eventueel gecontroleerd verwijderen na afzonderlijk besluit. Geen bedrijfsdatawijziging/dataherstel nodig. Beide documenten en broncheckpoint op main; normale partnerroute, Coming Soon en sandboxbewijzen behouden.


## REL-20261015-AMSTERDAM-RATES — SD-15.1/15.3 admin eerst

**Eigenaarbesluit15okt12:44Amsterdam:** een Nuitée-deal mag pas op de website nadat die in de admin is gecontroleerd en goedgekeurd. Verplichte volgorde: servergeverifieerd concept → admincontrole van inhoud/kamer/voorwaarden/prijs/kosten/marge → expliciete goedkeuring → afzonderlijk toegestane websiteplaatsing. Import/ophalen mag nooit automatisch goedkeuring of publieke zichtbaarheid verlenen. Automatisering moet deze beoordeling respecteren; geen stille auto-approval.

- Bron main `9e5bc840d21f4a1186d2c12663facaaf4e3e01c8`, bestaande productieavailability793 en sandboxadapter125. Afzonderlijke interne functie `supplier/production/preview_amsterdam_rates` geplaatst op workspace1/v1 als801. Functielijst bevestigt Created/Published15okt12:44Amsterdam, nul drafts; teruggelezen bron backend/xano/production/preview-amsterdam-rates.xs. Request History Disabled in UI. Geen bestaande adapter, route, config of goedkeuringscontrole gewijzigd.
- Begrensde alleen-lezen rates-POST naar https://api.liteapi.travel/v3.0/hotels/rates met productiesleutel; alleen hotel lp225fcf,27–29november2026,één kamer/twee volwassenen,EUR/NL,max50rates. Dit zijn gekozen voorbeelddata rond Black Friday, geen eigenaarbesluit om aanbod tot die duur/bezetting te beperken. config_status788 moet valid/configured_closed zijn. Geen prebook, databasewrite of externe transactie.
- Werkelijke response HTTP200/success=true,50offers,3,83s,checked_at1792061152495. Voorbeelden uit standardrates: Nhow Room/Room Only EUR265,32,NRFN,lokale City Tax EUR28,19 excluded; Nhow Room/Breakfast Included EUR285,37,RFN met cancelTime2026-11-14 02:00GMT en City Tax EUR33,87 excluded. Dit zijn upstream offerRetailRate-indicaties voor het gehele voorbeeldverblijf, geen vastgestelde SeasonDeals-verkoopprijs of bewezen nettokosten. suggestedSellingPrice respectievelijk305,12/328,18; betekenis en uiteindelijke prijsregels vóór goedkeuring verifiëren. Aanbod is tijdgebonden; verse verificatie vóór import/boeking nodig.
- Alle50gelezen rate.paymentTypes bevatten NUITEE_PAY. Dit veld is nog geen bewijs dat ACC op bookniveau onmogelijk is; eigenaarbevestigd ACC_CREDIT_CARD blijft het model. De binding tussen rate/prebook/payment.method moet expliciet worden bewezen, niet NUITEE_PAY stilzwijgend gelijkstellen aan ACC of betaalinstellingen wijzigen. Geen prebook gedaan. Processing-/Stripeproductiekosten en marge nog niet geverifieerd. Goedkoopste packageoffer niet blind als openbare losstaande hoteldeal selecteren.
- Admincode daadwerkelijk gelezen: admin/deal-detail.html laadt deal-detail-v5.js; deze staat reviewAllowed alleen toe voor sandbox supplierdeals. Actuele v1 Admingroep3 PATCH903 supplier-deals/{deal_id}/workflow via XanoScript gelezen, niet uitgevoerd/gewijzigd: harde environment==sandbox voor alle acties, submit draft→pending_approval, active alleen vanuit pending_approval en schrijft is_active=false, audit/log. Productie-adminworkflow is dus nog niet aangesloten. Reader/prijsbeheer/sandboxbewijzen blijven afgerond; geen bestaande controle versoepeld.
- Nog te implementeren voordat de gevraagde echte deal beoordeeld kan worden: atomaire/duplicaatveilige productieconceptimport, productiegeschikte adminprijs-/inhoud-/goedkeuringsroute met bewezen kosten en passende voorwaarden, daarna ingelogde controle van datzelfde nieuwe concept. Afzonderlijke acceptatiecontroles: concept/pending/rejected nooit publiek, onbevoegde gebruiker kan niet goedkeuren, gewijzigde prijs/voorwaarden vereisen herbeoordeling, goedkeuring zet geen transactiepoort open. Publieke plaatsing pas na admincontrole/goedkeuring conform eigenaarbesluit.
- Geen deal geïmporteerd, ingediend of goedgekeurd; geen klantwebsite gewijzigd. Volledige admin-/website-/checkoutketen nog NIET gecontroleerd.801 is slechts een interne bouwsteen voor het gevraagde concept. Beide Gitdocumenten plus bron bijgewerkt; Coming Soon, gesloten gates, orders97/99 en afgeronde sandboxstappen behouden. Terugval: nieuwe ongebruikte801 niet aansluiten; geen bedrijfsdataherstel nodig.


## REL-20261015-NHOW-DRAFT — SD-11/15.1 eerste echte conceptdeal

- Bron main `b2a12fe671a64228bea0dbefe7b9586c6a5ef2d8`; nieuwe interne functie workspace1/v1 #802 `supplier/production/import_first_nhow_draft`, gepubliceerd via eigen Review & Publish (alleen802, nul resterende drafts). Broncheckpoint: backend/xano/production/import-first-nhow-draft.xs. Config788 blijft gesloten; alleen metadata800 en verse rates-POST met NUITEE_PRODUCTION_API_KEY, geen prebook/boeking/betaling/mail.
- Aanmaak werkelijk uitgevoerd: 28 statements/3,71s, deal18 en supplier_deal3, status=draft, public=false, prijsvoorstel EUR317,39, production_costs_verified=false. Herhaling26statements/6,17s: dezelfde deal18, created=false; geen tweede concept of overschrijving. Beide inserts in één db.transaction; bestaande eigenaarrow alleen als serialisatielock gelezen. Geen adminrecord gewijzigd. Dit is een begrensde interne import, geen algemene landelijke importdienst.
- Bron hotel lp225fcf, nhow Amsterdam RAI,27–29nov2026,één kamer/twee volwassenen,room-only,standard,NRFN; alleen tarief met uitsluitend inbegrepen EUR-heffingen geselecteerd. Packageoffers uitgesloten. Voorstel max(suggestedSellingPrice,offerRetailRate*1,20), geen goedgekeurd commercieel prijsbeleid. Verwerkings-/Stripekosten null en verificatie false; ACC_CREDIT_CARD eigenaarbevestigd, werkelijke prebookbinding nog open. Voorbeeldbezetting/duur beperken SD-15 niet.
- Eerste run stopte vóór databasewrites: providerresponse had HTTP200 en velden data/guestLevel/hotels, maar géén sandboxmarker. Controle gecorrigeerd naar expliciet afwijzen van aanwezige onveilige marker; provenance afzonderlijk opgeslagen als dedicated production credential, provider_sandbox=null. Geen vals bewijs sandbox=false. Request history uitgeschakeld. Offer-ID/payload blijft uitsluitend afgeschermd in Xano, niet in Git.
- Dataherstel: alleen nieuw concept18 terugzetten/archiveren en supplier3 disabled houden; niet permanent verwijderen zonder afzonderlijk besluit. Code-terugval schakelt geen database terug. Geen bestaande deal, partnerroute of order97/99 gewijzigd. inventory0/is_active=false/is_enabled=false; geen websiteplaatsing of goedkeuring.
- Nog open: productiegeschikte adminprijs-/inhoud-/goedkeuringsroute en ingelogde inspectie van concept18, exact gelijke websitepreview, kosten/voorwaarden/margeverificatie, afzonderlijke publieke plaatsing en volledige productieboekingsketen. Dit checkpoint markeert uitsluitend conceptaanmaak als voltooid; SD-15 en productievrijgave blijven open.


## REL-20261015-ADMIN-STATUS-CONCEPT — SD-02/10/15

- Admin: Nuitée toont sandbox en productie afzonderlijk, met verkoop gesloten. Conceptdeals bekijken toegevoegd aan dashboard, aanbod en leveranciersoverzicht. Geen publieke verkoop vrijgegeven.
- Selectie: admin/js/integrations-v11.js, admin/integrations.html, admin/suppliers.html, admin/deals.html, admin/index.html. Bron f2edd8902b59407ce2e5f74555dbf73256152c1b; bestemming main/Pages.
- Lokaal gecontroleerd: render van beide omgevingen, conceptfilter/source-selectie en uitsluitend leesaanvragen. JS-syntax en diffcontrole geslaagd. Uitrol en ingelogde controle nog te verifiëren.
- Terugval: gerichte revert van deze vijf adminbestanden. Geen gegevenswijzigingen.
- **Verplicht vóór livegang (OPEN): interne documenten, backendbronnen en geschiedenis afschermen; controleren dat interne bestanden niet via de gepubliceerde website bereikbaar zijn.** Tijdelijk openbaar verder werken is op 15 oktober door de eigenaar toegestaan. Geen geheimen of klantgegevens publiceren.

- Uitrol bevestigd: commit 72c25ac8827bda8249e946054f7bf7cfc0f25d64 op main; GitHub Pages run 38777296700 completed/success. Gepubliceerde integratiescript, conceptlink en livegangnotitie via HTTP200 met nieuwe inhoud gecontroleerd. Browser beschermt de admin met login; ingelogde visuele controle blijft open. Geen verkoopvrijgave.

- Aanvullende ingelogde browsercontrole 15 oktober 2026: beide Nuitée-omgevingen en gesloten verkoop zichtbaar; Conceptdeals bekijken opent status=Concept en bron=Leveranciers. Het Amsterdamse concept staat in dit overzicht. Deze controle vervangt het bovenstaande open punt voor ingelogde visuele verificatie. Screenshots geleverd; geen gegevens of verkoopinstellingen gewijzigd.


## REL-20261015-APPROVAL-PUBLICATION — SD-02/11/15

- Eigenaar verduidelijkt: concept → ter beoordeling → goedkeuren publiceert automatisch. Geen tweede publicatiehandeling; afwijzen en terugzetten naar concept houden/halen de deal offline.
- Bron main `358c71498e603af5d0d16f114c450952a1d8e5ab`; selectie bestaande adminbeoordeling, publieke aanbodweergave en Xano v1 Admin #902/#903 + Public API #63/#64/#71. Bron en terugvalversies in `backend/xano/approval-publication/`. Andere routes/configuratie niet geselecteerd.
- Xano-selectie van precies vijf endpoints gepubliceerd; openbare lijst HTTP200, concept18 via beide detailroutes HTTP404. Verkoopconfiguratie blijft gesloten. Geen deal goedgekeurd, geen boeking/betaling/mail uitgevoerd.
- Gericht lokaal bewijs: elf tests geslaagd voor publicatieprojectie zonder interne gegevens, behoud partnercontract, beoordeling alleen na indienen, gesloten checkout en bestaande checkoutafhandeling. Een echte goedkeuring/publicatie met definitieve kosten is niet uitgevoerd.
- Frontendplaatsing en ingelogde eindcontrole: nog te verifiëren. Bij concept18 moeten de werkelijke kosten nog worden ingevuld/gecontroleerd; geen kostenbedragen verzonnen.
- Terugval: oorspronkelijke vijf endpointbronnen terugplaatsen en gerichte frontendrevert. Deze release wijzigt geen bestaande dealrecords; een toekomstige goedgekeurde deal kan via Terug naar concept weer offline.

- Uitrolbewijs: main `c796e2897cc111331732163c3638b8774c3bdc3c`; Pages run `38781691527` completed/success. Ingelogde admin toont Concept, Indienen ter beoordeling en de uitleg dat goedkeuren automatisch publiceert. Werkelijke indienpoging bij concept18 geeft ‘Controleer en sla eerst de kosten en prijsregels op.’; concept bleef ongewijzigd. Dit vervangt het bovenstaande open punt voor frontendplaatsing/eindcontrole. Positieve eind-tot-eind goedkeuring met definitieve kosten blijft niet uitgevoerd.


## REL-20261015-ROOM-PHOTOS — SD-15.3/15.7 vaste foto-eis

- Eigenaarbesluit: voor iedere deal maximaal vijf losse, verschillende foto's van het juiste hotel en het aangeboden kamertype. Ook dezelfde afbeelding via een andere URL, grootte of encoding geldt als dubbel. Verplicht bij import én verversing; geen algemene hotelkamerfoto als vervanging voor een ontbrekende kamerkoppeling.
- Bron main `c436b26236b70015287ab306e8f983799958c102`; selectie: admin/css/admin.css, admin/deal-detail.html, admin/js/deal-detail-v5.js, deal-preview.html, js/shared-deal-preview.js, backend/nuitee/select_photos.py, backend/xano/production/refresh-deal-photos.xs en backend/xano/approval-publication/workflow.xs plus gerichte tests. Bestemming main/Pages en Xano workspace1/v1 functie803 + Admin903. Xano803 en Admin903 afzonderlijk gepubliceerd; na herladen903 kamer-/hotel-/duplicaatcontrole aanwezig en directe conceptgoedkeuring afwezig. Frontendplaatsing/eindcontrole nog TE VERIFIËREN.
- Verplichte leverancierbinding: hotel-ID + opgeslagen offer mappedRoomId + oorspronkelijke kamerbenaming; alleen room.photos van dat kamertype. Een vernieuwde kamerbinding maakt eerder fotobewijs ongeldig. Goedkeuringsroute controleert deze binding en de exact opgeslagen galerij voor iedere Nuitée-deal. Concept → ter beoordeling → goedgekeurd → website blijft de werkwijze; geen extra publicatieknop.
- Fotochecker vergelijkt echte afbeeldingsbytes (SHA256) en visuele dHash64, afstand ≤5 afwijzen; onleesbare foto's overslaan, geen ongecontroleerde fallback. Dit is een technische vergelijkingscontrole, geen garantie voor iedere denkbare uitsnede of zware bewerking. Worker-output alleen intern vertrouwen, nooit browser-hashes als bewijs aanvaarden.
- Lokaal bewijs: drie Python-tests voor dubbele inhoud/URL/resize/encoding, maximaal vijf, beschadigde foto's en geen fallback; drie JS-tests voor correcte binding, verkeerde/gewijzigde kamer of hotel, ontbrekend bewijs, gewijzigde galerij en duplicaten. Bestaande drie publicatie-/reviewtests blijven slagen.
- Bestaand concept: leveranciermetadata heeft kamerfoto's, maar het opgeslagen aanbod mist mappedRoomId. Gerichte nieuwe rates-opvraag met roomMapping=true leverde geen exacte overeenkomst met de bestaande kamer-/tariefvoorwaarden. Geen aanbod, prijzen of foto's vervangen. Werkelijke opslagpoging zonder kamerbinding stopte vóór DB-writes: `Confirmed room mapping and room photos required` (8 statements, 780ms). Algemene hotelbeelden niet als juiste kamerfoto's presenteren.
- OPEN: bestaand concept opnieuw van een passend, serverbevestigd aanbod met roomMapping=true voorzien; daarna maximaal vijf bijbehorende foto's controleren en opslaan. Landelijke automatisering SD-15 blijft open en mag pas worden afgerond wanneer iedere import/verversing deze worker en backendcontrole gebruikt. Positieve opslag met echte kamerkoppeling nog niet bewezen.
- Terugval: gerichte frontendrevert; Admin903 terug naar broncommit; interne803 loskoppelen. Geen dealgegevens gewijzigd, dus geen dataherstel nodig. Een toekomstige fotowijziging bewaart previous_images maar code-revert herstelt geen data. Coming Soon/verkooppoorten gesloten; geen boeking, betaling of mail.

- Aanvullende broncontrole: gepubliceerde903 bevatte nog een productie-uitzondering voor direct vanuit concept goedkeuren/afwijzen. Deze concrete afwijking van de eigenaarafspraak wordt in dezelfde selectie verwijderd; vooraf ingediend zijn blijft ook serverzijdig verplicht. Geen bestaande dealstatus gewijzigd.


### REL-20261015-ROOM-PHOTOS — herstel en werkelijke foto-opslag

- De eerdere blokkade voor concept18 is opgelost: voor foto-identiteit wordt de exacte leverancierkamernaam plus hotel en bezetting gebruikt, onafhankelijk van maaltijd- en annuleringsvoorwaarden. Bij oude offers zonder mappedRoomId vraagt803 roomMapping=true op en accepteert uitsluitend één kamer-ID waarop alle exacte naam-/bezettingsmatches overeenstemmen. Geen zelfgekozen match op een vergelijkbare catalogusnaam. Bij meerdere/ontbrekende matches blijft opslag geblokkeerd.
- Provider bevestigde Nhow Room bij hotel lp225fcf voor twee volwassenen als room4723518, met21 gekoppelde room.photos. De referentiecatalogus noemt deze kamer Nhow Room Dinner Package; de oorspronkelijke leverancierkamernaam blijft leidend en er wordt geen diner/ontbijt toegevoegd. Ruwe offer-/rate-ID, kamerbenaming, prijs en voorwaarden blijven ongewijzigd; aparte room_photo_binding bewaart de herkomst van de fotokoppeling.
- Vijf originele foto's daadwerkelijk gedownload, op SHA256/dHash vergeleken en visueel bekeken: losse slaapkamer-/badkamerbeelden, geen samengestelde afbeelding gegenereerd. Opslag via803 geslaagd:23statements/3,51s,deal18,statusdraft,photo_count5,room_photos_matchedtrue. Uitsluitend supplier_content-fotometadata en deals.external_image_urls/updated_at gewijzigd. Oude beelden bewaard in supplier_content.hotel.previous_images voor gerichte data-terugval.
- Frontendmain a84f0a34aca1d09566734d97a8c0cebef1a90f68, Pages38787437723 completed/success. Beveiligde preview toont Bekijk alle5foto’s; losse foto openen en volgende naar2/5 daadwerkelijk getest. Prijs blijft EUR317,39, kamer Nhow Room, zonder ontbijt. Backendcorrectie803 en903 selectief gepubliceerd. Eindcontrole903: geen Draft-indicator, opgeslagen bron bevat provider_exact_room_name en pending_approval-controle. Admin toont vijf losse thumbnails; vijfde foto aangeklikt en Foto 5 van 5 bevestigd. Screenshot seasondeals-kamerfotos-galerij.jpg toont de werkelijke preview met vijf foto’s. Geen concept goedgekeurd, publieke deal of verkoop vrijgegeven.
- Aanvullend bewijs: vijf JS-fototests slagen, inclusief unanieme mapping naar uitsluitend het juiste room.photos, afwijzen van tegenstrijdige mapping en vervallen bewijs bij een gewijzigde kamer. De drie Python-fototests blijven slagen. Landelijke automatische import/verversing moet deze algemene functie en interne beeldchecker nog aansluiten; dit open punt betreft automatisering, niet de nu herstelde foto’s van concept18.


## REL-20261016-AUTO-ROOM-PHOTOS — SD-11/15.3/15.7

- Bron main a34aa62d7ca99948e076faa5073afd4a1e6f018f. Selectie: interne fotoselector (nieuw), productie-import802, fotoverversing803 en bijbehorende fotobewijscontrole903. Bestemming workspace1/v1; nieuwe functie-ID804. Bestaande concept18 en verkoop-/betaal-/mailpoorten blijven behouden.
- Doel: server downloadt en vergelijkt kamerbeelden binnen dezelfde import; geen handmatige doorgifte van vertrouwde hashes. Bij ontbrekende eenduidige kamerbinding of nul geldige foto's geen ongecontroleerde galerie opslaan. Eén nieuwe conceptdeal als begrensde ketenproef, geen goedkeuring.
- Afhankelijkheid: beelddecoder in Xano Lambda daadwerkelijk bewijzen vóór aansluiting. Terugval: de vier gewijzigde onderdelen gericht terug naar broncommit; testconcept behouden als concept, geen records verwijderen. Plaatsing en testresultaat: zie aanvullend bewijs hieronder.

- Plaatsing: nieuwe interne804 select_room_photos aangemaakt op workspace1/v1, history=false. Bestaande802/803/903 elk afzonderlijk via Review & Publish gepubliceerd, uitsluitend het bedoelde onderdeel geselecteerd. Geen frontend-/Webflow-wijziging. Herladen803 bevestigt automatische helperaanroep en afwezigheid verified_photos-input; herladen903 bevestigt v2-algoritme en pending_approval-statuscontrole.
- Bouw: bytechecker in backend/nuitee/photo-selector.js, gegenereerde Xano-bron backend/xano/production/select-room-photos.xs, buildscript en vastgepinde Jimp1.6.0-afhankelijkheid/lockfile. Hashvariant sha256+dhash64-area-v2, maximaal5, SHA256/dHashafstand≤5, alleen goedgekeurde foto-host, geen redirects, maximaal20MiB/16megapixels/40kandidaten; nul geldige foto's stopt vóór opslag. JPEG/PNG ondersteund, andere formaten worden geweigerd. Geen claims van perfecte detectie van alle uitsneden/bewerkingen.
- Import802 haalt roomMapping=true op en doet fotoverificatie vóór de atomaire deal/supplier-opslag. Geen algemene hotelfoto als fallback. Kamerbenaming in de concepttekst volgt het daadwerkelijk aangeboden kamertype. Bestaande standard/RO/NRFN/inclusieve-heffingencontroles blijven intact. Optionele import_id voor begrensde proef/herhaling, standaard blijft bestaande import-ID.
- Werkelijk bewijs:804 selecteerde5 echte kamerbeelden in11,11s. Gepubliceerde803 vervolgens uitgevoerd met deal_id18/save=true, zonder foto-URL's of hashes als input:28statements/10,53s, statusdraft, photo_count5, room_photos_matchedtrue. Alleen fotoverversing; aanbod/prijs/voorwaarden/status ongewijzigd. Geen nieuw concept, goedkeuring, boeking, betaling of mail.
- Dataherstel:803 bewaart eerdere afbeeldingen in supplier_content.hotel.previous_images; code-revert herstelt geen data. Terugval van fotobewijs kan gericht via oorspronkelijke803 plus intern opnieuw berekende v1-hashes; geen volledige supplier_mapping/offer overschrijven.
- Gerichte lokale tests:3 beeldtests (zelfde bytes/andere URL/resize/PNG-encoding, host/kapotte beelden, maximaal5),2 importtests (uitsluitend aangeboden kamer en behoud offer, uitgesloten kosten/package/ontbrekende mapping blokkeren),6 reviewtests; alle11 slagen.
- OPEN positieve nieuwe-conceptproef: import-ID SD-PROD-NHOW-AUTO-PHOTOS-20261016-V2 is niet aangemaakt. Actuele leverancierrespons27–29november bevatte geen standard/RO/NRFN-aanbod dat tegelijk kamermapping en uitsluitend inbegrepen heffingen had; standaard niet-restitueerbaar aanbod had26,61EUR uitgesloten city_tax. Run stopte vóór DB-writes. Andere aanwezige varianten waren package of restitueerbaar; niet stilzwijgend als hetzelfde aanbod gebruikt. Tijdelijke begrensde diagnose verwijderd vóór publicatie. Eerstvolgende actie: passend actueel aanbod selecteren en de nieuwe-conceptketen één keer positief bewijzen.
- Landelijke importplanning en varianten SD-15 blijven afzonderlijk open. De automatische fotobouwsteen is nu werkelijk aangesloten op huidige import802 en verversing803, niet alleen als los script aanwezig.


## REL-20261016-PREVIEW-CONTENT — SD-13/15

- Eigenaar meldt screenshot deal-preview.html?portal=admin&id=18: SeasonDeals partner en lege inbegrepen-placeholder. Bron main89d773d8fb541937d7398a156847ef6c72fbceed; selectie js/shared-deal-preview.js en deal-preview.html, bestemming main/Pages. Terugval gerichte revert van deze twee bestanden.
- Preview gebruikt reeds opgehaalde leverancierhotelmetadata voor hotelnaam en concrete verblijfsinhoud. Fallback SeasonDeals zonder partner. Inbegrepen toont bevestigde nachten/leverancierkamer/bezetting en expliciete deal-extra’s; room-only toont ontbijt als niet inbegrepen. Leeg blok en generieke belofte verwijderd. Geen gewijzigde offerte/prijs/voorwaarden/status of backend.
- JavaScript-syntax en gerichte weergavecontrole geslaagd:2 overnachtingen/Nhow Room/2volwassenen; false-tekst wordt niet als inbegrepen extra behandeld. Plaatsing main/Pages en ingelogde eindcontrole TE VERIFIËREN; nieuwe-conceptimportproef en landelijke planning blijven afzonderlijk open.


## REL-20261016-AUTO-CONTENT — SD-13/15

- Eigenaarcorrectie: geen handmatig ingevulde inbegrepen-tekst per deal. Nuitée-metadata, gekozen offer/rate en zoekverblijf zijn de bron voor iedere import en weergave; ontbrekende gegevens nooit invullen met aannames. Dit vervangt de nog niet geplaatste preview-only commit3b70c5a5fa68a26bd256703e158dde54bfb8e75d; main blijft voorlopig89d773d8fb541937d7398a156847ef6c72fbceed.
- Selectie: centrale backend/nuitee/deal-content.js met buildscript; import802; beoordeling903; openbare lijst63 en details64/71; js/shared-deal-preview.js en public-preview/js/deal.js met bijbehorende HTML/cacheversies en gerichte tests. Bestemming Xano workspace1/v1, GitHub main/Pages. Geen Webflow-paginaconfiguratie, prijs, offer, bestaande dealstatus of verkooppoort wijzigen.
- Eén gegenereerde projectie leidt hotelnaam, echte leverancierkamer, nachten, bezetting en maaltijdvoorwaarden af. Hotelvoorzieningen en cataloguskamernamen bewijzen geen gratis extra’s. Publieke API geeft uitsluitend veilige klantvelden terug; interne mapping blijft privé. Beoordeling blokkeert onvolledige/tegenstrijdige brongegevens binnen de bestaande indien-/goedkeuringsroute.
- Terugval: geselecteerde bronnen terug naar main89d773d; geen bestaande dealrecords worden gemigreerd. Nieuwe imports behouden conceptstatus; code-terugval verandert geen eerder geïmporteerde records. Plaatsing en werkelijke ketencontrole TE VERIFIËREN. Nieuwe-conceptproef blijft apart geblokkeerd door eerder beschreven ontbrekend passend actueel tarief.

- Aanvullende eigenaarafspraak16oktober: kritische ketencontrole, professionele presentatie en schaalbaarheid als vaste werkwijze opgenomen in SEASONDEALS_WERKPROTOCOL.md; prioriteit voor concrete livegangblokkades, geen onbewezen onderdelen als gereed markeren.

- Xano-plaatsing16oktober: exact802/903/63/64/71 via Review & Publish geselecteerd (5 drafts); publicatie voltooid, draftteller0. Gerichte lokale tests14/14 geslaagd voor bronprojectie, varianten, ontbrekende/tegenstrijdige gegevens, behoud foto-/indienregels en afscherming interne velden. GitHub/Pages en ingelogde weergave nog TE VERIFIËREN.

- Frontend/backend-bron op main9f58d0e8a76f4be386b6fec7b88d88ddc49a8133; Pages38865634637 completed/success. Publieke lijst HTTP200/7 records; concept18 via beide detailroutes HTTP404. Alle18 lokale bestanden bytegelijk aan origin/main. Ingelogde previewcontrole toont nog geen inbegrepen-blok: bestaande previewresponse levert geen bronherkenning aan de nieuwe frontendroute. Dit concrete aansluitprobleem wordt vóór afronding hersteld; niet als positieve eindcontrole markeren.

- Concrete eindcontrolecorrectie: oudere beveiligde previewresponse zonder source herkent leverancier nu via bestaande ingelogde reader901, met deal-ID/providercontrole. Alleen404 bij onbekende bron geldt als niet-leveranciersdeal; andere fouten stoppen de preview. Geen wijziging aan endpoint196 of dealgegevens; bestaande sandboxmapping wordt hergebruikt zonder extra v1-fetch. Plaatsing/eindcontrole volgt.

- Positieve ingelogde eindcontrole: main85cfe7d16ddc938f37be81a497e47b99f5846c57, Pages38867178206 completed/success. Werkelijke preview18 toont hotelnaam nhow Amsterdam Rai, 2 overnachtingen, Nhow Room, 2 volwassenen en ontbijt niet inbegrepen, automatisch uit reader901/mapping. Geen handmatige wijziging van deal18. Prijs317,39 en conceptstatus behouden; vijf losse foto’s blijven aanwezig. Screenshot seasondeals-automatische-nuitee-inhoud-20261016.jpg. Aanvullende2 regressietests bewijzen het oude previewcontract zonder source plus fout-/verkeerde-dealblokkade.
- Open bij kritische livegangcontrole, in prioriteitsvolgorde: (1) nieuwe-conceptketen met passend actueel tarief/kosten en goedkeuring/publicatietest; (2) volledige gast-/Stripe-/Nuitée-/bevestigingsketen met expliciet geautoriseerde transactietest; (3) landelijke importplanning, varianten, capaciteit/quota en verversing; (4) interne bronnen vóór livegang afschermen. Bestaande testorders97/99 blijven ongewijzigd. Dit is een prioritering op bestaand bewijs, geen afgeronde audit van het hele platform.
- Presentatiepunt voor volgende previewcontrole: nul importvoorraad toont nog ‘Uitverkocht’ in beschermde preview terwijl leveranciersvoorraad via beschikbaarheidscontrole loopt; openbare supplierprojectie gebruikt al inventory=null. Ook Nederlandse datumopmaak in de automatisch afgeleide inbegrepenregel nog nalopen. Niet verborgen als voltooid kwaliteitswerk.


## REL-20261016-EXTRAS — SD-13/15

- Eigenaar keurt aansluiting van vijf hotelpartnertestvelden en herstel hotelnaam/voorraad/datums goed. Bron main be6c738134730645d994d44ca4fe969b08e2f280; bestemming main/Pages en Xano workspace1/v1: import802, refresh803, workflow903, publieke63/64/71. Centrale bron backend/nuitee/deal-content.js plus gegenereerde consumers; admin detail en gedeelde/public preview. Hotelnaam in adminlijst nog TE VERIFIËREN.
- Leveranciermetadata wordt naast de ongewijzigde geselecteerde rate bewaard. Geen gratis extra op basis van alleen aanwezigheid; tariefperks bewaren voorwaarden en hun amount is geen klanttoeslag. Oude partnertestdata, prijzen, status en verkooppoorten blijven behouden.
- Terugval: gerichte revert naar broncommit; bij metadatarefresh bewaart supplier_content.hotel.previous_supplier_details de voorafgaande metadata. Code-terugval herstelt geen data. Bouw/tests/plaatsing/eindcontrole nog TE VERIFIËREN.

- Aanvullende eigenaarafspraak: onderdelen automatisch vullen uit bevestigde bron; niet beschikbaar/onbevestigd niet tonen. Nergens “gratis” in de aanbodweergave; inbegrepen voorzieningen en eventuele kosten/voorwaarden blijven zichtbaar.

- Xano v1: exact802/803/903/63/64/71 gepubliceerd via selectie6drafts, teller0. Lokaal19 gerichte tests geslaagd. Adminlijst herstelt ontbrekende hotelnaam via bestaande reader901 uitsluitend voor zichtbare pagina, maximaal4 tegelijk en sessiecache; endpoint172 blijft ongewijzigd. Nieuwe backendbron op main/Pages en ingelogde eindcontrole nog TE VERIFIËREN.
