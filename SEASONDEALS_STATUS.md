# SeasonDeals — actuele projectstatus

> **Vaste bron van waarheid voor de technische voortgang van SeasonDeals**
>
> Laatst inhoudelijk geverifieerd: **9 oktober 2026**
>
> Repository: `jurgenhassankhan/seasondeals-partner-portal`  
> Productiearchitectuur: **Webflow (publieke frontend) + Xano (backend en bron van waarheid) + Stripe (betalingen) + Resend (e-mail)**

## Stap 3 vervolg — 9 oktober 2026

### Afgerond en getest
- GitHub-back-up `backup/pre-step3-final-2026-10-09`; Xano-bron `nuitee-step3-final-2026-10-09` vanuit v1. Alleen reader, refreshfunctie en sandboxtaak samengevoegd, met doelbranchback-up; tien bestaande afwijkende endpoints en middleware uitgesloten.
- Reader #1310 gecompileerd en met bestaande adminauth getest: echte sandboxdeal17, vaste €241,43, leverancier €203,78, marge na reserves €28,85, betalen false; 790ms. Latest pending mag alleen maximaal 20 seconden een nog geldig, exact gelijk goedgekeurd completed resultaat behouden. Nieuwe negatieve resultaten winnen altijd.
- Refreshfunctie #379 geeft snapshots maximaal 90 seconden geldigheid; dit overbrugt minuutplanning, geen realtime voorraadgarantie. Datumselectie blijft een afzonderlijke verse leverancierscontrole.
- Taak #36 handmatig uitgevoerd in 3,32s; oudste controles eerst, maximaal20 kandidaten, sequentiële aanvragen en 45s startbudget. v1-taak #32 opnieuw actief gepubliceerd na selectieve merge. Productiequotum en opschaalcapaciteit moeten afzonderlijk bevestigd worden.
- Regressies voor verval, gewijzigde prijzen/configuratie, negatieve resultaten, pendingtimeout en eerlijke rotatie over41 proefdeals slagen. Bestaande20-rijentabel/search/filtertests en nieuwe bezoekerspreviewtest slagen.

### Gepubliceerd; laatste ingelogde browsercontrole nog open
- PR17 samengevoegd als `7044524ff8a7747db4accdaab64d377ab8b45de9`; Pages-uitrol #37936400362 geslaagd. v1-taaklijst na publicatie toont taak32 Live: Active, Draft: Active, every1min.
- Beveiligde `admin/availability-website-preview.html` gebruikt bestaande adminauth en private v1-snapshots. In bezoekersstijl verschijnen alleen beschikbare goedgekeurde sandboxdeals, met foto, vaste prijs en link naar bestaande verse datumselectie. Geen onbevestigd kameraantal. Zoekveld en twintig kaarten per pagina.
- Admincatalogus linkt naar bezoekerspreview; tabel en goedkeuringsproces behouden. Client accepteert maximaal90s snapshots conform server. Geen anonieme sandboxpublicatie of betaalroute geopend.

- Laatste portalcontrole: beveiligde aanmelding ingediend, maar canonieke catalogus keert terug naar het loginformulier; ingelogde bezoekerspreview vandaag niet geverifieerd. Browserobservatie was tijdelijk beperkt na credentialdelivery. Geen herhaalde credentialinvoer uitgevoerd; bestaande ingelogde controle van8okt blijft afzonderlijk bewijs voor de oude versie.

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
