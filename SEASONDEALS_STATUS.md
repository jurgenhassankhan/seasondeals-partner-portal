# SeasonDeals — actuele projectstatus

> **Actueel13okt — SD-10:** ACC door eigenaar bevestigd; aparte Nuitée-productiekey en gesloten configuratie geplaatst. Controlefunctie788 op v1 getest; geen productieboekingen of publieke vrijgave. Zie REL-20261013-ACC-PREP onderaan.

> **Actueel12okt — SD-12:** stap7-sandboxherstelroute afgerond, op v1/main/Pages geplaatst en ingelogd gecontroleerd. Historische order97 blijft op aanwijzing van Jurgen een ongewijzigd testrecord en is geen afsluitblokkade; order99 blijft manual_attention. Geen publieke productievrijgave. Zie DOC-20261012-ORDER97-LEGACY onderaan.

> **Vaste bron van waarheid voor de technische voortgang van SeasonDeals**
>
> Laatst inhoudelijk geverifieerd: **12 oktober 2026**
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
